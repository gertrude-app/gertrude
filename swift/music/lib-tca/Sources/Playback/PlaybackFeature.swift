import ComposableArchitecture
import Foundation
import GertieApp

struct PlaybackProgress: Codable, Equatable, Sendable {
  var elapsedTime: TimeInterval
  var duration: TimeInterval

  init(
    elapsedTime: TimeInterval = 0,
    duration: TimeInterval = 0,
  ) {
    self.elapsedTime = elapsedTime.isFinite ? max(0, elapsedTime) : 0
    self.duration = duration.isFinite ? max(0, duration) : 0
  }

  static let zero = Self()

  var fraction: Double {
    guard self.duration > 0 else { return 0 }
    return min(1, max(0, self.elapsedTime / self.duration))
  }
}

enum PlaybackFailure: Equatable, Sendable {
  case appleMusicSubscriptionRequired
  case catalogLookupFailed
  case musicAccessDenied
  case musicAccessRestricted
  case playbackFailed
  case privacyAcknowledgementRequired
  case trackUnavailable

  init(error: any Error) {
    switch error as? PlaybackClientError {
    case .appleMusicSubscriptionRequired:
      self = .appleMusicSubscriptionRequired
    case .catalogLookupFailed:
      self = .catalogLookupFailed
    case .musicAccessDenied:
      self = .musicAccessDenied
    case .musicAccessRestricted:
      self = .musicAccessRestricted
    case .playbackFailed:
      self = .playbackFailed
    case .privacyAcknowledgementRequired:
      self = .privacyAcknowledgementRequired
    case .trackUnavailable:
      self = .trackUnavailable
    case nil:
      self = .playbackFailed
    }
  }

  var opensSettings: Bool {
    switch self {
    case .musicAccessDenied, .musicAccessRestricted:
      true
    case .appleMusicSubscriptionRequired,
         .catalogLookupFailed,
         .playbackFailed,
         .privacyAcknowledgementRequired,
         .trackUnavailable:
      false
    }
  }
}

@Reducer
struct PlaybackFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var session: Session?
    var failure: PlaybackFailure?
    var hasAuthoritativeSnapshot = false
    var isRestoringCheckpoint = false
    var lastCachedProgressBucket: Int?
    var pendingAlbumResolutionSongID: ApprovedTrack.ID?
    var pendingPlayNowItems: [PlaybackItem]?
    var pendingPlaylistSourcePlan: [PlaybackSourceHintMatcher.Occurrence]?
    var playlistSourceHints: [PlaybackQueueEntry.ID: PlaylistPlaybackSource] = [:]
    var progress = PlaybackProgress.zero
    var sourceAlbumIDs: [ApprovedTrack.ID: ApprovedAlbum.ID] = [:]
  }

  struct Queue: Equatable, Sendable {
    var entries: [PlaybackQueueEntry]
    var currentIndex: Int

    init(
      items: [PlaybackItem],
      currentIndex: Int = 0,
    ) {
      self.entries = items.enumerated().map { index, item in
        PlaybackQueueEntry(id: "pending:\(index):\(item.id.rawValue)", item: item)
      }
      self.currentIndex = items.indices.contains(currentIndex) ? currentIndex : 0
    }

    init?(
      entries: [PlaybackQueueEntry],
      currentEntryID: PlaybackQueueEntry.ID?,
    ) {
      guard let currentEntryID,
            let currentIndex = entries.firstIndex(where: { $0.id == currentEntryID }) else {
        return nil
      }
      self.entries = entries
      self.currentIndex = currentIndex
    }

    var currentEntry: PlaybackQueueEntry {
      self.entries[self.currentIndex]
    }

    var currentItem: PlaybackItem {
      self.currentEntry.item
    }

    var items: [PlaybackItem] {
      self.entries.map(\.item)
    }

    var upcomingEntries: [PlaybackQueueEntry] {
      guard !self.entries.isEmpty,
            self.currentIndex < self.entries.index(before: self.entries.endIndex) else { return [] }
      let nextIndex = self.entries.index(after: self.currentIndex)
      return Array(self.entries[nextIndex...])
    }

    var upcomingItems: [PlaybackItem] {
      self.upcomingEntries.map(\.item)
    }
  }

  struct Session: Equatable, Sendable {
    var playStatus: PlayStatus
    var queue: Queue

    init(
      playStatus: PlayStatus = .playing,
      queue: Queue,
    ) {
      precondition(!queue.items.isEmpty)
      self.playStatus = playStatus
      self.queue = queue
    }

    init(
      playStatus: PlayStatus = .playing,
      currentItem: PlaybackItem,
    ) {
      self.init(
        playStatus: playStatus,
        queue: .init(items: [currentItem]),
      )
    }

    init?(
      snapshot: PlaybackSnapshot,
      sourceAlbumIDs: [ApprovedTrack.ID: ApprovedAlbum.ID],
      playlistSourceHints: [PlaybackQueueEntry.ID: PlaylistPlaybackSource] = [:],
    ) {
      let entries = snapshot.entries.map { entry in
        PlaybackQueueEntry(
          id: entry.id,
          item: entry.item
            .withAlbumID(sourceAlbumIDs[entry.item.id])
            .withPlaylistSource(
              playlistSourceHints[entry.id] ?? entry.item.playlistSource,
            ),
        )
      }
      guard let queue = Queue(
        entries: entries,
        currentEntryID: snapshot.currentEntryID,
      ) else { return nil }
      self.init(
        playStatus: snapshot.playStatus,
        queue: queue,
      )
    }
  }

  enum PlayStatus: Equatable, Sendable {
    case loading
    case playing
    case paused
  }

  enum Action: Equatable {
    case addToQueue([PlaybackItem])
    case checkpointLoaded(PlaybackCheckpoint?)
    case checkpointRestorationFinished(PlaybackSnapshot?)
    case clearUpcomingButtonTapped
    case observePlayback
    case pause
    case playNext([PlaybackItem])
    case playNow(items: [PlaybackItem], startIndex: Int)
    case playNowFinished(PlaybackSnapshot)
    case playbackEvent(PlaybackEvent)
    case playbackFailed(PlaybackFailure)
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case queueEntryRemoveRequested(PlaybackQueueEntry.ID)
    case reorderUpcoming([PlaybackQueueEntry.ID])
    case restoreCachedSession
    case resume
    case saveCachedSession
    case seek(TimeInterval)
    case skipToNext
    case skipToPrevious
    case stop
    case togglePlayPause
  }

  enum CancelID: Hashable {
    case checkpointSave
    case playbackEvents
    case playbackStart
    case seek
  }

  @Dependency(\.playback) var playback
  @Dependency(\.playbackSessionCache) var playbackSessionCache
  @Dependency(\.systemSettings) var systemSettings

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addToQueue(let items):
        return self.insertIntoQueue(items, position: .tail, state: &state)

      case .checkpointLoaded(let loadedCheckpoint):
        guard state.session == nil,
              let loadedCheckpoint else { return .none }
        let checkpoint = loadedCheckpoint.activeQueue
        state.failure = nil
        state.hasAuthoritativeSnapshot = false
        state.isRestoringCheckpoint = true
        state.lastCachedProgressBucket = nil
        state.sourceAlbumIDs.merge(checkpoint.sourceAlbumIDs) { _, new in new }
        state.preparePlaylistSourcePlan(checkpoint: checkpoint)
        return .run { send in
          do {
            let snapshot = try await self.playback.restoreQueue(checkpoint)
            try Task.checkCancellation()
            await send(.checkpointRestorationFinished(snapshot))
          } catch is CancellationError {
            return
          } catch {
            await send(.checkpointRestorationFinished(nil))
          }
        }
        .cancellable(id: CancelID.playbackStart, cancelInFlight: true)

      case .checkpointRestorationFinished(let snapshot):
        state.isRestoringCheckpoint = false
        guard let snapshot else {
          state.hasAuthoritativeSnapshot = false
          return .none
        }
        return .send(.playbackEvent(.snapshotChanged(snapshot)))

      case .clearUpcomingButtonTapped:
        guard let queue = state.session?.queue,
              !queue.upcomingEntries.isEmpty else { return .none }
        state.pendingPlayNowItems = nil
        state.preparePlaylistSourcePlan(
          entries: Array(queue.entries.prefix(queue.currentIndex + 1)),
        )
        return .run { send in
          do {
            let snapshot = try await self.playback.clearUpcoming()
            try Task.checkCancellation()
            await send(.playbackEvent(.snapshotChanged(snapshot)))
          } catch is CancellationError {
            return
          } catch {
            await send(.playbackFailed(.init(error: error)))
          }
        }
        .cancellable(id: CancelID.playbackStart, cancelInFlight: true)

      case .observePlayback:
        return .run { send in
          for await event in self.playback.events() {
            await send(.playbackEvent(event))
          }
        }
        .cancellable(id: CancelID.playbackEvents, cancelInFlight: true)

      case .playbackEvent(.queueEnded):
        guard state.session != nil || state.isRestoringCheckpoint else { return .none }
        state.failure = nil
        state.hasAuthoritativeSnapshot = false
        state.isRestoringCheckpoint = false
        state.lastCachedProgressBucket = nil
        state.pendingAlbumResolutionSongID = nil
        state.pendingPlayNowItems = nil
        state.pendingPlaylistSourcePlan = nil
        state.playlistSourceHints.removeAll()
        state.progress = .zero
        state.session = nil
        state.sourceAlbumIDs.removeAll()
        return .merge(
          .cancel(id: CancelID.playbackStart),
          .cancel(id: CancelID.seek),
          .concatenate(
            .cancel(id: CancelID.checkpointSave),
            .run { _ in
              await self.playback.clearQueue()
              await self.playbackSessionCache.delete()
            },
          ),
        )

      case .playbackEvent(.progressChanged(let progress)):
        guard state.pendingPlayNowItems == nil else { return .none }
        state.setProgress(progress)
        guard state.shouldCacheProgressSnapshot() else { return .none }
        return self.saveCheckpoint(state)

      case .playbackEvent(.snapshotChanged(let snapshot)):
        if let pendingItems = state.pendingPlayNowItems {
          guard snapshot.entries.map(\.item.id) == pendingItems.map(\.id) else { return .none }
          state.pendingPlayNowItems = nil
        }
        return self.applySnapshot(snapshot, state: &state)

      case .playNext(let items):
        return self.insertIntoQueue(items, position: .next, state: &state)

      case .playNow(let items, let startIndex):
        guard items.indices.contains(startIndex) else { return .none }
        let requestedItems = Array(items[startIndex...])
        let existingUpcomingEntries = state.hasAuthoritativeSnapshot
          ? state.session?.queue.upcomingEntries ?? []
          : []
        let existingUpcomingItems = existingUpcomingEntries.map(\.item)
        let composedItems = requestedItems + existingUpcomingItems
        state.preparePlaylistSourcePlan(
          newItems: requestedItems,
          retainedEntries: existingUpcomingEntries,
        )
        state.failure = nil
        state.hasAuthoritativeSnapshot = false
        state.isRestoringCheckpoint = false
        state.lastCachedProgressBucket = nil
        state.pendingPlayNowItems = composedItems
        state.progress = .zero
        state.recordSourceAlbums(requestedItems)
        state.session = .init(
          playStatus: .loading,
          queue: .init(items: composedItems),
        )
        return .run { send in
          do {
            let snapshot = try await self.playback.playNow(items, startIndex)
            try Task.checkCancellation()
            await send(.playNowFinished(snapshot))
          } catch is CancellationError {
            return
          } catch {
            await send(.playbackFailed(.init(error: error)))
          }
        }
        .cancellable(id: CancelID.playbackStart, cancelInFlight: true)

      case .playNowFinished(let snapshot):
        state.pendingPlayNowItems = nil
        return self.applySnapshot(snapshot, state: &state)

      case .togglePlayPause:
        switch state.session?.playStatus {
        case .playing:
          return .send(.pause)
        case .paused:
          return .send(.resume)
        case .loading, nil:
          return .none
        }

      case .pause:
        guard state.session?.playStatus == .playing else { return .none }
        state.pauseSession()
        return .merge(
          self.saveCheckpoint(state),
          .run { _ in
            await self.playback.pause()
          },
        )

      case .queueEntryRemoveRequested(let entryID):
        guard let queue = state.session?.queue,
              queue.upcomingEntries.contains(where: { $0.id == entryID }) else { return .none }
        state.pendingPlayNowItems = nil
        state.preparePlaylistSourcePlan(
          entries: queue.entries.filter { $0.id != entryID },
        )
        return .run { send in
          do {
            let snapshot = try await self.playback.removeQueueEntry(entryID)
            try Task.checkCancellation()
            await send(.playbackEvent(.snapshotChanged(snapshot)))
          } catch is CancellationError {
            return
          } catch {
            await send(.playbackFailed(.init(error: error)))
          }
        }
        .cancellable(id: CancelID.playbackStart, cancelInFlight: true)

      case .reorderUpcoming(let entryIDs):
        guard let session = state.session,
              entryIDs.count == session.queue.upcomingEntries.count,
              Set(entryIDs) == Set(session.queue.upcomingEntries.map(\.id)) else {
          return .none
        }
        state.pendingPlayNowItems = nil
        let upcomingByID = Dictionary(
          uniqueKeysWithValues: session.queue.upcomingEntries.map { ($0.id, $0) },
        )
        state.preparePlaylistSourcePlan(
          entries: Array(session.queue.entries.prefix(session.queue.currentIndex + 1))
            + entryIDs.compactMap { upcomingByID[$0] },
        )
        return .run { send in
          do {
            let snapshot = try await self.playback.reorderUpcoming(entryIDs)
            try Task.checkCancellation()
            await send(.playbackEvent(.snapshotChanged(snapshot)))
          } catch is CancellationError {
            return
          } catch {
            await send(.playbackFailed(.init(error: error)))
          }
        }
        .cancellable(id: CancelID.playbackStart, cancelInFlight: true)

      case .restoreCachedSession:
        guard state.session == nil,
              !state.isRestoringCheckpoint else { return .none }
        return .run { send in
          await send(.checkpointLoaded(try? self.playbackSessionCache.load()))
        }

      case .resume:
        guard state.session?.playStatus == .paused else { return .none }
        state.failure = nil
        state.resumeSession()
        return .merge(
          self.saveCheckpoint(state),
          .run { send in
            do {
              try await self.playback.resume()
            } catch {
              await send(.playbackFailed(.init(error: error)))
            }
          },
        )

      case .saveCachedSession:
        return self.saveCheckpoint(state)

      case .seek(let time):
        guard state.session != nil,
              state.progress.duration > 0 else { return .none }
        let duration = state.progress.duration
        let clampedTime = min(duration, max(0, time))
        state.setProgress(.init(elapsedTime: clampedTime, duration: duration))
        let seekEffect: EffectOf<Self> = .run { _ in
          await self.playback.seek(clampedTime)
        }
        .cancellable(id: CancelID.seek, cancelInFlight: true)
        return .merge(self.saveCheckpoint(state), seekEffect)

      case .skipToNext:
        guard state.session != nil else { return .none }
        return .run { send in
          guard let outcome = try? await self.playback.skipToNext(),
                outcome == .queueEnded else { return }
          await send(.playbackEvent(.queueEnded))
        }

      case .skipToPrevious:
        guard let session = state.session else { return .none }
        if state.progress.elapsedTime > 3 || session.queue.currentIndex == 0 {
          return .run { _ in
            await self.playback.restartCurrentEntry()
          }
        }
        return .run { _ in
          try? await self.playback.skipToPrevious()
        }

      case .stop:
        state.pauseSession()
        return .merge(
          .cancel(id: CancelID.playbackStart),
          self.saveCheckpoint(state),
          .run { _ in
            await self.playback.stop()
          },
        )

      case .playbackFailed(let failure):
        state.failure = failure
        state.pendingPlayNowItems = nil
        state.pendingPlaylistSourcePlan = nil
        state.pauseSession()
        log(
          failure.eventLevel,
          failure.eventDomain,
          failure.eventId,
          detail: "\(failure)",
        )
        return .none

      case .playbackFailureDismissed:
        state.failure = nil
        return .none

      case .playbackFailureActionTapped:
        guard state.failure?.opensSettings == true else { return .none }
        return .run { _ in
          await self.systemSettings.openAppSettings()
        }
      }
    }
  }

  private func applySnapshot(
    _ snapshot: PlaybackSnapshot,
    state: inout State,
  ) -> EffectOf<Self> {
    state.recordPlaylistSources(entries: state.session?.queue.entries ?? [])
    state.recordPlaylistSources(entries: snapshot.entries)
    let sourcePlan = state.pendingPlaylistSourcePlan ?? []
    state.playlistSourceHints = PlaybackSourceHintMatcher.match(
      plan: sourcePlan,
      entries: snapshot.entries,
      existing: state.playlistSourceHints,
    )
    if Self.hasMatchedAllPlaylistSources(
      in: sourcePlan,
      hints: state.playlistSourceHints,
    ) {
      state.pendingPlaylistSourcePlan = nil
    }
    guard var session = Session(
      snapshot: snapshot,
      sourceAlbumIDs: state.sourceAlbumIDs,
      playlistSourceHints: state.playlistSourceHints,
    ) else { return .none }
    let previousSession = state.session
    if previousSession?.isLoading == true, session.playStatus == .paused {
      session.playStatus = .loading
    }
    state.hasAuthoritativeSnapshot = !state.isRestoringCheckpoint
    state.progress = snapshot.progress
    state.session = session
    guard !state.isRestoringCheckpoint else { return .none }
    let shouldCacheImmediately = previousSession?.queue != session.queue
      || previousSession?.playStatus != session.playStatus
    if shouldCacheImmediately {
      state.lastCachedProgressBucket = Int(state.progress.elapsedTime / 5)
      return self.saveCheckpoint(state)
    }
    guard state.shouldCacheProgressSnapshot() else { return .none }
    return self.saveCheckpoint(state)
  }

  private static func hasMatchedAllPlaylistSources(
    in plan: [PlaybackSourceHintMatcher.Occurrence],
    hints: [PlaybackQueueEntry.ID: PlaylistPlaybackSource],
  ) -> Bool {
    var remaining = plan.compactMap(\.item.playlistSource)
    for hint in hints.values {
      if let index = remaining.firstIndex(of: hint) {
        remaining.remove(at: index)
      }
    }
    return remaining.isEmpty
  }

  private func insertIntoQueue(
    _ items: [PlaybackItem],
    position: PlaybackQueueInsertionPosition,
    state: inout State,
  ) -> EffectOf<Self> {
    guard !items.isEmpty else { return .none }
    if let queue = state.session?.queue {
      switch position {
      case .next:
        state.preparePlaylistSourcePlan(
          prefixEntries: Array(queue.entries.prefix(queue.currentIndex + 1)),
          newItems: items,
          suffixEntries: Array(queue.entries.dropFirst(queue.currentIndex + 1)),
        )
      case .tail:
        state.preparePlaylistSourcePlan(
          prefixEntries: queue.entries,
          newItems: items,
        )
      }
    } else {
      state.preparePlaylistSourcePlan(newItems: items)
    }
    state.failure = nil
    state.isRestoringCheckpoint = false
    state.pendingPlayNowItems = nil
    state.recordSourceAlbums(items)
    if state.session == nil {
      state.hasAuthoritativeSnapshot = false
      state.session = .init(
        playStatus: .loading,
        queue: .init(items: items),
      )
    }
    return .run { send in
      do {
        let snapshot = try await self.playback.insertIntoQueue(items, position)
        try Task.checkCancellation()
        await send(.playbackEvent(.snapshotChanged(snapshot)))
      } catch is CancellationError {
        return
      } catch {
        await send(.playbackFailed(.init(error: error)))
      }
    }
    .cancellable(id: CancelID.playbackStart, cancelInFlight: true)
  }

  private func saveCheckpoint(_ state: State) -> EffectOf<Self> {
    guard state.hasAuthoritativeSnapshot,
          !state.isRestoringCheckpoint,
          let session = state.session else { return .none }
    let checkpoint = PlaybackCheckpoint(
      session: session,
      progress: state.progress,
      sourceAlbumIDs: state.sourceAlbumIDs,
    )
    return .run { _ in
      try Task.checkCancellation()
      try? await self.playbackSessionCache.save(checkpoint)
    }
    .cancellable(id: CancelID.checkpointSave, cancelInFlight: true)
  }
}

extension PlaybackFeature.State {
  mutating func pauseSession() {
    self.setPlayStatus(.paused)
  }

  mutating func resumeSession() {
    self.setPlayStatus(.playing)
  }

  mutating func setPlayStatus(_ playStatus: PlaybackFeature.PlayStatus) {
    guard var session = self.session else { return }
    session.playStatus = playStatus
    self.session = session
  }

  mutating func setProgress(_ progress: PlaybackProgress) {
    guard self.session != nil else { return }
    self.progress = progress
  }

  mutating func recordPlaylistSources(entries: [PlaybackQueueEntry]) {
    for entry in entries {
      if let source = entry.item.playlistSource {
        self.playlistSourceHints[entry.id] = source
      }
    }
  }

  mutating func preparePlaylistSourcePlan(checkpoint: PlaybackCheckpoint) {
    let plan = zip(
      checkpoint.songIDs,
      checkpoint.playlistSourceHints,
    ).map { songID, source in
      PlaybackSourceHintMatcher.Occurrence(item: PlaybackItem(
        id: songID,
        title: "",
        artistName: "",
        artworkURL: nil,
        playlistSource: source,
      ))
    }
    self.setPendingPlaylistSourcePlan(plan)
  }

  mutating func preparePlaylistSourcePlan(entries: [PlaybackQueueEntry]) {
    self.recordPlaylistSources(entries: entries)
    self.setPendingPlaylistSourcePlan(entries.map {
      PlaybackSourceHintMatcher.Occurrence(
        item: $0.item,
        retainedEntryID: $0.id,
      )
    })
  }

  mutating func preparePlaylistSourcePlan(
    newItems: [PlaybackItem],
    retainedEntries: [PlaybackQueueEntry] = [],
  ) {
    self.preparePlaylistSourcePlan(
      prefixEntries: [],
      newItems: newItems,
      suffixEntries: retainedEntries,
    )
  }

  mutating func preparePlaylistSourcePlan(
    prefixEntries: [PlaybackQueueEntry],
    newItems: [PlaybackItem],
    suffixEntries: [PlaybackQueueEntry] = [],
  ) {
    let retainedEntries = prefixEntries + suffixEntries
    self.recordPlaylistSources(entries: retainedEntries)
    let plan = prefixEntries.map {
      PlaybackSourceHintMatcher.Occurrence(
        item: $0.item,
        retainedEntryID: $0.id,
      )
    } + newItems.map {
      PlaybackSourceHintMatcher.Occurrence(item: $0)
    } + suffixEntries.map {
      PlaybackSourceHintMatcher.Occurrence(
        item: $0.item,
        retainedEntryID: $0.id,
      )
    }
    self.setPendingPlaylistSourcePlan(plan)
  }

  private mutating func setPendingPlaylistSourcePlan(
    _ plan: [PlaybackSourceHintMatcher.Occurrence],
  ) {
    self.pendingPlaylistSourcePlan = self.playlistSourceHints.isEmpty
      && plan.allSatisfy { $0.item.playlistSource == nil }
      ? nil
      : plan
  }

  mutating func recordSourceAlbums(_ items: [PlaybackItem]) {
    for item in items {
      if let albumID = item.albumID {
        self.sourceAlbumIDs[item.id] = albumID
      }
    }
  }

  mutating func resolveCurrentAlbum(in library: ApprovedMusicLibrary) -> Bool {
    guard let item = self.session?.currentItem else { return false }
    if let albumID = self.sourceAlbumIDs[item.id],
       library.album(id: albumID) != nil {
      if item.albumID != albumID {
        self.setSourceAlbumID(albumID, for: item.id)
      }
      return true
    }
    self.sourceAlbumIDs[item.id] = nil
    guard let album = library.album(matching: item) else {
      if item.albumID != nil {
        self.setSourceAlbumID(nil, for: item.id)
      }
      return false
    }
    if item.albumID != album.id {
      self.setSourceAlbumID(album.id, for: item.id)
    }
    return true
  }

  mutating func setSourceAlbumID(
    _ albumID: ApprovedAlbum.ID?,
    for songID: ApprovedTrack.ID,
  ) {
    self.sourceAlbumIDs[songID] = albumID
    guard var session = self.session else { return }
    session.queue.entries = session.queue.entries.map { entry in
      guard entry.item.id == songID else { return entry }
      return PlaybackQueueEntry(
        id: entry.id,
        item: entry.item.withAlbumID(albumID),
      )
    }
    self.session = session
    if self.pendingAlbumResolutionSongID == songID, albumID != nil {
      self.pendingAlbumResolutionSongID = nil
    }
  }

  mutating func shouldCacheProgressSnapshot() -> Bool {
    guard self.session != nil else { return false }
    let bucket = Int(self.progress.elapsedTime / 5)
    guard bucket != self.lastCachedProgressBucket else { return false }
    self.lastCachedProgressBucket = bucket
    return true
  }
}

extension PlaybackFeature.Session {
  var currentItem: PlaybackItem {
    self.queue.currentItem
  }

  var nextItems: [PlaybackItem] {
    self.queue.upcomingItems
  }

  var isPlaying: Bool {
    self.playStatus == .playing
  }

  var isLoading: Bool {
    self.playStatus == .loading
  }

  var currentTrackID: ApprovedTrack.ID {
    self.currentItem.id
  }
}
