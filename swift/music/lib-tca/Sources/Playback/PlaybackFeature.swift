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
  case appleMusicSignInRequired
  case appleMusicSubscriptionRequired
  case catalogLookupFailed
  case musicAccessDenied
  case musicAccessRestricted
  case playbackFailed
  case privacyAcknowledgementRequired
  case trackUnavailable

  init(error: any Error) {
    switch error as? PlaybackClientError {
    case .appleMusicSignInRequired:
      self = .appleMusicSignInRequired
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
    case .appleMusicSignInRequired,
         .appleMusicSubscriptionRequired,
         .catalogLookupFailed,
         .playbackFailed,
         .privacyAcknowledgementRequired,
         .trackUnavailable:
      false
    }
  }
}

struct PlaybackFailureReport: Equatable, Sendable {
  var failure: PlaybackFailure
  var diagnostic: PlaybackDiagnostic?

  init(failure: PlaybackFailure, diagnostic: PlaybackDiagnostic? = nil) {
    self.failure = failure
    self.diagnostic = diagnostic
  }

  init(error: any Error) {
    self.failure = PlaybackFailure(error: error)
    self.diagnostic = (error as? PlaybackClientError)?.diagnostic
  }

  var logDetail: String {
    guard let logDetail = self.diagnostic?.logDetail, !logDetail.isEmpty else {
      return "\(self.failure)"
    }
    return "\(self.failure) \(logDetail)"
  }
}

@Reducer
struct PlaybackFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var approvedTrackIDs: Set<ApprovedTrack.ID>?
    var session: Session?
    var failure: PlaybackFailure?
    var hasAuthoritativeSnapshot = false
    var isRestoringCheckpoint = false
    var lastCachedProgressBucket: Int?
    var pendingAlbumResolutionSongID: ApprovedTrack.ID?
    var pendingMetadataPlan: [PlaybackMetadataHintMatcher.Occurrence]?
    var pendingPlayNowItems: [PlaybackItem]?
    var pendingQueueReplacementViewIDs: [String]?
    var pendingUpcomingViewIDs: [String]?
    var playbackContext: PlaybackContext?
    var playlistSourceHints: [PlaybackQueueEntry.ID: PlaylistPlaybackSource] = [:]
    var progress = PlaybackProgress.zero
    var queueRoleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [:]
    var shouldClearPlaybackOnUpcomingUpdateFailure = false
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

    var queuedEntries: [PlaybackQueueEntry] {
      self.upcomingEntries.filter { $0.role == .queued }
    }

    var contextEntries: [PlaybackQueueEntry] {
      self.upcomingEntries.filter { $0.role == .context }
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
      queueRoleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [:],
    ) {
      let entries = snapshot.entries.map { entry in
        PlaybackQueueEntry(
          id: entry.id,
          item: entry.item
            .withAlbumID(sourceAlbumIDs[entry.item.id])
            .withPlaylistSource(
              playlistSourceHints[entry.id] ?? entry.item.playlistSource,
            )
            .withQueueRole(
              queueRoleHints[entry.id] ?? entry.item.queueRole,
            ),
          viewID: entry.viewID,
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
    case approvedTrackIDsUpdated(Set<ApprovedTrack.ID>)
    case checkpointLoaded(PlaybackCheckpoint?)
    case checkpointRestorationFinished(PlaybackSnapshot?)
    case clearQueueButtonTapped
    case observePlayback
    case pause
    case playNext([PlaybackItem])
    case playNow(items: [PlaybackItem], startIndex: Int, context: PlaybackContext?)
    case playNowFinished(PlaybackSnapshot)
    case playbackEvent(PlaybackEvent)
    case playbackFailed(PlaybackFailureReport)
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case queueEntryRemoveRequested(String)
    case queueReplacementFailed(
      expectedViewIDs: [String],
      failure: PlaybackFailureReport,
    )
    case reorderUpcoming(
      entryViewIDs: [String],
      queuedEntryCount: Int,
    )
    case restoreCachedSession
    case resume
    case saveCachedSession
    case seek(TimeInterval)
    case skipToNext
    case skipToPrevious
    case stop
    case togglePlayPause
    case upcomingQueueUpdateFailed(
      expectedViewIDs: [String],
      failure: PlaybackFailureReport,
    )
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

      case .approvedTrackIDsUpdated(let approvedTrackIDs):
        state.approvedTrackIDs = approvedTrackIDs
        return self.reconcileApprovedQueue(state: &state) ?? .none

      case .checkpointLoaded(let loadedCheckpoint):
        guard state.session == nil,
              let loadedCheckpoint else { return .none }
        let activeCheckpoint = loadedCheckpoint.activeQueue
        let checkpoint: PlaybackCheckpoint? = if let approvedTrackIDs = state.approvedTrackIDs {
          activeCheckpoint.filtered(to: approvedTrackIDs)
        } else {
          activeCheckpoint
        }
        guard let checkpoint else {
          return .run { _ in
            await self.playback.clearQueue()
            await self.playbackSessionCache.delete()
          }
          .cancellable(id: CancelID.checkpointSave, cancelInFlight: true)
        }
        state.failure = nil
        state.hasAuthoritativeSnapshot = false
        state.isRestoringCheckpoint = true
        state.lastCachedProgressBucket = nil
        state.playbackContext = checkpoint.context
        state.sourceAlbumIDs.merge(checkpoint.sourceAlbumIDs) { _, new in new }
        state.prepareMetadataPlan(checkpoint: checkpoint)
        return .run { send in
          if checkpoint != activeCheckpoint {
            try? await self.playbackSessionCache.save(checkpoint)
          }
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

      case .clearQueueButtonTapped:
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              let queue = state.session?.queue,
              !queue.queuedEntries.isEmpty else { return .none }
        return self.updateUpcomingQueue(
          queue.contextEntries,
          state: &state,
        )

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
        state.pendingMetadataPlan = nil
        state.pendingPlayNowItems = nil
        state.pendingQueueReplacementViewIDs = nil
        state.pendingUpcomingViewIDs = nil
        state.playbackContext = nil
        state.playlistSourceHints.removeAll()
        state.progress = .zero
        state.queueRoleHints.removeAll()
        state.session = nil
        state.shouldClearPlaybackOnUpcomingUpdateFailure = false
        state.sourceAlbumIDs.removeAll()
        return .merge(
          .cancel(id: CancelID.playbackStart),
          .cancel(id: CancelID.seek),
          .run { _ in
            await self.playback.clearQueue()
            await self.playbackSessionCache.delete()
          }
          .cancellable(id: CancelID.checkpointSave, cancelInFlight: true),
        )

      case .playbackEvent(.progressChanged(let progress)):
        guard state.pendingPlayNowItems == nil,
              state.pendingQueueReplacementViewIDs == nil else { return .none }
        state.setProgress(progress)
        guard state.shouldCacheProgressSnapshot() else { return .none }
        return self.saveCheckpoint(state)

      case .playbackEvent(.snapshotChanged(let receivedSnapshot)):
        if let pendingItems = state.pendingPlayNowItems {
          guard receivedSnapshot.entries.map(\.item.id) == pendingItems.map(\.id) else {
            return .none
          }
          state.pendingPlayNowItems = nil
        }
        return self.applySnapshot(receivedSnapshot, state: &state)

      case .playNext(let items):
        return self.insertIntoQueue(items, position: .next, state: &state)

      case .playNow(let items, let startIndex, let context):
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              items.indices.contains(startIndex) else { return .none }
        let requestedItems = items[startIndex...]
          .filter { state.approvedTrackIDs?.contains($0.id) ?? true }
          .map { $0.withQueueRole(.context) }
        guard let currentItem = requestedItems.first else { return .none }
        let queuedItems = state.hasAuthoritativeSnapshot
          ? state.session?.queue.queuedEntries.map(\.item).filter {
            state.approvedTrackIDs?.contains($0.id) ?? true
          } ?? []
          : []
        let composedItems = [currentItem] + queuedItems + requestedItems.dropFirst()
        state.prepareMetadataPlan(newItems: composedItems)
        state.failure = nil
        state.hasAuthoritativeSnapshot = false
        state.isRestoringCheckpoint = false
        state.lastCachedProgressBucket = nil
        state.pendingPlayNowItems = composedItems
        state.pendingQueueReplacementViewIDs = nil
        state.pendingUpcomingViewIDs = nil
        state.playbackContext = context
        state.shouldClearPlaybackOnUpcomingUpdateFailure = false
        state.progress = .zero
        state.recordSourceAlbums(requestedItems)
        state.session = .init(
          playStatus: .loading,
          queue: .init(items: composedItems),
        )
        return .run { send in
          do {
            let snapshot = try await self.playback.playNow(composedItems, 0)
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
        guard let session = state.session,
              session.playStatus == .playing else { return .none }
        if state.pendingQueueReplacementViewIDs != nil {
          return self.replaceActiveQueue(
            with: Array(session.queue.entries[session.queue.currentIndex...]),
            playStatus: .paused,
            state: &state,
          )
        }
        state.pauseSession()
        return .merge(
          self.saveCheckpoint(state),
          .run { _ in
            await self.playback.pause()
          },
        )

      case .queueEntryRemoveRequested(let entryViewID):
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              let queue = state.session?.queue,
              queue.upcomingEntries.contains(where: {
                $0.viewID == entryViewID
              }) else { return .none }
        return self.updateUpcomingQueue(
          queue.upcomingEntries.filter { $0.viewID != entryViewID },
          state: &state,
        )

      case .queueReplacementFailed(let expectedViewIDs, let report):
        guard state.pendingQueueReplacementViewIDs == expectedViewIDs else { return .none }
        log(
          report.failure.eventLevel,
          report.failure.eventDomain,
          report.failure.eventId,
          detail: report.logDetail,
        )
        return .send(.playbackEvent(.queueEnded))

      case .reorderUpcoming(let entryViewIDs, let queuedEntryCount):
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              let queue = state.session?.queue,
              entryViewIDs.count == queue.upcomingEntries.count,
              Set(entryViewIDs) == Set(queue.upcomingEntries.map(\.viewID)),
              (0 ... entryViewIDs.count).contains(queuedEntryCount) else {
          return .none
        }
        let upcomingByViewID = Dictionary(
          uniqueKeysWithValues: queue.upcomingEntries.map { ($0.viewID, $0) },
        )
        let reorderedEntries = entryViewIDs.enumerated().compactMap { index, viewID in
          upcomingByViewID[viewID].map { entry in
            PlaybackQueueEntry(
              id: entry.id,
              item: entry.item.withQueueRole(
                index < queuedEntryCount ? .queued : .context,
              ),
              viewID: entry.viewID,
            )
          }
        }
        guard reorderedEntries.count == entryViewIDs.count else { return .none }
        return self.updateUpcomingQueue(
          reorderedEntries,
          state: &state,
        )

      case .upcomingQueueUpdateFailed(let expectedViewIDs, let report):
        guard state.pendingUpcomingViewIDs == expectedViewIDs else { return .none }
        let shouldClearPlayback = state.shouldClearPlaybackOnUpcomingUpdateFailure
        state.pendingUpcomingViewIDs = nil
        state.shouldClearPlaybackOnUpcomingUpdateFailure = false
        log(
          report.failure.eventLevel,
          report.failure.eventDomain,
          report.failure.eventId,
          detail: report.logDetail,
        )
        if shouldClearPlayback {
          return .send(.playbackEvent(.queueEnded))
        }
        state.failure = report.failure
        return .none

      case .restoreCachedSession:
        guard state.session == nil,
              !state.isRestoringCheckpoint else { return .none }
        return .run { send in
          await send(.checkpointLoaded(try? self.playbackSessionCache.load()))
        }

      case .resume:
        guard state.pendingQueueReplacementViewIDs == nil,
              state.session?.playStatus == .paused else { return .none }
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
        guard state.pendingQueueReplacementViewIDs == nil,
              state.session != nil,
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
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              state.session != nil else { return .none }
        return .run { send in
          guard let outcome = try? await self.playback.skipToNext(),
                outcome == .queueEnded else { return }
          await send(.playbackEvent(.queueEnded))
        }

      case .skipToPrevious:
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              let session = state.session else { return .none }
        if state.progress.elapsedTime > 3 || session.queue.currentIndex == 0 {
          return .run { _ in
            await self.playback.restartCurrentEntry()
          }
        }
        return .run { _ in
          try? await self.playback.skipToPrevious()
        }

      case .stop:
        if state.pendingQueueReplacementViewIDs != nil,
           let session = state.session {
          return self.replaceActiveQueue(
            with: Array(session.queue.entries[session.queue.currentIndex...]),
            playStatus: .paused,
            state: &state,
          )
        }
        let cancelPlaybackStart: EffectOf<Self> =
          state.shouldClearPlaybackOnUpcomingUpdateFailure
            ? .none
            : .cancel(id: CancelID.playbackStart)
        if !state.shouldClearPlaybackOnUpcomingUpdateFailure {
          state.pendingUpcomingViewIDs = nil
        }
        state.pauseSession()
        return .merge(
          cancelPlaybackStart,
          self.saveCheckpoint(state),
          .run { _ in
            await self.playback.stop()
          },
        )

      case .playbackFailed(let report):
        let failure = report.failure
        state.failure = failure
        state.pendingMetadataPlan = nil
        state.pendingPlayNowItems = nil
        state.pendingQueueReplacementViewIDs = nil
        state.pendingUpcomingViewIDs = nil
        state.shouldClearPlaybackOnUpcomingUpdateFailure = false
        state.pauseSession()
        log(
          failure.eventLevel,
          failure.eventDomain,
          failure.eventId,
          detail: report.logDetail,
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

  private static func preservingEntryMetadata(
    in snapshot: PlaybackSnapshot,
    from queue: Queue?,
  ) -> PlaybackSnapshot {
    guard let queue else { return snapshot }
    var availableEntries = queue.entries
    var previousEntries = [PlaybackQueueEntry?](repeating: nil, count: snapshot.entries.count)

    for index in snapshot.entries.indices {
      let entry = snapshot.entries[index]
      guard let matchingIndex = availableEntries.firstIndex(where: {
        $0.id == entry.id && $0.item.id == entry.item.id
      }) else { continue }
      previousEntries[index] = availableEntries.remove(at: matchingIndex)
    }

    for index in snapshot.entries.indices where previousEntries[index] == nil {
      let entry = snapshot.entries[index]
      guard let matchingIndex = availableEntries.firstIndex(where: {
        $0.item.id == entry.item.id
      }) else { continue }
      previousEntries[index] = availableEntries.remove(at: matchingIndex)
    }

    return PlaybackSnapshot(
      entries: snapshot.entries.indices.map { index in
        let entry = snapshot.entries[index]
        guard let previousEntry = previousEntries[index] else { return entry }
        return PlaybackQueueEntry(
          id: entry.id,
          item: entry.item
            .withAlbumID(previousEntry.item.albumID ?? entry.item.albumID)
            .withArtworkURL(previousEntry.item.artworkURL ?? entry.item.artworkURL)
            .withPlaylistSource(
              previousEntry.item.playlistSource ?? entry.item.playlistSource,
            )
            .withQueueRole(previousEntry.item.queueRole ?? entry.item.queueRole),
          viewID: previousEntry.viewID.hasPrefix("pending:")
            ? entry.viewID
            : previousEntry.viewID,
        )
      },
      currentEntryID: snapshot.currentEntryID,
      playStatus: snapshot.playStatus,
      progress: snapshot.progress,
    )
  }

  private func applySnapshot(
    _ receivedSnapshot: PlaybackSnapshot,
    state: inout State,
  ) -> EffectOf<Self> {
    let snapshot = Self.preservingEntryMetadata(
      in: receivedSnapshot,
      from: state.session?.queue,
    )
    if let expectedViewIDs = state.pendingQueueReplacementViewIDs {
      guard let receivedQueue = Queue(
        entries: snapshot.entries,
        currentEntryID: snapshot.currentEntryID,
      ), receivedQueue.currentIndex == 0,
      receivedQueue.entries.map(\.viewID) == expectedViewIDs else { return .none }
      state.pendingQueueReplacementViewIDs = nil
    }
    if let expectedViewIDs = state.pendingUpcomingViewIDs {
      guard let receivedQueue = Queue(
        entries: snapshot.entries,
        currentEntryID: snapshot.currentEntryID,
      ) else { return .none }
      if receivedQueue.currentEntry.viewID == state.session?.queue.currentEntry.viewID,
         receivedQueue.upcomingEntries.map(\.viewID) != expectedViewIDs {
        return .none
      }
      state.pendingUpcomingViewIDs = nil
      state.shouldClearPlaybackOnUpcomingUpdateFailure = false
    }
    state.recordMetadata(entries: snapshot.entries)
    let metadataPlan = state.pendingMetadataPlan ?? []
    state.playlistSourceHints = PlaybackMetadataHintMatcher.match(
      plan: metadataPlan,
      entries: snapshot.entries,
      existing: state.playlistSourceHints,
    )
    state.queueRoleHints = PlaybackMetadataHintMatcher.match(
      plan: metadataPlan,
      entries: snapshot.entries,
      existing: state.queueRoleHints,
      value: { $0.queueRole },
    )
    if Self.hasMatchedAllMetadata(
      in: metadataPlan,
      playlistSourceHints: state.playlistSourceHints,
      queueRoleHints: state.queueRoleHints,
    ) {
      state.pendingMetadataPlan = nil
    }
    guard var session = Session(
      snapshot: snapshot,
      sourceAlbumIDs: state.sourceAlbumIDs,
      playlistSourceHints: state.playlistSourceHints,
      queueRoleHints: state.queueRoleHints,
    ) else { return .none }
    let previousSession = state.session
    if previousSession?.isLoading == true, session.playStatus == .paused {
      session.playStatus = .loading
    }
    state.hasAuthoritativeSnapshot = !state.isRestoringCheckpoint
    state.progress = snapshot.progress
    if previousSession != session {
      state.session = session
    }
    guard !state.isRestoringCheckpoint else { return .none }
    if let reconciliation = self.reconcileApprovedQueue(state: &state) {
      return reconciliation
    }
    let shouldCacheImmediately = previousSession?.queue != session.queue
      || previousSession?.playStatus != session.playStatus
    if shouldCacheImmediately {
      state.lastCachedProgressBucket = Int(state.progress.elapsedTime / 5)
      return self.saveCheckpoint(state)
    }
    guard state.shouldCacheProgressSnapshot() else { return .none }
    return self.saveCheckpoint(state)
  }

  private static func hasMatchedAllMetadata(
    in plan: [PlaybackMetadataHintMatcher.Occurrence],
    playlistSourceHints: [PlaybackQueueEntry.ID: PlaylistPlaybackSource],
    queueRoleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole],
  ) -> Bool {
    self.hasMatchedAll(
      plan.compactMap(\.item.playlistSource),
      with: Array(playlistSourceHints.values),
    ) && self.hasMatchedAll(
      plan.compactMap(\.item.queueRole),
      with: Array(queueRoleHints.values),
    )
  }

  private static func hasMatchedAll<Value: Equatable>(
    _ expected: [Value],
    with actual: [Value],
  ) -> Bool {
    var remaining = expected
    for value in actual {
      if let index = remaining.firstIndex(of: value) {
        remaining.remove(at: index)
      }
    }
    return remaining.isEmpty
  }

  private func reconcileApprovedQueue(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.hasAuthoritativeSnapshot,
          !state.isRestoringCheckpoint,
          let approvedTrackIDs = state.approvedTrackIDs,
          let session = state.session else { return nil }
    let queue = session.queue
    if let pendingViewIDs = state.pendingQueueReplacementViewIDs {
      let approvedEntries = queue.entries[queue.currentIndex...].filter {
        approvedTrackIDs.contains($0.item.id)
      }
      guard !approvedEntries.isEmpty else {
        return .send(.playbackEvent(.queueEnded))
      }
      guard approvedEntries.map(\.viewID) != pendingViewIDs else { return nil }
      return self.replaceActiveQueue(
        with: approvedEntries,
        playStatus: session.playStatus,
        state: &state,
      )
    }
    let approvedUpcomingEntries = queue.upcomingEntries.filter {
      approvedTrackIDs.contains($0.item.id)
    }
    if !approvedTrackIDs.contains(queue.currentItem.id) {
      guard !approvedUpcomingEntries.isEmpty else {
        return .send(.playbackEvent(.queueEnded))
      }
      return self.replaceActiveQueue(
        with: approvedUpcomingEntries,
        playStatus: session.playStatus,
        state: &state,
      )
    }
    guard approvedUpcomingEntries.count != queue.upcomingEntries.count else { return nil }
    return self.updateUpcomingQueue(
      approvedUpcomingEntries,
      clearPlaybackOnFailure: true,
      state: &state,
    )
  }

  private func replaceActiveQueue(
    with entries: [PlaybackQueueEntry],
    playStatus: PlayStatus,
    state: inout State,
  ) -> EffectOf<Self> {
    guard let firstEntry = entries.first,
          let queue = Queue(
            entries: entries,
            currentEntryID: firstEntry.id,
          ) else { return .none }
    let expectedViewIDs = entries.map(\.viewID)
    let retainedEntryIDs = Set(entries.map(\.id))
    let retainedTrackIDs = Set(entries.map(\.item.id))
    state.failure = nil
    state.lastCachedProgressBucket = 0
    state.pendingAlbumResolutionSongID = nil
    state.pendingMetadataPlan = nil
    state.pendingPlayNowItems = nil
    state.pendingQueueReplacementViewIDs = expectedViewIDs
    state.pendingUpcomingViewIDs = nil
    state.playlistSourceHints = state.playlistSourceHints.filter {
      retainedEntryIDs.contains($0.key)
    }
    state.progress = .zero
    state.queueRoleHints = state.queueRoleHints.filter {
      retainedEntryIDs.contains($0.key)
    }
    state.recordMetadata(entries: entries)
    state.session = .init(playStatus: playStatus, queue: queue)
    state.shouldClearPlaybackOnUpcomingUpdateFailure = false
    state.sourceAlbumIDs = state.sourceAlbumIDs.filter {
      retainedTrackIDs.contains($0.key)
    }
    if !entries.contains(where: { $0.role == .context }) {
      state.playbackContext = nil
    }
    let replacementEffect: EffectOf<Self> = .run { send in
      do {
        let snapshot = try await self.playback.replaceQueue(
          entries,
          playStatus != .paused,
        )
        try Task.checkCancellation()
        await send(.playbackEvent(.snapshotChanged(snapshot)))
      } catch is CancellationError {
        return
      } catch {
        await send(.queueReplacementFailed(
          expectedViewIDs: expectedViewIDs,
          failure: .init(error: error),
        ))
      }
    }
    .cancellable(id: CancelID.playbackStart, cancelInFlight: true)
    return .merge(
      self.saveCheckpoint(state),
      replacementEffect,
    )
  }

  private func updateUpcomingQueue(
    _ upcomingEntries: [PlaybackQueueEntry],
    clearPlaybackOnFailure: Bool = false,
    state: inout State,
  ) -> EffectOf<Self> {
    guard let session = state.session else { return .none }
    let expectedViewIDs = upcomingEntries.map(\.viewID)
    let physicalOrderChanged = expectedViewIDs != session.queue.upcomingEntries.map(\.viewID)
    let entries = Array(session.queue.entries.prefix(session.queue.currentIndex + 1))
      + upcomingEntries
    state.failure = nil
    state.pendingMetadataPlan = nil
    state.pendingPlayNowItems = nil
    state.recordMetadata(entries: entries)
    state.session?.queue.entries = entries
    if !entries.contains(where: { $0.role == .context }) {
      state.playbackContext = nil
    }
    if !physicalOrderChanged {
      return self.saveCheckpoint(state)
    }
    state.pendingUpcomingViewIDs = expectedViewIDs
    state.shouldClearPlaybackOnUpcomingUpdateFailure = clearPlaybackOnFailure
    let updateEffect: EffectOf<Self> = .run { send in
      do {
        let snapshot = try await self.playback.setUpcoming(upcomingEntries)
        try Task.checkCancellation()
        await send(.playbackEvent(.snapshotChanged(snapshot)))
      } catch is CancellationError {
        return
      } catch {
        await send(.upcomingQueueUpdateFailed(
          expectedViewIDs: expectedViewIDs,
          failure: .init(error: error),
        ))
      }
    }
    .cancellable(id: CancelID.playbackStart, cancelInFlight: true)
    return .merge(
      self.saveCheckpoint(state),
      updateEffect,
    )
  }

  private func insertIntoQueue(
    _ items: [PlaybackItem],
    position: PlaybackQueueInsertionPosition,
    state: inout State,
  ) -> EffectOf<Self> {
    guard state.pendingQueueReplacementViewIDs == nil,
          !state.shouldClearPlaybackOnUpcomingUpdateFailure else { return .none }
    let queuedItems = items
      .filter { state.approvedTrackIDs?.contains($0.id) ?? true }
      .map { $0.withQueueRole(.queued) }
    guard !queuedItems.isEmpty else { return .none }
    let target: PlaybackQueueInsertionTarget
    if let queue = state.session?.queue {
      switch position {
      case .next:
        target = .next
        state.prepareMetadataPlan(
          prefixEntries: Array(queue.entries.prefix(queue.currentIndex + 1)),
          newItems: queuedItems,
          suffixEntries: Array(queue.entries.dropFirst(queue.currentIndex + 1)),
        )
      case .tail:
        if let firstContextEntry = queue.upcomingEntries.first(where: {
          $0.role == .context
        }), let insertionIndex = queue.entries.firstIndex(where: {
          $0.id == firstContextEntry.id
        }) {
          target = .before(firstContextEntry)
          state.prepareMetadataPlan(
            prefixEntries: Array(queue.entries[..<insertionIndex]),
            newItems: queuedItems,
            suffixEntries: Array(queue.entries[insertionIndex...]),
          )
        } else {
          target = .tail
          state.prepareMetadataPlan(
            prefixEntries: queue.entries,
            newItems: queuedItems,
          )
        }
      }
    } else {
      target = .tail
      state.prepareMetadataPlan(newItems: queuedItems)
    }
    state.failure = nil
    state.isRestoringCheckpoint = false
    state.pendingPlayNowItems = nil
    state.pendingUpcomingViewIDs = nil
    state.shouldClearPlaybackOnUpcomingUpdateFailure = false
    state.recordSourceAlbums(queuedItems)
    if state.session == nil {
      state.hasAuthoritativeSnapshot = false
      state.playbackContext = nil
      state.session = .init(
        playStatus: .loading,
        queue: .init(items: queuedItems),
      )
    }
    return .run { send in
      do {
        let snapshot = try await self.playback.insertIntoQueue(queuedItems, target)
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
      context: state.playbackContext,
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
  var activePlaybackContext: PlaybackContext? {
    guard self.session?.queue.currentEntry.role == .context else { return nil }
    return self.playbackContext
  }

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

  mutating func recordMetadata(entries: [PlaybackQueueEntry]) {
    for entry in entries {
      if let source = entry.item.playlistSource {
        self.playlistSourceHints[entry.id] = source
      }
      if let role = entry.item.queueRole {
        self.queueRoleHints[entry.id] = role
      }
    }
  }

  mutating func prepareMetadataPlan(checkpoint: PlaybackCheckpoint) {
    let plan = checkpoint.songIDs.indices.map { index in
      PlaybackMetadataHintMatcher.Occurrence(item: PlaybackItem(
        id: checkpoint.songIDs[index],
        title: "",
        artistName: "",
        artworkURL: nil,
        playlistSource: checkpoint.playlistSourceHints[index],
        queueRole: checkpoint.queueRoles?[index],
      ))
    }
    self.setPendingMetadataPlan(plan)
  }

  mutating func prepareMetadataPlan(newItems: [PlaybackItem]) {
    self.prepareMetadataPlan(
      prefixEntries: [],
      newItems: newItems,
    )
  }

  mutating func prepareMetadataPlan(
    prefixEntries: [PlaybackQueueEntry],
    newItems: [PlaybackItem],
    suffixEntries: [PlaybackQueueEntry] = [],
  ) {
    let retainedEntries = prefixEntries + suffixEntries
    self.recordMetadata(entries: retainedEntries)
    let plan = prefixEntries.map {
      PlaybackMetadataHintMatcher.Occurrence(
        item: $0.item,
        retainedEntryID: $0.id,
      )
    } + newItems.map {
      PlaybackMetadataHintMatcher.Occurrence(item: $0)
    } + suffixEntries.map {
      PlaybackMetadataHintMatcher.Occurrence(
        item: $0.item,
        retainedEntryID: $0.id,
      )
    }
    self.setPendingMetadataPlan(plan)
  }

  private mutating func setPendingMetadataPlan(
    _ plan: [PlaybackMetadataHintMatcher.Occurrence],
  ) {
    self.pendingMetadataPlan = self.playlistSourceHints.isEmpty
      && self.queueRoleHints.isEmpty
      && plan.allSatisfy {
        $0.item.playlistSource == nil && $0.item.queueRole == nil
      }
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
        viewID: entry.viewID,
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
