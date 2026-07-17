import Dependencies
import DependenciesMacros
import Foundation

@DependencyClient
struct PlaybackSessionCacheClient: Sendable {
  var _load: @Sendable () async throws -> PlaybackCheckpoint?
  var _save: @Sendable (_ checkpoint: PlaybackCheckpoint) async throws -> Void
  var _delete: @Sendable () async -> Void
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
      _delete: {
        @Dependency(\.keychain) var keychain
        guard let childId = keychain.loadConnection()?.childId else { return }
        await storage.delete(childId: childId)
      },
    )
  }

  static let noop = Self(
    _load: { nil },
    _save: { _ in },
    _delete: {},
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
      isValid: { $0.playbackSession != nil },
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
  var currentIndex: Int
  var elapsedTime: TimeInterval
  var durationFallback: TimeInterval?
  var sourceAlbumHints: [SourceAlbumHint]

  init(
    songIDs: [ApprovedTrack.ID],
    currentIndex: Int,
    elapsedTime: TimeInterval,
    durationFallback: TimeInterval? = nil,
    sourceAlbumHints: [SourceAlbumHint] = [],
  ) {
    self.songIDs = songIDs
    self.currentIndex = currentIndex
    self.elapsedTime = elapsedTime.isFinite ? max(0, elapsedTime) : 0
    self.durationFallback = durationFallback.flatMap { duration in
      duration.isFinite && duration > 0 ? duration : nil
    }
    self.sourceAlbumHints = sourceAlbumHints
  }

  init(
    session: PlaybackFeature.Session,
    sourceAlbumIDs: [ApprovedTrack.ID: ApprovedAlbum.ID],
  ) {
    let items = Array(session.queue.items.dropFirst(session.queue.currentIndex))
    var seenSongIDs = Set<ApprovedTrack.ID>()
    let sourceAlbumHints = items.compactMap { item -> SourceAlbumHint? in
      guard seenSongIDs.insert(item.id).inserted,
            let albumID = sourceAlbumIDs[item.id] ?? item.albumID else { return nil }
      return SourceAlbumHint(songID: item.id, albumID: albumID)
    }
    self.init(
      songIDs: items.map(\.id),
      currentIndex: 0,
      elapsedTime: session.progress.elapsedTime,
      durationFallback: session.progress.duration,
      sourceAlbumHints: sourceAlbumHints,
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
    self.init(
      songIDs: items.map(\.id),
      currentIndex: 0,
      elapsedTime: legacySession.progress.elapsedTime,
      durationFallback: legacySession.progress.duration,
      sourceAlbumHints: sourceAlbumHints,
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
      sourceAlbumHints: self.sourceAlbumHints.filter { retainedSongIDs.contains($0.songID) },
    )
  }

  var isValid: Bool {
    !self.songIDs.isEmpty && self.songIDs.indices.contains(self.currentIndex)
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

  init(session: PlaybackFeature.Session) {
    self.init(
      items: session.queue.items,
      currentIndex: session.queue.currentIndex,
      progress: session.progress,
    )
  }

  var playbackSession: PlaybackFeature.Session? {
    guard !self.items.isEmpty else { return nil }
    return PlaybackFeature.Session(
      playStatus: .paused,
      queue: .init(items: self.items, currentIndex: self.currentIndex),
      progress: PlaybackProgress(
        elapsedTime: self.progress.elapsedTime,
        duration: self.progress.duration,
      ),
    )
  }
}
