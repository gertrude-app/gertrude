import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct PlaybackSessionCacheClient: Sendable {
  var _delete: @Sendable () async -> Void
  var _deleteForChild: @Sendable (_ childId: UUID) async -> Void
  var _load: @Sendable () async throws -> PlaybackCheckpoint?
  var _save: @Sendable (_ checkpoint: PlaybackCheckpoint) async throws -> Void
}

extension PlaybackSessionCacheClient {
  func load() async throws -> PlaybackCheckpoint? {
    try await self._load()
  }

  func save(_ checkpoint: PlaybackCheckpoint) async throws {
    try await self._save(checkpoint)
  }

  func delete() async {
    await self._delete()
  }

  func delete(childId: UUID) async {
    await self._deleteForChild(childId)
  }
}

extension PlaybackSessionCacheClient: DependencyKey {
  static var liveValue: Self {
    .live(directory: ChildScopedDiskJSONCache<PlaybackCheckpoint>.directory(
      named: "PlaybackSessionCache",
    ))
  }

  static let testValue = Self.noop
}

extension DependencyValues {
  var playbackSessionCache: PlaybackSessionCacheClient {
    get { self[PlaybackSessionCacheClient.self] }
    set { self[PlaybackSessionCacheClient.self] = newValue }
  }
}

extension PlaybackSessionCacheClient {
  static func live(directory: URL) -> Self {
    let storage = PlaybackCheckpointStorage(directory: directory)
    return Self(
      _delete: {
        @Dependency(\.keychain) var keychain
        guard let childId = keychain.loadConnection()?.childId else { return }
        await storage.delete(childId: childId)
      },
      _deleteForChild: { childId in
        await storage.delete(childId: childId)
      },
      _load: {
        @Dependency(\.keychain) var keychain
        guard let childId = keychain.loadConnection()?.childId else { return nil }
        return try await storage.load(childId: childId)
      },
      _save: { checkpoint in
        @Dependency(\.keychain) var keychain
        guard let childId = keychain.loadConnection()?.childId else { return }
        try Task.checkCancellation()
        try await storage.save(checkpoint, childId: childId)
      },
    )
  }

  static let noop = Self(
    _delete: {},
    _deleteForChild: { _ in },
    _load: { nil },
    _save: { _ in },
  )
}

private actor PlaybackCheckpointStorage {
  private let checkpointCache: ChildScopedDiskJSONCache<PlaybackCheckpoint>
  private let legacyCache: ChildScopedDiskJSONCache<CachedPlaybackSession>

  init(directory: URL) {
    self.checkpointCache = ChildScopedDiskJSONCache<PlaybackCheckpoint>(
      directory: directory,
      version: 2,
      isValid: \.isValid,
    )
    self.legacyCache = ChildScopedDiskJSONCache<CachedPlaybackSession>(
      directory: directory,
      version: 1,
      isValid: \.isValid,
    )
  }

  func delete(childId: UUID) {
    try? self.checkpointCache.delete(childId: childId)
    try? self.legacyCache.delete(childId: childId)
  }

  func load(childId: UUID) throws -> PlaybackCheckpoint? {
    if let checkpoint = try self.checkpointCache.load(childId: childId) {
      return checkpoint
    }
    guard let legacySession = try self.legacyCache.load(childId: childId) else { return nil }
    let checkpoint = PlaybackCheckpoint(legacySession: legacySession)
    try self.checkpointCache.save(checkpoint, childId: childId)
    return checkpoint
  }

  func save(_ checkpoint: PlaybackCheckpoint, childId: UUID) throws {
    try Task.checkCancellation()
    try self.checkpointCache.save(checkpoint, childId: childId)
  }
}

struct PlaybackCheckpoint: Codable, Equatable, Sendable {
  struct SourceAlbumHint: Codable, Equatable, Sendable {
    var songID: ApprovedTrack.ID
    var albumID: ApprovedAlbum.ID
  }

  var songIDs: [ApprovedTrack.ID]
  var context: PlaybackContext?
  var currentIndex: Int
  var elapsedTime: TimeInterval
  var durationFallback: TimeInterval?
  var infinitePlaybackPlan: InfinitePlaybackPlan?
  var playbackSource: PlaybackSource?
  var playlistSourceHints: [PlaylistPlaybackSource?]
  var queueRoles: [PlaybackQueueRole?]?
  var sourceAlbumHints: [SourceAlbumHint]
  var sourceEntryIDs: [PlaybackSource.Entry.ID?]?

  init(
    songIDs: [ApprovedTrack.ID],
    currentIndex: Int,
    elapsedTime: TimeInterval,
    durationFallback: TimeInterval? = nil,
    infinitePlaybackPlan: InfinitePlaybackPlan? = nil,
    sourceAlbumHints: [SourceAlbumHint] = [],
    playbackSource: PlaybackSource? = nil,
    playlistSourceHints: [PlaylistPlaybackSource?]? = nil,
    queueRoles: [PlaybackQueueRole?]? = nil,
    sourceEntryIDs: [PlaybackSource.Entry.ID?]? = nil,
    context: PlaybackContext? = nil,
  ) {
    self.songIDs = songIDs
    self.context = context
    self.currentIndex = currentIndex
    self.elapsedTime = elapsedTime.isFinite ? max(0, elapsedTime) : 0
    self.durationFallback = durationFallback.flatMap { duration in
      duration.isFinite && duration > 0 ? duration : nil
    }
    self.infinitePlaybackPlan = infinitePlaybackPlan
    self.playbackSource = playbackSource
    self.playlistSourceHints = playlistSourceHints
      ?? Array(repeating: nil, count: songIDs.count)
    self.queueRoles = queueRoles
    self.sourceAlbumHints = sourceAlbumHints
    self.sourceEntryIDs = sourceEntryIDs
  }

  init(
    session: PlaybackFeature.Session,
    infinitePlaybackPlan: InfinitePlaybackPlan? = nil,
    playbackSource: PlaybackSource? = nil,
    context: PlaybackContext? = nil,
    progress: PlaybackProgress,
    sourceAlbumIDs: [ApprovedTrack.ID: ApprovedAlbum.ID],
  ) {
    let entries = Array(session.queue.entries.dropFirst(session.queue.currentIndex))
    let items = entries.map(\.item)
    var seenSongIDs = Set<ApprovedTrack.ID>()
    let sourceAlbumHints = items.compactMap { item -> SourceAlbumHint? in
      guard seenSongIDs.insert(item.id).inserted,
            let albumID = sourceAlbumIDs[item.id] ?? item.albumID else { return nil }
      return SourceAlbumHint(songID: item.id, albumID: albumID)
    }
    let queueRoles = items.map(\.queueRole)
    let sourceEntryIDs = entries.map(\.sourceEntryID)
    self.init(
      songIDs: items.map(\.id),
      currentIndex: 0,
      elapsedTime: progress.elapsedTime,
      durationFallback: progress.duration,
      infinitePlaybackPlan: infinitePlaybackPlan,
      sourceAlbumHints: sourceAlbumHints,
      playbackSource: playbackSource,
      playlistSourceHints: items.map(\.playlistSource),
      queueRoles: queueRoles.contains(where: { $0 != nil }) ? queueRoles : nil,
      sourceEntryIDs: sourceEntryIDs.contains(where: { $0 != nil }) ? sourceEntryIDs : nil,
      context: context,
    )
  }

  init(legacySession: CachedPlaybackSession) {
    let currentIndex = legacySession.items.indices.contains(legacySession.currentIndex)
      ? legacySession.currentIndex
      : 0
    let items = Array(legacySession.items.dropFirst(currentIndex))
    var seenSongIDs = Set<ApprovedTrack.ID>()
    let sourceAlbumHints = items.compactMap { item -> SourceAlbumHint? in
      guard seenSongIDs.insert(item.id).inserted,
            let albumID = item.albumID else { return nil }
      return SourceAlbumHint(songID: item.id, albumID: albumID)
    }
    let queueRoles = items.map(\.queueRole)
    self.init(
      songIDs: items.map(\.id),
      currentIndex: 0,
      elapsedTime: legacySession.progress.elapsedTime,
      durationFallback: legacySession.progress.duration,
      sourceAlbumHints: sourceAlbumHints,
      playlistSourceHints: items.map(\.playlistSource),
      queueRoles: queueRoles.contains(where: { $0 != nil }) ? queueRoles : nil,
    )
  }

  var activeQueue: Self {
    guard self.isValid else { return self }
    let songIDs = Array(self.songIDs.dropFirst(self.currentIndex))
    let retainedSongIDs = Set(songIDs)
    return Self(
      songIDs: songIDs,
      currentIndex: 0,
      elapsedTime: self.elapsedTime,
      durationFallback: self.durationFallback,
      infinitePlaybackPlan: self.infinitePlaybackPlan,
      sourceAlbumHints: self.sourceAlbumHints.filter { retainedSongIDs.contains($0.songID) },
      playbackSource: self.playbackSource,
      playlistSourceHints: Array(self.playlistSourceHints.dropFirst(self.currentIndex)),
      queueRoles: self.queueRoles.map { Array($0.dropFirst(self.currentIndex)) },
      sourceEntryIDs: self.sourceEntryIDs.map { Array($0.dropFirst(self.currentIndex)) },
      context: self.context,
    )
  }

  func filtered(to approvedTrackIDs: Set<ApprovedTrack.ID>) -> Self? {
    let checkpoint = self.activeQueue
    let retainedIndices = checkpoint.songIDs.indices.filter {
      approvedTrackIDs.contains(checkpoint.songIDs[$0])
    }
    guard !retainedIndices.isEmpty else { return nil }
    let currentItemWasRetained = retainedIndices.first == checkpoint.currentIndex
    let songIDs = retainedIndices.map { checkpoint.songIDs[$0] }
    let retainedSongIDs = Set(songIDs)
    let queueRoles = checkpoint.queueRoles.map { roles in
      retainedIndices.map { roles[$0] }
    }
    let retainsContext = queueRoles?.contains(where: { $0 == .context }) ?? true
    var playbackSource = checkpoint.playbackSource
    playbackSource?.removeTracks(notIn: approvedTrackIDs)
    return Self(
      songIDs: songIDs,
      currentIndex: 0,
      elapsedTime: currentItemWasRetained ? checkpoint.elapsedTime : 0,
      durationFallback: currentItemWasRetained ? checkpoint.durationFallback : nil,
      infinitePlaybackPlan: checkpoint.infinitePlaybackPlan.map { plan in
        InfinitePlaybackPlan(
          remainingSourceEntryIDs: plan.remainingSourceEntryIDs.filter { entryID in
            playbackSource?.removedEntryIDs.contains(entryID) == false
          },
          generatedItems: plan.generatedItems.filter {
            approvedTrackIDs.contains($0.id)
          },
        )
      },
      sourceAlbumHints: checkpoint.sourceAlbumHints.filter {
        retainedSongIDs.contains($0.songID)
      },
      playbackSource: playbackSource,
      playlistSourceHints: retainedIndices.map {
        checkpoint.playlistSourceHints[$0]
      },
      queueRoles: queueRoles,
      sourceEntryIDs: checkpoint.sourceEntryIDs.map { sourceEntryIDs in
        retainedIndices.map { sourceEntryIDs[$0] }
      },
      context: retainsContext ? checkpoint.context : nil,
    )
  }

  var isValid: Bool {
    !self.songIDs.isEmpty
      && self.songIDs.indices.contains(self.currentIndex)
      && self.playlistSourceHints.count == self.songIDs.count
      && (self.playbackSource?.isValid ?? true)
      && (self.infinitePlaybackPlan?.remainingSourceEntryIDs.allSatisfy { sourceEntryID in
        self.playbackSource?.entries.contains(where: { $0.id == sourceEntryID }) == true
      } ?? true)
      && (self.queueRoles == nil || self.queueRoles?.count == self.songIDs.count)
      && (self.sourceEntryIDs == nil || self.sourceEntryIDs?.count == self.songIDs.count)
      && (self.sourceEntryIDs?.allSatisfy { sourceEntryID in
        guard let sourceEntryID else { return true }
        return self.playbackSource?.entries.contains(where: { $0.id == sourceEntryID }) == true
      } ?? true)
  }

  var sourceAlbumIDs: [ApprovedTrack.ID: ApprovedAlbum.ID] {
    Dictionary(
      self.sourceAlbumHints.map { ($0.songID, $0.albumID) },
      uniquingKeysWith: { first, _ in first },
    )
  }
}

struct CachedPlaybackSession: Codable, Equatable, Sendable {
  var items: [PlaybackItem]
  var currentIndex: Int
  var progress: PlaybackProgress

  init(
    items: [PlaybackItem],
    currentIndex: Int,
    progress: PlaybackProgress,
  ) {
    self.items = items
    self.currentIndex = currentIndex
    self.progress = progress
  }

  var isValid: Bool {
    !self.items.isEmpty
  }
}
