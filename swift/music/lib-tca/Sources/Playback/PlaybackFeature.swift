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

enum PlaybackEndBehavior: String, Codable, Equatable, Sendable {
  case finite
  case infinite
  case loopCollection
  case loopTrack
}

struct PlaybackPreferences: Codable, Equatable, Sendable {
  var endBehavior: PlaybackEndBehavior = .finite
  var isShuffleEnabled = false
}

@Reducer
struct PlaybackFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var approvedLibrary: ApprovedMusicLibrary?
    var approvedTrackIDs: Set<ApprovedTrack.ID>?
    var session: Session?
    var failure: PlaybackFailure?
    var hasAuthoritativeSnapshot = false
    var infinitePlaybackPlan: InfinitePlaybackPlan?
    var isRestoringCheckpoint = false
    var lastCachedProgressBucket: Int?
    var pendingAlbumResolutionViewID: PlaybackQueueEntry.ID?
    var pendingInfiniteLookaheadInsertion: InfiniteLookaheadInsertion?
    var pendingMetadataPlan: [PlaybackMetadataHintMatcher.Occurrence]?
    var pendingPlayNowItems: [PlaybackItem]?
    var pendingQueueReplacementViewIDs: [String]?
    var pendingRepeatCycleEntryIDs: [PlaybackSource.Entry.ID]?
    var pendingUpcomingViewIDs: [String]?
    var playbackContext: PlaybackContext?
    var playbackSource: PlaybackSource?
    var playlistSourceHints: [PlaybackQueueEntry.ID: PlaylistPlaybackSource] = [:]
    var preferences = PlaybackPreferences()
    var progress = PlaybackProgress.zero
    var queueRoleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [:]
    var shouldClearPlaybackOnUpcomingUpdateFailure = false
    var sourceAlbumIDs: [ApprovedTrack.ID: ApprovedAlbum.ID] = [:]
    var sourceEntryIDHints: [PlaybackQueueEntry.ID: PlaybackSource.Entry.ID] = [:]
    var temporarilyMissingUpcomingEntries: [PlaybackQueueEntry] = []
  }

  struct InfiniteLookaheadInsertion: Equatable, Sendable {
    let entries: [PlaybackSourceQueuePlanEntry]
    let remainingPlan: InfinitePlaybackPlan
  }

  private struct InfinitePlaybackProjection {
    let entries: [PlaybackSourceQueuePlanEntry]
    let remainingPlan: InfinitePlaybackPlan
  }

  private struct InfiniteUpcomingProjection {
    let entries: [PlaybackQueueEntry]
    let remainingPlan: InfinitePlaybackPlan
  }

  struct Queue: Equatable, Sendable {
    var entries: [PlaybackQueueEntry]
    var currentIndex: Int

    init(
      items: [PlaybackItem],
      currentIndex: Int = 0,
    ) {
      self.init(
        items: items,
        sourceEntryIDs: Array(repeating: nil, count: items.count),
        currentIndex: currentIndex,
      )
    }

    init(
      items: [PlaybackItem],
      sourceEntryIDs: [PlaybackSource.Entry.ID?],
      currentIndex: Int = 0,
    ) {
      precondition(items.count == sourceEntryIDs.count)
      self.entries = zip(items, sourceEntryIDs).enumerated().map { index, pair in
        PlaybackQueueEntry(
          id: "pending:\(index):\(pair.0.id.rawValue)",
          item: pair.0,
          sourceEntryID: pair.1,
        )
      }
      self.currentIndex = items.indices.contains(currentIndex) ? currentIndex : 0
    }

    init(plannedEntries: [PlaybackSourceQueuePlanEntry]) {
      precondition(!plannedEntries.isEmpty)
      self.entries = plannedEntries.enumerated().map { index, entry in
        switch entry {
        case .explicit(let entry):
          entry
        case .generated, .source:
          PlaybackQueueEntry(
            id: "pending:\(index):\(entry.item.id.rawValue)",
            item: entry.item,
            sourceEntryID: entry.sourceEntryID,
          )
        }
      }
      self.currentIndex = 0
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
      sourceEntryIDHints: [PlaybackQueueEntry.ID: PlaybackSource.Entry.ID] = [:],
    ) {
      let entries = snapshot.entries.map { entry in
        PlaybackQueueEntry(
          id: entry.id,
          item: entry.item
            .withAlbumID(entry.item.albumID ?? sourceAlbumIDs[entry.item.id])
            .withPlaylistSource(
              playlistSourceHints[entry.id] ?? entry.item.playlistSource,
            )
            .withQueueRole(
              queueRoleHints[entry.id] ?? entry.item.queueRole,
            ),
          sourceEntryID: sourceEntryIDHints[entry.id] ?? entry.sourceEntryID,
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
    case approvedLibraryUpdated(ApprovedMusicLibrary)
    case approvedTrackIDsUpdated(Set<ApprovedTrack.ID>)
    case checkpointLoaded(PlaybackCheckpoint?)
    case checkpointRestorationFinished(PlaybackSnapshot?)
    case clearQueueButtonTapped
    case infiniteButtonTapped
    case infiniteLookaheadInsertionFinished(PlaybackSnapshot)
    case observePlayback
    case pause
    case playNext([PlaybackItem])
    case playNow(items: [PlaybackItem], start: PlaybackStartIntent, context: PlaybackContext?)
    case playNowFinished(PlaybackSnapshot)
    case playbackEvent(PlaybackEvent)
    case playbackFailed(PlaybackFailureReport)
    case playbackFailureActionTapped
    case playbackFailureDismissed
    case playbackPreferencesLoaded(PlaybackPreferences)
    case queueEntryRemoveRequested(String)
    case queueReplacementFailed(
      expectedViewIDs: [String],
      failure: PlaybackFailureReport,
    )
    case reorderUpcoming(
      entryViewIDs: [String],
      queuedEntryCount: Int,
    )
    case repeatButtonTapped
    case restoreCachedSession
    case restorePlaybackPreferences
    case resume
    case resumeFinished
    case saveCachedSession
    case seek(TimeInterval)
    case shuffleButtonTapped
    case skipToNext
    case skipToNextFinished(PlaybackSkipOutcome)
    case skipToPrevious
    case skipToPreviousFinished
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
    case playbackPreferencesSave
    case playbackRepeatModeUpdate
    case playbackStart
    case seek
  }

  @Dependency(\.playback) var playback
  @Dependency(\.playbackPreferences) var playbackPreferences
  @Dependency(\.playbackSessionCache) var playbackSessionCache
  @Dependency(\.systemSettings) var systemSettings
  @Dependency(\.withRandomNumberGenerator) var withRandomNumberGenerator

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addToQueue(let items):
        return self.insertIntoQueue(items, position: .tail, state: &state)

      case .approvedLibraryUpdated(let approvedLibrary):
        state.approvedLibrary = approvedLibrary
        state.restoreWebArtwork(using: approvedLibrary)
        return self.updateApprovedTrackIDs(
          approvedLibrary.approvedTrackIDs,
          state: &state,
        )

      case .approvedTrackIDsUpdated(let approvedTrackIDs):
        return self.updateApprovedTrackIDs(approvedTrackIDs, state: &state)

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
        state.infinitePlaybackPlan = state.preferences.endBehavior == .infinite
          ? checkpoint.infinitePlaybackPlan
          : nil
        state.isRestoringCheckpoint = true
        state.lastCachedProgressBucket = nil
        state.playbackContext = checkpoint.context
        state.playbackSource = checkpoint.playbackSource
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
        guard state.pendingInfiniteLookaheadInsertion == nil,
              state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              let queue = state.session?.queue,
              !queue.queuedEntries.isEmpty else { return .none }
        return self.updateUpcomingQueue(
          queue.contextEntries,
          state: &state,
        )

      case .infiniteButtonTapped:
        let wasInfinite = state.preferences.endBehavior == .infinite
        state.preferences.endBehavior = wasInfinite ? .finite : .infinite
        state.pendingRepeatCycleEntryIDs = nil
        let queueUpdate = wasInfinite
          ? self.disableInfinitePlayback(state: &state)
          : self.enableInfinitePlayback(state: &state)
        self.prepareRepeatCollectionCycleIfNeeded(state: &state)
        return .merge(
          self.savePreferences(state.preferences),
          self.synchronizePlaybackRepeatMode(state.preferences.endBehavior),
          queueUpdate ?? .none,
        )

      case .infiniteLookaheadInsertionFinished(let snapshot):
        guard let insertion = state.pendingInfiniteLookaheadInsertion else { return .none }
        let insertedItemIDs = insertion.entries.map(\.item.id)
        guard snapshot.entries.suffix(insertedItemIDs.count).map(\.item.id)
          == insertedItemIDs else { return .none }
        state.infinitePlaybackPlan = insertion.remainingPlan
        state.pendingInfiniteLookaheadInsertion = nil
        return self.applySnapshot(snapshot, state: &state)

      case .observePlayback:
        return .run { send in
          for await event in self.playback.events() {
            await send(.playbackEvent(event))
          }
        }
        .cancellable(id: CancelID.playbackEvents, cancelInFlight: true)

      case .playbackEvent(.queueEnded):
        if let restart = self.restartLoopCollection(state: &state)
          ?? self.restartInfinitePlayback(state: &state) {
          return restart
        }
        guard state.session != nil || state.isRestoringCheckpoint else { return .none }
        state.failure = nil
        state.hasAuthoritativeSnapshot = false
        state.infinitePlaybackPlan = nil
        state.isRestoringCheckpoint = false
        state.lastCachedProgressBucket = nil
        state.pendingAlbumResolutionViewID = nil
        state.pendingInfiniteLookaheadInsertion = nil
        state.pendingMetadataPlan = nil
        state.pendingPlayNowItems = nil
        state.pendingQueueReplacementViewIDs = nil
        state.pendingRepeatCycleEntryIDs = nil
        state.pendingUpcomingViewIDs = nil
        state.playbackContext = nil
        state.playbackSource = nil
        state.playlistSourceHints.removeAll()
        state.progress = .zero
        state.queueRoleHints.removeAll()
        state.session = nil
        state.shouldClearPlaybackOnUpcomingUpdateFailure = false
        state.sourceAlbumIDs.removeAll()
        state.sourceEntryIDHints.removeAll()
        state.temporarilyMissingUpcomingEntries.removeAll()
        return .merge(
          .cancel(id: CancelID.playbackStart),
          .cancel(id: CancelID.seek),
          .run { _ in
            await self.playback.clearQueue()
            await self.playbackSessionCache.delete()
          }
          .cancellable(id: CancelID.checkpointSave, cancelInFlight: true),
        )

      case .playbackPreferencesLoaded(let preferences):
        state.preferences = preferences
        state.pendingRepeatCycleEntryIDs = nil
        self.prepareRepeatCollectionCycleIfNeeded(state: &state)
        return self.synchronizePlaybackRepeatMode(preferences.endBehavior)

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

      case .playNow(let items, let start, let context):
        let startIndex: Int
        let plannerStart: PlaybackSourceQueuePlanner.Start
        switch start {
        case .collection:
          startIndex = 0
          plannerStart = .collection
        case .selectedEntry(let index):
          startIndex = index
          plannerStart = .selectedEntry
        }
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              items.indices.contains(startIndex) else { return .none }
        let approvedItems = items.filter {
          state.approvedTrackIDs?.contains($0.id) ?? true
        }
        let selectedIndex = items[..<startIndex].count(where: {
          state.approvedTrackIDs?.contains($0.id) ?? true
        })
        guard approvedItems.indices.contains(selectedIndex) else { return .none }
        let playbackSource = PlaybackSource(
          items: approvedItems,
          selectedIndex: selectedIndex,
          context: context,
        )
        let explicitEntries = state.hasAuthoritativeSnapshot
          ? state.session?.queue.queuedEntries.filter {
            state.approvedTrackIDs?.contains($0.item.id) ?? true
          } ?? []
          : []
        guard let plannedEntries = PlaybackSourceQueuePlanner.startingEntries(
          source: playbackSource,
          start: plannerStart,
          explicitEntries: explicitEntries,
          isShuffleEnabled: state.preferences.isShuffleEnabled,
          shuffle: { $0 = self.shuffled($0) },
        ) else { return .none }
        var projectedEntries = plannedEntries
        var infinitePlaybackPlan: InfinitePlaybackPlan?
        if state.preferences.endBehavior == .infinite,
           let approvedLibrary = state.approvedLibrary,
           let preparedPlan = self.makeInfinitePlaybackPlan(
             source: playbackSource,
             plannedEntries: plannedEntries,
             library: approvedLibrary,
           ),
           let projection = self.makeInfinitePlaybackProjection(
             preparedPlan,
             source: playbackSource,
             plannedEntries: plannedEntries,
             library: approvedLibrary,
           ) {
          projectedEntries = projection.entries
          infinitePlaybackPlan = projection.remainingPlan
        }
        let composedItems = projectedEntries.map(\.item)
        let sourceItems = projectedEntries.compactMap { entry -> PlaybackItem? in
          guard case .explicit = entry else { return entry.item }
          return nil
        }
        state.prepareMetadataPlan(plannedEntries: projectedEntries)
        state.failure = nil
        state.hasAuthoritativeSnapshot = false
        state.infinitePlaybackPlan = infinitePlaybackPlan
        state.isRestoringCheckpoint = false
        state.lastCachedProgressBucket = nil
        state.pendingInfiniteLookaheadInsertion = nil
        state.pendingPlayNowItems = composedItems
        state.pendingQueueReplacementViewIDs = nil
        state.pendingRepeatCycleEntryIDs = nil
        state.pendingUpcomingViewIDs = nil
        state.playbackContext = context
        state.playbackSource = playbackSource
        state.shouldClearPlaybackOnUpcomingUpdateFailure = false
        state.progress = .zero
        state.recordSourceAlbums(sourceItems)
        state.sourceEntryIDHints.removeAll()
        state.temporarilyMissingUpcomingEntries.removeAll()
        state.session = .init(
          playStatus: .loading,
          queue: .init(plannedEntries: projectedEntries),
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
        guard state.pendingInfiniteLookaheadInsertion == nil,
              state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              let queue = state.session?.queue,
              let removedEntry = queue.upcomingEntries.first(where: {
                $0.viewID == entryViewID
              }) else { return .none }
        if let sourceEntryID = removedEntry.sourceEntryID {
          state.playbackSource?.remove(sourceEntryID)
        }
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
        guard state.pendingInfiniteLookaheadInsertion == nil,
              state.pendingQueueReplacementViewIDs == nil,
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
              sourceEntryID: entry.sourceEntryID,
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

      case .repeatButtonTapped:
        let wasInfinite = state.preferences.endBehavior == .infinite
        state.preferences.endBehavior = switch state.preferences.endBehavior {
        case .finite, .infinite:
          .loopCollection
        case .loopCollection:
          .loopTrack
        case .loopTrack:
          .finite
        }
        let queueUpdate = wasInfinite
          ? self.disableInfinitePlayback(state: &state)
          : nil
        state.infinitePlaybackPlan = nil
        state.pendingInfiniteLookaheadInsertion = nil
        state.pendingRepeatCycleEntryIDs = nil
        self.prepareRepeatCollectionCycleIfNeeded(state: &state)
        return .merge(
          self.savePreferences(state.preferences),
          self.synchronizePlaybackRepeatMode(state.preferences.endBehavior),
          queueUpdate ?? .none,
        )

      case .restoreCachedSession:
        guard state.session == nil,
              !state.isRestoringCheckpoint else { return .none }
        return .run { send in
          await send(.checkpointLoaded(try? self.playbackSessionCache.load()))
        }

      case .restorePlaybackPreferences:
        return .run { send in
          await send(.playbackPreferencesLoaded(self.playbackPreferences.load()))
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
              await send(.resumeFinished)
            } catch {
              await send(.playbackFailed(.init(error: error)))
            }
          },
        )

      case .resumeFinished:
        return .none

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

      case .shuffleButtonTapped:
        state.preferences.isShuffleEnabled.toggle()
        state.pendingRepeatCycleEntryIDs = nil
        let savePreferences = self.savePreferences(state.preferences)
        let updateUpcomingQueue = state.preferences.endBehavior == .infinite
          ? self.updateInfiniteUpcomingQueueForShufflePreference(state: &state)
          : self.updateUpcomingQueueForShufflePreference(state: &state)
        self.prepareRepeatCollectionCycleIfNeeded(state: &state)
        guard let updateUpcomingQueue else { return savePreferences }
        return .merge(savePreferences, updateUpcomingQueue)

      case .skipToNext:
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              state.session != nil else { return .none }
        return .run { send in
          guard let outcome = try? await self.playback.skipToNext() else { return }
          await send(.skipToNextFinished(outcome))
        }

      case .skipToNextFinished(.advanced):
        return .none

      case .skipToNextFinished(.queueEnded):
        return .send(.playbackEvent(.queueEnded))

      case .skipToPrevious:
        guard state.pendingQueueReplacementViewIDs == nil,
              !state.shouldClearPlaybackOnUpcomingUpdateFailure,
              let session = state.session else { return .none }
        if state.progress.elapsedTime > 3 || session.queue.currentIndex == 0 {
          return .run { send in
            await self.playback.restartCurrentEntry()
            await send(.skipToPreviousFinished)
          }
        }
        return .run { send in
          do {
            try await self.playback.skipToPrevious()
            await send(.skipToPreviousFinished)
          } catch {}
        }

      case .skipToPreviousFinished:
        return .none

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
        state.pendingInfiniteLookaheadInsertion = nil
        state.pendingMetadataPlan = nil
        state.pendingPlayNowItems = nil
        state.pendingQueueReplacementViewIDs = nil
        state.pendingRepeatCycleEntryIDs = nil
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

    if snapshot.entries.map(\.item.id) == queue.entries.map(\.item.id) {
      previousEntries = queue.entries.map(Optional.some)
    } else {
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
          sourceEntryID: previousEntry.sourceEntryID ?? entry.sourceEntryID,
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

  private static func preservingTemporarilyMissingEntryMetadata(
    in snapshot: PlaybackSnapshot,
    from missingEntries: [PlaybackQueueEntry],
  ) -> (snapshot: PlaybackSnapshot, remainingEntries: [PlaybackQueueEntry]) {
    var availableEntries = missingEntries
    var previousEntries = [PlaybackQueueEntry?](repeating: nil, count: snapshot.entries.count)

    for index in snapshot.entries.indices where snapshot.entries[index].hasNoQueueMetadata {
      let entry = snapshot.entries[index]
      guard let matchingIndex = availableEntries.firstIndex(where: {
        $0.id == entry.id && $0.item.id == entry.item.id
      }) else { continue }
      previousEntries[index] = availableEntries.remove(at: matchingIndex)
    }

    for index in snapshot.entries.indices
      where previousEntries[index] == nil && snapshot.entries[index].hasNoQueueMetadata {
      let entry = snapshot.entries[index]
      guard let matchingIndex = availableEntries.firstIndex(where: {
        $0.item.id == entry.item.id
      }) else { continue }
      previousEntries[index] = availableEntries.remove(at: matchingIndex)
    }

    return (
      PlaybackSnapshot(
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
            sourceEntryID: previousEntry.sourceEntryID ?? entry.sourceEntryID,
            viewID: previousEntry.viewID,
          )
        },
        currentEntryID: snapshot.currentEntryID,
        playStatus: snapshot.playStatus,
        progress: snapshot.progress,
      ),
      availableEntries,
    )
  }

  private static func temporarilyMissingUpcomingEntries(
    from queue: Queue?,
    in snapshot: PlaybackSnapshot,
  ) -> [PlaybackQueueEntry] {
    guard let queue,
          let receivedCurrentID = snapshot.currentEntryID,
          let receivedCurrentIndex = snapshot.entries.firstIndex(where: {
            $0.id == receivedCurrentID
          }) else { return [] }
    let receivedCurrentEntry = snapshot.entries[receivedCurrentIndex]
    let previousCurrentIndex = queue.entries.firstIndex(where: {
      $0.id == receivedCurrentEntry.id && $0.item.id == receivedCurrentEntry.item.id
    }) ?? queue.entries[queue.currentIndex...].firstIndex(where: {
      $0.item.id == receivedCurrentEntry.item.id
    })
    guard let previousCurrentIndex else { return [] }
    let previousUpcomingStart = queue.entries.index(after: previousCurrentIndex)
    let receivedUpcomingStart = snapshot.entries.index(after: receivedCurrentIndex)
    let previousUpcomingEntries = Array(queue.entries[previousUpcomingStart...])
    let receivedUpcomingEntries = Array(snapshot.entries[receivedUpcomingStart...])
    var availableReceivedIndices = Set(receivedUpcomingEntries.indices)
    var matchedPreviousIndices = Set<Int>()

    for index in previousUpcomingEntries.indices {
      let previousEntry = previousUpcomingEntries[index]
      guard let matchingIndex = receivedUpcomingEntries.indices.first(where: {
        guard availableReceivedIndices.contains($0) else { return false }
        let receivedEntry = receivedUpcomingEntries[$0]
        return receivedEntry.id == previousEntry.id
          && receivedEntry.item.id == previousEntry.item.id
      }) else { continue }
      availableReceivedIndices.remove(matchingIndex)
      matchedPreviousIndices.insert(index)
    }

    for index in previousUpcomingEntries.indices where !matchedPreviousIndices.contains(index) {
      let previousEntry = previousUpcomingEntries[index]
      guard let matchingIndex = receivedUpcomingEntries.indices.first(where: {
        availableReceivedIndices.contains($0)
          && receivedUpcomingEntries[$0].item.id == previousEntry.item.id
      }) else { continue }
      availableReceivedIndices.remove(matchingIndex)
      matchedPreviousIndices.insert(index)
    }

    return previousUpcomingEntries.indices.compactMap { index in
      guard !matchedPreviousIndices.contains(index) else { return nil }
      let entry = previousUpcomingEntries[index]
      return entry.role == .context ? entry : nil
    }
  }

  private func shuffled<Element: Sendable>(_ elements: [Element]) -> [Element] {
    self.withRandomNumberGenerator {
      elements.shuffled(using: &$0)
    }
  }

  private func makeInfinitePlaybackPlan(
    source: PlaybackSource,
    plannedEntries: [PlaybackSourceQueuePlanEntry],
    library: ApprovedMusicLibrary,
  ) -> InfinitePlaybackPlan? {
    guard let candidatePlan = InfinitePlaybackCandidatePlanner.plan(
      source: source,
      library: library,
    ) else { return nil }
    let randomizedPlan = InfinitePlaybackCandidatePlanner.randomizedInitialPlan(
      candidatePlan,
      shuffle: { $0 = self.shuffled($0) },
    )
    var sourceEntryIDs = Set<PlaybackSource.Entry.ID>()
    var sourceEntries = plannedEntries.compactMap { entry -> PlaybackSource.Entry? in
      guard case .source(let sourceEntry) = entry,
            sourceEntryIDs.insert(sourceEntry.id).inserted else { return nil }
      return sourceEntry
    }
    sourceEntries.append(contentsOf: candidatePlan.sourceEntries.filter {
      sourceEntryIDs.insert($0.id).inserted
    })
    guard !sourceEntries.isEmpty else { return nil }
    return InfinitePlaybackPlan(
      remainingSourceEntryIDs: sourceEntries.dropFirst().map(\.id),
      generatedItems: randomizedPlan.relatedItems + randomizedPlan.otherItems,
    )
  }

  private func makeInfinitePlaybackProjection(
    _ plan: InfinitePlaybackPlan,
    source: PlaybackSource,
    plannedEntries: [PlaybackSourceQueuePlanEntry],
    library: ApprovedMusicLibrary,
  ) -> InfinitePlaybackProjection? {
    guard let firstEntry = plannedEntries.first,
          case .source(let currentEntry) = firstEntry else { return nil }
    let sourceEntriesByID = Dictionary(
      uniqueKeysWithValues: source.entries.map { ($0.id, $0) },
    )
    let remainingSourceEntries = plan.remainingSourceEntryIDs.compactMap {
      sourceEntriesByID[$0]
    }
    guard remainingSourceEntries.count == plan.remainingSourceEntryIDs.count else {
      return nil
    }
    let generatedItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
      remainingSourceEntries: remainingSourceEntries,
      generatedItems: plan.generatedItems,
      library: library,
      previousTrackID: currentEntry.item.id,
      shuffle: { $0 = self.shuffled($0) },
    )
    let lookaheadEntries = InfinitePlaybackLookaheadPlanner.entries(
      remainingSourceEntries: remainingSourceEntries,
      generatedItems: generatedItems,
      approvedUniqueTrackCount: library.approvedTrackIDs.count,
    )
    let visibleSourceCount = lookaheadEntries.count {
      $0.sourceEntryID != nil
    }
    let visibleGeneratedCount = lookaheadEntries.count - visibleSourceCount
    let explicitEntries = plannedEntries.compactMap { entry -> PlaybackQueueEntry? in
      guard case .explicit(let explicitEntry) = entry else { return nil }
      return explicitEntry
    }
    let projectedLookaheadEntries = lookaheadEntries.map { entry in
      switch entry {
      case .generated(let item):
        PlaybackSourceQueuePlanEntry.generated(item)
      case .source(let sourceEntry):
        PlaybackSourceQueuePlanEntry.source(sourceEntry)
      }
    }
    return InfinitePlaybackProjection(
      entries: [.source(currentEntry)]
        + explicitEntries.map(PlaybackSourceQueuePlanEntry.explicit)
        + projectedLookaheadEntries,
      remainingPlan: InfinitePlaybackPlan(
        remainingSourceEntryIDs: Array(
          plan.remainingSourceEntryIDs.dropFirst(visibleSourceCount),
        ),
        generatedItems: Array(generatedItems.dropFirst(visibleGeneratedCount)),
      ),
    )
  }

  private func enableInfinitePlayback(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.hasAuthoritativeSnapshot,
          state.pendingInfiniteLookaheadInsertion == nil,
          state.pendingQueueReplacementViewIDs == nil,
          state.pendingUpcomingViewIDs == nil,
          let library = state.approvedLibrary,
          let source = state.playbackSource,
          let queue = state.session?.queue,
          let generatedItems = self.makeInitialInfiniteGeneratedItems(
            source: source,
            library: library,
          ) else { return nil }
    let sourceEntriesByID = Dictionary(
      uniqueKeysWithValues: source.entries.map { ($0.id, $0) },
    )
    let remainingSourceEntries = queue.contextEntries.compactMap { entry in
      entry.sourceEntryID.flatMap { sourceEntriesByID[$0] }
    }
    let preservedGeneratedItems = queue.contextEntries.compactMap { entry -> PlaybackItem? in
      guard entry.sourceEntryID == nil else { return nil }
      return entry.item.withQueueRole(nil)
    }
    guard let projection = self.makeInfiniteUpcomingProjection(
      sourceEntries: remainingSourceEntries,
      generatedItems: preservedGeneratedItems + generatedItems,
      queue: queue,
      library: library,
    ) else { return nil }
    state.infinitePlaybackPlan = projection.remainingPlan
    state.pendingInfiniteLookaheadInsertion = nil
    return self.updateUpcomingQueue(
      queue.queuedEntries + projection.entries,
      state: &state,
    )
  }

  private func disableInfinitePlayback(
    state: inout State,
  ) -> EffectOf<Self>? {
    state.pendingInfiniteLookaheadInsertion = nil
    state.temporarilyMissingUpcomingEntries.removeAll()
    guard state.hasAuthoritativeSnapshot,
          state.pendingQueueReplacementViewIDs == nil,
          state.pendingUpcomingViewIDs == nil,
          let queue = state.session?.queue else {
      state.infinitePlaybackPlan = nil
      return nil
    }
    let visibleSourceEntryIDs = queue.contextEntries.compactMap(\.sourceEntryID)
    let plannedSourceEntryIDs = state.infinitePlaybackPlan?.remainingSourceEntryIDs ?? []
    let source = state.playbackSource
    var retainedEntryIDs = Set<PlaybackSource.Entry.ID>()
    var remainingSourceEntryIDs = (visibleSourceEntryIDs + plannedSourceEntryIDs).filter {
      retainedEntryIDs.insert($0).inserted
        && source?.removedEntryIDs.contains($0) == false
    }
    if !state.preferences.isShuffleEnabled {
      let remainingEntryIDSet = Set(remainingSourceEntryIDs)
      remainingSourceEntryIDs = source?.entries.compactMap {
        remainingEntryIDSet.contains($0.id) ? $0.id : nil
      } ?? []
    }
    let sourceEntriesByID = Dictionary(
      uniqueKeysWithValues: source?.entries.map { ($0.id, $0) } ?? [],
    )
    let existingEntriesBySourceEntryID = Dictionary(
      uniqueKeysWithValues: queue.contextEntries.compactMap { entry in
        entry.sourceEntryID.map { ($0, entry) }
      },
    )
    let sourceEntries = remainingSourceEntryIDs.enumerated().compactMap {
      index, entryID -> PlaybackQueueEntry? in
      guard let sourceEntry = sourceEntriesByID[entryID] else { return nil }
      return existingEntriesBySourceEntryID[entryID]
        ?? self.pendingQueueEntry(
          for: .source(sourceEntry),
          index: index,
        )
    }
    state.infinitePlaybackPlan = nil
    return self.updateUpcomingQueue(
      queue.queuedEntries + sourceEntries,
      state: &state,
    )
  }

  private func updateInfiniteUpcomingQueueForShufflePreference(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.hasAuthoritativeSnapshot,
          state.pendingInfiniteLookaheadInsertion == nil,
          state.pendingQueueReplacementViewIDs == nil,
          state.pendingUpcomingViewIDs == nil,
          let library = state.approvedLibrary,
          let source = state.playbackSource,
          let plan = state.infinitePlaybackPlan,
          let queue = state.session?.queue else { return nil }
    let sourceEntryIDs = queue.contextEntries.compactMap(\.sourceEntryID)
      + plan.remainingSourceEntryIDs
    let sourceEntriesByID = Dictionary(
      uniqueKeysWithValues: source.entries.map { ($0.id, $0) },
    )
    var sourceEntries = sourceEntryIDs.compactMap { sourceEntriesByID[$0] }
    if state.preferences.isShuffleEnabled {
      sourceEntries = self.shuffled(sourceEntries)
    } else {
      let sourceEntryIDSet = Set(sourceEntries.map(\.id))
      sourceEntries = source.entries.filter {
        sourceEntryIDSet.contains($0.id) && !source.removedEntryIDs.contains($0.id)
      }
    }
    let visibleGeneratedItems = queue.contextEntries.compactMap { entry -> PlaybackItem? in
      guard entry.sourceEntryID == nil else { return nil }
      return entry.item.withQueueRole(nil)
    }
    guard let projection = self.makeInfiniteUpcomingProjection(
      sourceEntries: sourceEntries,
      generatedItems: visibleGeneratedItems + plan.generatedItems,
      queue: queue,
      library: library,
    ) else { return nil }
    state.infinitePlaybackPlan = projection.remainingPlan
    return self.updateUpcomingQueue(
      queue.queuedEntries + projection.entries,
      state: &state,
    )
  }

  private func makeInitialInfiniteGeneratedItems(
    source: PlaybackSource,
    library: ApprovedMusicLibrary,
  ) -> [PlaybackItem]? {
    guard let candidatePlan = InfinitePlaybackCandidatePlanner.plan(
      source: source,
      library: library,
    ) else { return nil }
    let randomizedPlan = InfinitePlaybackCandidatePlanner.randomizedInitialPlan(
      candidatePlan,
      shuffle: { $0 = self.shuffled($0) },
    )
    return randomizedPlan.relatedItems + randomizedPlan.otherItems
  }

  private func makeInfiniteUpcomingProjection(
    sourceEntries: [PlaybackSource.Entry],
    generatedItems: [PlaybackItem],
    queue: Queue,
    library: ApprovedMusicLibrary,
  ) -> InfiniteUpcomingProjection? {
    let generatedItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
      remainingSourceEntries: sourceEntries,
      generatedItems: generatedItems,
      library: library,
      previousTrackID: queue.currentItem.id,
      shuffle: { $0 = self.shuffled($0) },
    )
    let lookaheadEntries = InfinitePlaybackLookaheadPlanner.entries(
      remainingSourceEntries: sourceEntries,
      generatedItems: generatedItems,
      approvedUniqueTrackCount: library.approvedTrackIDs.count,
    )
    let visibleSourceCount = lookaheadEntries.count { $0.sourceEntryID != nil }
    let visibleGeneratedCount = lookaheadEntries.count - visibleSourceCount
    let existingSourceEntries = Dictionary(
      uniqueKeysWithValues: queue.contextEntries.compactMap { entry in
        entry.sourceEntryID.map { ($0, entry) }
      },
    )
    var existingGeneratedEntries = queue.contextEntries.filter {
      $0.sourceEntryID == nil
    }
    let entries = lookaheadEntries.enumerated().map { index, entry in
      switch entry {
      case .source(let sourceEntry):
        return existingSourceEntries[sourceEntry.id]
          ?? self.pendingQueueEntry(for: .source(sourceEntry), index: index)
      case .generated(let item):
        if let existingIndex = existingGeneratedEntries.firstIndex(where: {
          $0.item.id == item.id
        }) {
          return existingGeneratedEntries.remove(at: existingIndex)
        }
        return self.pendingQueueEntry(for: .generated(item), index: index)
      }
    }
    return InfiniteUpcomingProjection(
      entries: entries,
      remainingPlan: InfinitePlaybackPlan(
        remainingSourceEntryIDs: Array(sourceEntries.dropFirst(visibleSourceCount).map(\.id)),
        generatedItems: Array(generatedItems.dropFirst(visibleGeneratedCount)),
      ),
    )
  }

  private func pendingQueueEntry(
    for entry: PlaybackSourceQueuePlanEntry,
    index: Int,
  ) -> PlaybackQueueEntry {
    PlaybackQueueEntry(
      id: "pending:infinite:\(index):\(entry.item.id.rawValue)",
      item: entry.item,
      sourceEntryID: entry.sourceEntryID,
    )
  }

  private func updateApprovedTrackIDs(
    _ approvedTrackIDs: Set<ApprovedTrack.ID>,
    state: inout State,
  ) -> EffectOf<Self> {
    let previousApprovedTrackIDs = state.approvedTrackIDs
    let previousPlaybackSource = state.playbackSource
    state.approvedTrackIDs = approvedTrackIDs
    state.playbackSource?.removeTracks(notIn: approvedTrackIDs)
    self.reconcileInfinitePlaybackPlan(
      approvedTrackIDs: approvedTrackIDs,
      newlyApprovedTrackIDs: previousApprovedTrackIDs.map {
        approvedTrackIDs.subtracting($0)
      } ?? [],
      state: &state,
    )
    if let reconciliation = self.reconcileApprovedQueue(state: &state) {
      return reconciliation
    }
    self.prepareRepeatCollectionCycleIfNeeded(state: &state)
    guard state.playbackSource != previousPlaybackSource else { return .none }
    return self.saveCheckpoint(state)
  }

  private func reconcileInfinitePlaybackPlan(
    approvedTrackIDs: Set<ApprovedTrack.ID>,
    newlyApprovedTrackIDs: Set<ApprovedTrack.ID>,
    state: inout State,
  ) {
    guard state.preferences.endBehavior == .infinite,
          let library = state.approvedLibrary else { return }
    let retainedSourceEntryIDs = Set(state.playbackSource?.entries.compactMap { entry in
      state.playbackSource?.removedEntryIDs.contains(entry.id) == false ? entry.id : nil
    } ?? [])
    let visibleTrackIDs = Set(state.session?.queue.entries.map(\.item.id) ?? [])
    let newItems = InfinitePlaybackCandidatePlanner.uniqueApprovedItems(in: library).filter {
      newlyApprovedTrackIDs.contains($0.id) && !visibleTrackIDs.contains($0.id)
    }
    let shuffledNewItems = if newItems.count > 1 {
      self.shuffled(newItems)
    } else {
      newItems
    }
    if var plan = state.infinitePlaybackPlan {
      plan.remainingSourceEntryIDs.removeAll {
        !retainedSourceEntryIDs.contains($0)
      }
      plan.generatedItems.removeAll {
        !approvedTrackIDs.contains($0.id)
      }
      let plannedTrackIDs = Set(plan.generatedItems.map(\.id))
      plan.generatedItems.append(contentsOf: shuffledNewItems.filter {
        !plannedTrackIDs.contains($0.id)
      })
      state.infinitePlaybackPlan = plan
    }
    if let insertion = state.pendingInfiniteLookaheadInsertion {
      var remainingPlan = insertion.remainingPlan
      remainingPlan.remainingSourceEntryIDs.removeAll {
        !retainedSourceEntryIDs.contains($0)
      }
      remainingPlan.generatedItems.removeAll {
        !approvedTrackIDs.contains($0.id)
      }
      let plannedTrackIDs = Set(remainingPlan.generatedItems.map(\.id))
      remainingPlan.generatedItems.append(contentsOf: shuffledNewItems.filter {
        !plannedTrackIDs.contains($0.id)
      })
      state.pendingInfiniteLookaheadInsertion = InfiniteLookaheadInsertion(
        entries: insertion.entries,
        remainingPlan: remainingPlan,
      )
    }
  }

  private static func preservingPlannedItemMetadata(
    in snapshot: PlaybackSnapshot,
    plan: [PlaybackMetadataHintMatcher.Occurrence],
  ) -> PlaybackSnapshot {
    let albumIDHints = PlaybackMetadataHintMatcher.match(
      plan: plan,
      entries: snapshot.entries,
      value: { $0.albumID },
    )
    let artworkURLHints = PlaybackMetadataHintMatcher.match(
      plan: plan,
      entries: snapshot.entries,
      value: { $0.artworkURL },
    )
    guard !albumIDHints.isEmpty || !artworkURLHints.isEmpty else { return snapshot }
    return PlaybackSnapshot(
      entries: snapshot.entries.map { entry in
        PlaybackQueueEntry(
          id: entry.id,
          item: entry.item
            .withAlbumID(albumIDHints[entry.id] ?? entry.item.albumID)
            .withArtworkURL(artworkURLHints[entry.id] ?? entry.item.artworkURL),
          sourceEntryID: entry.sourceEntryID,
          viewID: entry.viewID,
        )
      },
      currentEntryID: snapshot.currentEntryID,
      playStatus: snapshot.playStatus,
      progress: snapshot.progress,
    )
  }

  private static func restoringWebArtwork(
    in snapshot: PlaybackSnapshot,
    library: ApprovedMusicLibrary?,
    sourceAlbumIDs: [ApprovedTrack.ID: ApprovedAlbum.ID],
  ) -> PlaybackSnapshot {
    guard let library else { return snapshot }
    return PlaybackSnapshot(
      entries: snapshot.entries.map { entry in
        PlaybackQueueEntry(
          id: entry.id,
          item: entry.item.withArtworkURL(library.playbackArtworkURL(
            for: entry.item,
            sourceAlbumID: entry.item.albumID ?? sourceAlbumIDs[entry.item.id],
          )),
          sourceEntryID: entry.sourceEntryID,
          viewID: entry.viewID,
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
    let metadataPlan = state.pendingMetadataPlan ?? []
    let previousQueue = state.session?.queue
    let entryMetadataSnapshot = Self.preservingEntryMetadata(
      in: receivedSnapshot,
      from: previousQueue,
    )
    let missingMetadataRestoration = Self.preservingTemporarilyMissingEntryMetadata(
      in: entryMetadataSnapshot,
      from: state.temporarilyMissingUpcomingEntries,
    )
    let plannedMetadataSnapshot = Self.preservingPlannedItemMetadata(
      in: missingMetadataRestoration.snapshot,
      plan: metadataPlan,
    )
    let snapshot = Self.restoringWebArtwork(
      in: plannedMetadataSnapshot,
      library: state.approvedLibrary,
      sourceAlbumIDs: state.sourceAlbumIDs,
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
         !Self.matchesExpectedUpcomingEntries(
           receivedQueue.upcomingEntries,
           expectedEntries: state.session?.queue.upcomingEntries ?? [],
           expectedViewIDs: expectedViewIDs,
         ) {
        return .none
      }
      state.pendingUpcomingViewIDs = nil
      state.shouldClearPlaybackOnUpcomingUpdateFailure = false
    }
    state.temporarilyMissingUpcomingEntries = missingMetadataRestoration.remainingEntries
    if state.preferences.endBehavior == .infinite {
      for entry in Self.temporarilyMissingUpcomingEntries(
        from: previousQueue,
        in: receivedSnapshot,
      ) where !state.temporarilyMissingUpcomingEntries.contains(where: {
        $0.viewID == entry.viewID
      }) {
        state.temporarilyMissingUpcomingEntries.append(entry)
      }
    }
    state.recordMetadata(entries: snapshot.entries)
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
    state.sourceEntryIDHints = PlaybackMetadataHintMatcher.matchSourceEntries(
      plan: metadataPlan,
      entries: snapshot.entries,
      existing: state.sourceEntryIDHints,
    )
    if PlaybackMetadataHintMatcher.hasMaterializedAllRequiredMetadata(
      plan: metadataPlan,
      entries: snapshot.entries,
    ) {
      state.pendingMetadataPlan = nil
    }
    guard var session = Session(
      snapshot: snapshot,
      sourceAlbumIDs: state.sourceAlbumIDs,
      playlistSourceHints: state.playlistSourceHints,
      queueRoleHints: state.queueRoleHints,
      sourceEntryIDHints: state.sourceEntryIDHints,
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
    self.prepareRepeatCollectionCycleIfNeeded(state: &state)
    let infiniteLookaheadInsertion = state.preferences.endBehavior == .infinite
      && state.infinitePlaybackPlan == nil
      ? self.enableInfinitePlayback(state: &state)
      : self.insertInfiniteLookaheadIfNeeded(state: &state)
    let shouldCacheImmediately = previousSession?.queue != session.queue
      || previousSession?.playStatus != session.playStatus
    if shouldCacheImmediately {
      state.lastCachedProgressBucket = Int(state.progress.elapsedTime / 5)
      return .merge(
        self.saveCheckpoint(state),
        infiniteLookaheadInsertion ?? .none,
      )
    }
    if let infiniteLookaheadInsertion {
      return infiniteLookaheadInsertion
    }
    guard state.shouldCacheProgressSnapshot() else { return .none }
    return self.saveCheckpoint(state)
  }

  private func insertInfiniteLookaheadIfNeeded(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.preferences.endBehavior == .infinite,
          state.hasAuthoritativeSnapshot,
          state.pendingInfiniteLookaheadInsertion == nil,
          state.pendingMetadataPlan == nil,
          state.pendingQueueReplacementViewIDs == nil,
          state.pendingUpcomingViewIDs == nil,
          !state.shouldClearPlaybackOnUpcomingUpdateFailure,
          let library = state.approvedLibrary,
          var plan = state.infinitePlaybackPlan,
          let queue = state.session?.queue else { return nil }
    let targetCount = min(10, library.approvedTrackIDs.count)
    let visibleCount = queue.upcomingEntries.count {
      $0.role == .context
    }
    let insertionCount = targetCount - visibleCount
    guard insertionCount > 0 else { return nil }
    let sourceEntriesByID = Dictionary(
      uniqueKeysWithValues: state.playbackSource?.entries.map { ($0.id, $0) } ?? [],
    )
    let remainingSourceEntries = plan.remainingSourceEntryIDs.compactMap {
      sourceEntriesByID[$0]
    }
    guard remainingSourceEntries.count == plan.remainingSourceEntryIDs.count else {
      return nil
    }
    if remainingSourceEntries.count + plan.generatedItems.count < insertionCount {
      let visibleContextEntries = queue.upcomingEntries.filter { $0.role == .context }
      plan.generatedItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
        remainingSourceEntries: remainingSourceEntries,
        generatedItems: plan.generatedItems,
        library: library,
        previousTrackID: visibleContextEntries.last?.item.id ?? queue.currentItem.id,
        additionalVisibleTrackIDs: Set(visibleContextEntries.map(\.item.id)),
        shuffle: { $0 = self.shuffled($0) },
      )
    }
    let lookaheadEntries = InfinitePlaybackLookaheadPlanner.entries(
      remainingSourceEntries: remainingSourceEntries,
      generatedItems: plan.generatedItems,
      approvedUniqueTrackCount: library.approvedTrackIDs.count,
    )
    let insertedLookaheadEntries = lookaheadEntries.prefix(insertionCount)
    guard !insertedLookaheadEntries.isEmpty else { return nil }
    let insertedSourceCount = insertedLookaheadEntries.count {
      $0.sourceEntryID != nil
    }
    let insertedGeneratedCount = insertedLookaheadEntries.count - insertedSourceCount
    let insertedEntries = insertedLookaheadEntries.map { entry in
      switch entry {
      case .generated(let item):
        PlaybackSourceQueuePlanEntry.generated(item)
      case .source(let sourceEntry):
        PlaybackSourceQueuePlanEntry.source(sourceEntry)
      }
    }
    let insertion = InfiniteLookaheadInsertion(
      entries: insertedEntries,
      remainingPlan: InfinitePlaybackPlan(
        remainingSourceEntryIDs: Array(
          plan.remainingSourceEntryIDs.dropFirst(insertedSourceCount),
        ),
        generatedItems: Array(plan.generatedItems.dropFirst(insertedGeneratedCount)),
      ),
    )
    state.pendingInfiniteLookaheadInsertion = insertion
    state.prepareMetadataPlan(
      prefixEntries: queue.entries,
      appendedEntries: insertedEntries,
    )
    let items = insertedEntries.map(\.item)
    return .run { send in
      do {
        let snapshot = try await self.playback.insertIntoQueue(items, .tail)
        try Task.checkCancellation()
        await send(.infiniteLookaheadInsertionFinished(snapshot))
      } catch is CancellationError {
        return
      } catch {
        await send(.playbackFailed(.init(error: error)))
      }
    }
    .cancellable(id: CancelID.playbackStart, cancelInFlight: true)
  }

  private static func matchesExpectedUpcomingEntries(
    _ receivedEntries: [PlaybackQueueEntry],
    expectedEntries: [PlaybackQueueEntry],
    expectedViewIDs: [String],
  ) -> Bool {
    guard receivedEntries.count == expectedEntries.count,
          expectedEntries.map(\.viewID) == expectedViewIDs else { return false }
    return zip(receivedEntries, expectedEntries).allSatisfy { received, expected in
      expected.viewID.hasPrefix("pending:")
        ? received.item.id == expected.item.id
        : received.viewID == expected.viewID
    }
  }

  private func reconcileApprovedQueue(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.hasAuthoritativeSnapshot,
          !state.isRestoringCheckpoint,
          state.pendingInfiniteLookaheadInsertion == nil,
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
    state.pendingAlbumResolutionViewID = nil
    state.pendingMetadataPlan = nil
    state.pendingPlayNowItems = nil
    state.pendingQueueReplacementViewIDs = expectedViewIDs
    state.pendingRepeatCycleEntryIDs = nil
    state.pendingUpcomingViewIDs = nil
    state.playlistSourceHints = state.playlistSourceHints.filter {
      retainedEntryIDs.contains($0.key)
    }
    state.progress = .zero
    state.queueRoleHints = state.queueRoleHints.filter {
      retainedEntryIDs.contains($0.key)
    }
    state.sourceEntryIDHints = state.sourceEntryIDHints.filter {
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

  private func updateUpcomingQueueForShufflePreference(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.hasAuthoritativeSnapshot,
          !state.isRestoringCheckpoint,
          state.pendingQueueReplacementViewIDs == nil,
          !state.shouldClearPlaybackOnUpcomingUpdateFailure,
          let source = state.playbackSource,
          source.isValid,
          let queue = state.session?.queue else { return nil }
    let contextEntries = queue.contextEntries
    let remainingSourceEntryIDs = contextEntries.compactMap(\.sourceEntryID)
    let sourceEntryIDs = Set(source.entries.map(\.id))
    guard !contextEntries.isEmpty,
          remainingSourceEntryIDs.count == contextEntries.count,
          Set(remainingSourceEntryIDs).count == remainingSourceEntryIDs.count,
          Set(remainingSourceEntryIDs).isSubset(of: sourceEntryIDs) else { return nil }
    let contextEntriesBySourceEntryID = Dictionary(
      uniqueKeysWithValues: zip(remainingSourceEntryIDs, contextEntries),
    )
    let plannedEntries = PlaybackSourceQueuePlanner.upcomingEntries(
      source: source,
      remainingSourceEntryIDs: remainingSourceEntryIDs,
      explicitEntries: queue.queuedEntries,
      isShuffleEnabled: state.preferences.isShuffleEnabled,
      shuffle: { $0 = self.shuffled($0) },
    )
    let upcomingEntries = plannedEntries.compactMap { entry in
      switch entry {
      case .explicit(let entry):
        entry
      case .generated:
        nil
      case .source(let entry):
        contextEntriesBySourceEntryID[entry.id]
      }
    }
    guard upcomingEntries.count == plannedEntries.count else { return nil }
    return self.updateUpcomingQueue(upcomingEntries, state: &state)
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
    state.pendingRepeatCycleEntryIDs = nil
    state.recordMetadata(entries: entries)
    state.session?.queue.entries = entries
    if !entries.contains(where: { $0.role == .context }) {
      state.playbackContext = nil
    }
    if !physicalOrderChanged {
      self.prepareRepeatCollectionCycleIfNeeded(state: &state)
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
    guard state.pendingInfiniteLookaheadInsertion == nil,
          state.pendingQueueReplacementViewIDs == nil,
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
    state.pendingRepeatCycleEntryIDs = nil
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

  private func prepareRepeatCollectionCycleIfNeeded(
    state: inout State,
  ) {
    guard state.preferences.endBehavior == .loopCollection,
          state.hasAuthoritativeSnapshot,
          !state.isRestoringCheckpoint,
          state.pendingMetadataPlan == nil,
          state.pendingPlayNowItems == nil,
          state.pendingQueueReplacementViewIDs == nil,
          state.pendingUpcomingViewIDs == nil,
          !state.shouldClearPlaybackOnUpcomingUpdateFailure,
          let source = state.playbackSource,
          source.isValid,
          let queue = state.session?.queue,
          queue.upcomingEntries.isEmpty else {
      state.pendingRepeatCycleEntryIDs = nil
      return
    }
    if let entryIDs = state.pendingRepeatCycleEntryIDs,
       PlaybackSourceQueuePlanner.sourceCycleEntries(
         source: source,
         entryIDs: entryIDs,
       ) != nil {
      return
    }
    state.pendingRepeatCycleEntryIDs = self.makeRepeatCollectionCycleEntries(
      source: source,
      queue: queue,
      isShuffleEnabled: state.preferences.isShuffleEnabled,
    )?.map(\.id)
  }

  private func makeRepeatCollectionCycleEntries(
    source: PlaybackSource,
    queue: Queue,
    isShuffleEnabled: Bool,
  ) -> [PlaybackSource.Entry]? {
    let previousTrackID = queue.entries[...queue.currentIndex].reversed().first(where: {
      $0.sourceEntryID != nil
    })?.item.id
    return PlaybackSourceQueuePlanner.sourceCycleEntries(
      source: source,
      isShuffleEnabled: isShuffleEnabled,
      avoidingFirstTrackID: previousTrackID,
      shuffle: { $0 = self.shuffled($0) },
    )
  }

  private func restartInfinitePlayback(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.preferences.endBehavior == .infinite,
          state.hasAuthoritativeSnapshot,
          state.pendingInfiniteLookaheadInsertion == nil,
          state.pendingQueueReplacementViewIDs == nil,
          state.pendingUpcomingViewIDs == nil,
          let library = state.approvedLibrary,
          let previousItem = state.session?.currentItem else { return nil }
    var cycleItems = InfinitePlaybackCandidatePlanner.libraryCycleItems(
      library: library,
      avoidingFirstTrackID: previousItem.id,
      shuffle: { $0 = self.shuffled($0) },
    )
    guard let currentItem = cycleItems.first else { return nil }
    cycleItems.removeFirst()
    cycleItems = InfinitePlaybackLookaheadPlanner.replenishedGeneratedItems(
      remainingSourceEntries: [],
      generatedItems: cycleItems,
      library: library,
      previousTrackID: currentItem.id,
      shuffle: { $0 = self.shuffled($0) },
    )
    let lookaheadItems = InfinitePlaybackLookaheadPlanner.entries(
      remainingSourceEntries: [],
      generatedItems: cycleItems,
      approvedUniqueTrackCount: library.approvedTrackIDs.count,
    ).map(\.item)
    let items = [currentItem.withQueueRole(.context)] + lookaheadItems
    let plannedEntries = items.map { item in
      PlaybackSourceQueuePlanEntry.generated(item.withQueueRole(nil))
    }
    state.prepareMetadataPlan(plannedEntries: plannedEntries)
    state.failure = nil
    state.hasAuthoritativeSnapshot = false
    state.infinitePlaybackPlan = InfinitePlaybackPlan(
      remainingSourceEntryIDs: [],
      generatedItems: Array(cycleItems.dropFirst(lookaheadItems.count)),
    )
    state.lastCachedProgressBucket = nil
    state.pendingAlbumResolutionViewID = nil
    state.pendingInfiniteLookaheadInsertion = nil
    state.pendingPlayNowItems = items
    state.pendingQueueReplacementViewIDs = nil
    state.pendingRepeatCycleEntryIDs = nil
    state.pendingUpcomingViewIDs = nil
    state.progress = .zero
    state.shouldClearPlaybackOnUpcomingUpdateFailure = false
    state.recordSourceAlbums(items)
    state.sourceEntryIDHints.removeAll()
    state.session = .init(
      playStatus: .loading,
      queue: .init(plannedEntries: plannedEntries),
    )
    let restart: EffectOf<Self> = .run { send in
      do {
        let snapshot = try await self.playback.playNow(items, 0)
        try Task.checkCancellation()
        await send(.playNowFinished(snapshot))
      } catch is CancellationError {
        return
      } catch {
        await send(.playbackFailed(.init(error: error)))
      }
    }
    .cancellable(id: CancelID.playbackStart, cancelInFlight: true)
    return .merge(
      .cancel(id: CancelID.checkpointSave),
      .cancel(id: CancelID.seek),
      restart,
    )
  }

  private func restartLoopCollection(
    state: inout State,
  ) -> EffectOf<Self>? {
    guard state.preferences.endBehavior == .loopCollection,
          state.hasAuthoritativeSnapshot,
          !state.isRestoringCheckpoint,
          state.pendingPlayNowItems == nil,
          state.pendingQueueReplacementViewIDs == nil,
          state.pendingUpcomingViewIDs == nil,
          !state.shouldClearPlaybackOnUpcomingUpdateFailure,
          let source = state.playbackSource,
          let queue = state.session?.queue else { return nil }
    let cycleEntries: [PlaybackSource.Entry]
    if let entryIDs = state.pendingRepeatCycleEntryIDs,
       let preparedEntries = PlaybackSourceQueuePlanner.sourceCycleEntries(
         source: source,
         entryIDs: entryIDs,
       ) {
      cycleEntries = preparedEntries
    } else {
      guard let generatedEntries = self.makeRepeatCollectionCycleEntries(
        source: source,
        queue: queue,
        isShuffleEnabled: state.preferences.isShuffleEnabled,
      ) else { return nil }
      cycleEntries = generatedEntries
    }
    let plannedEntries = cycleEntries.map(PlaybackSourceQueuePlanEntry.source)
    let items = plannedEntries.map(\.item)
    state.prepareMetadataPlan(plannedEntries: plannedEntries)
    state.failure = nil
    state.hasAuthoritativeSnapshot = false
    state.isRestoringCheckpoint = false
    state.lastCachedProgressBucket = nil
    state.pendingAlbumResolutionViewID = nil
    state.pendingPlayNowItems = items
    state.pendingQueueReplacementViewIDs = nil
    state.pendingRepeatCycleEntryIDs = nil
    state.pendingUpcomingViewIDs = nil
    state.playbackContext = source.context
    state.progress = .zero
    state.shouldClearPlaybackOnUpcomingUpdateFailure = false
    state.recordSourceAlbums(items)
    state.sourceEntryIDHints.removeAll()
    state.session = .init(
      playStatus: .loading,
      queue: .init(
        items: items,
        sourceEntryIDs: plannedEntries.map(\.sourceEntryID),
      ),
    )
    let restart: EffectOf<Self> = .run { send in
      do {
        let snapshot = try await self.playback.playNow(items, 0)
        try Task.checkCancellation()
        await send(.playNowFinished(snapshot))
      } catch is CancellationError {
        return
      } catch {
        await send(.playbackFailed(.init(error: error)))
      }
    }
    .cancellable(id: CancelID.playbackStart, cancelInFlight: true)
    return .merge(
      .cancel(id: CancelID.checkpointSave),
      .cancel(id: CancelID.seek),
      restart,
    )
  }

  private func saveCheckpoint(_ state: State) -> EffectOf<Self> {
    guard state.hasAuthoritativeSnapshot,
          !state.isRestoringCheckpoint,
          let session = state.session else { return .none }
    let checkpoint = PlaybackCheckpoint(
      session: session,
      infinitePlaybackPlan: state.preferences.endBehavior == .infinite
        ? state.infinitePlaybackPlan
        : nil,
      playbackSource: state.playbackSource,
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

  private func synchronizePlaybackRepeatMode(
    _ endBehavior: PlaybackEndBehavior,
  ) -> EffectOf<Self> {
    .run { _ in
      guard !Task.isCancelled else { return }
      await self.playback.setRepeatsCurrentEntry(endBehavior == .loopTrack)
    }
    .cancellable(id: CancelID.playbackRepeatModeUpdate, cancelInFlight: true)
  }

  private func savePreferences(_ preferences: PlaybackPreferences) -> EffectOf<Self> {
    .run { _ in
      guard !Task.isCancelled else { return }
      await self.playbackPreferences.save(preferences)
    }
    .cancellable(id: CancelID.playbackPreferencesSave, cancelInFlight: true)
  }
}

extension PlaybackFeature.State {
  var activePlaybackContext: PlaybackContext? {
    guard let currentEntry = self.session?.queue.currentEntry,
          currentEntry.role == .context else { return nil }
    let isInfiniteGeneratedEntry = self.preferences.endBehavior == .infinite
      && currentEntry.sourceEntryID == nil
    return isInfiniteGeneratedEntry ? nil : self.playbackContext
  }

  var queueContextTitle: String? {
    guard self.preferences.endBehavior == .infinite,
          let contextEntries = self.session?.queue.contextEntries,
          !contextEntries.isEmpty,
          contextEntries.allSatisfy({ $0.sourceEntryID == nil }) else {
      return self.playbackContext?.title
    }
    return "Infinite Play"
  }

  var repeatCollectionWrapEntry: PlaybackSource.Entry? {
    guard self.preferences.endBehavior == .loopCollection,
          self.hasAuthoritativeSnapshot,
          !self.isRestoringCheckpoint,
          self.pendingMetadataPlan == nil,
          self.pendingPlayNowItems == nil,
          self.pendingQueueReplacementViewIDs == nil,
          self.pendingUpcomingViewIDs == nil,
          !self.shouldClearPlaybackOnUpcomingUpdateFailure,
          self.session?.queue.upcomingEntries.isEmpty == true,
          let source = self.playbackSource,
          source.isValid else { return nil }
    let entryID: PlaybackSource.Entry.ID? = if let preparedEntryID =
      self.pendingRepeatCycleEntryIDs?.first {
      preparedEntryID
    } else if self.preferences.isShuffleEnabled {
      nil
    } else {
      source.entries.first(where: {
        !source.removedEntryIDs.contains($0.id)
      })?.id
    }
    return source.entries.first {
      $0.id == entryID && !source.removedEntryIDs.contains($0.id)
    }
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
      self.playlistSourceHints[entry.id] = entry.item.playlistSource
      self.queueRoleHints[entry.id] = entry.item.queueRole
      self.sourceEntryIDHints[entry.id] = entry.sourceEntryID
    }
  }

  mutating func restoreWebArtwork(using library: ApprovedMusicLibrary) {
    guard var session = self.session else { return }
    session.queue.entries = session.queue.entries.map { entry in
      PlaybackQueueEntry(
        id: entry.id,
        item: entry.item.withArtworkURL(library.playbackArtworkURL(
          for: entry.item,
          sourceAlbumID: entry.item.albumID ?? self.sourceAlbumIDs[entry.item.id],
        )),
        sourceEntryID: entry.sourceEntryID,
        viewID: entry.viewID,
      )
    }
    self.session = session
  }

  mutating func prepareMetadataPlan(checkpoint: PlaybackCheckpoint) {
    let plan = checkpoint.songIDs.indices.map { index in
      PlaybackMetadataHintMatcher.Occurrence(
        item: PlaybackItem(
          id: checkpoint.songIDs[index],
          title: "",
          artistName: "",
          artworkURL: nil,
          albumID: checkpoint.albumID(at: index),
          playlistSource: checkpoint.playlistSourceHints[index],
          queueRole: checkpoint.queueRoles?[index],
        ),
        sourceEntryID: checkpoint.sourceEntryIDs?[index],
      )
    }
    self.setPendingMetadataPlan(plan)
  }

  mutating func prepareMetadataPlan(
    plannedEntries: [PlaybackSourceQueuePlanEntry],
  ) {
    self.setPendingMetadataPlan(
      plannedEntries.map(Self.metadataOccurrence),
    )
  }

  mutating func prepareMetadataPlan(
    prefixEntries: [PlaybackQueueEntry],
    appendedEntries: [PlaybackSourceQueuePlanEntry],
  ) {
    self.recordMetadata(entries: prefixEntries)
    let prefixPlan = prefixEntries.map {
      PlaybackMetadataHintMatcher.Occurrence(
        item: $0.item,
        retainedEntryID: $0.id,
        sourceEntryID: $0.sourceEntryID,
      )
    }
    self.setPendingMetadataPlan(
      prefixPlan + appendedEntries.map(Self.metadataOccurrence),
    )
  }

  private static func metadataOccurrence(
    for entry: PlaybackSourceQueuePlanEntry,
  ) -> PlaybackMetadataHintMatcher.Occurrence {
    switch entry {
    case .explicit(let entry):
      PlaybackMetadataHintMatcher.Occurrence(
        item: entry.item,
        retainedEntryID: entry.id,
      )
    case .generated(let item):
      PlaybackMetadataHintMatcher.Occurrence(
        item: item.withQueueRole(.context),
      )
    case .source(let entry):
      PlaybackMetadataHintMatcher.Occurrence(
        item: entry.item.withQueueRole(.context),
        sourceEntryID: entry.id,
      )
    }
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
        sourceEntryID: $0.sourceEntryID,
      )
    } + newItems.map {
      PlaybackMetadataHintMatcher.Occurrence(item: $0)
    } + suffixEntries.map {
      PlaybackMetadataHintMatcher.Occurrence(
        item: $0.item,
        retainedEntryID: $0.id,
        sourceEntryID: $0.sourceEntryID,
      )
    }
    self.setPendingMetadataPlan(plan)
  }

  private mutating func setPendingMetadataPlan(
    _ plan: [PlaybackMetadataHintMatcher.Occurrence],
  ) {
    self.pendingMetadataPlan = self.playlistSourceHints.isEmpty
      && self.queueRoleHints.isEmpty
      && self.sourceEntryIDHints.isEmpty
      && plan.allSatisfy {
        $0.item.albumID == nil
          && $0.item.artworkURL == nil
          && $0.item.playlistSource == nil
          && $0.item.queueRole == nil
          && $0.sourceEntryID == nil
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
    guard let entry = self.session?.queue.currentEntry else { return false }
    if let albumID = entry.item.albumID,
       library.album(id: albumID) != nil {
      return true
    }
    if let albumID = self.sourceAlbumIDs[entry.item.id],
       library.album(id: albumID) != nil {
      self.setCurrentAlbumID(albumID, for: entry.viewID)
      return true
    }
    self.sourceAlbumIDs[entry.item.id] = nil
    guard let album = library.album(matching: entry.item) else {
      if entry.item.albumID != nil {
        self.setCurrentAlbumID(nil, for: entry.viewID)
      }
      return false
    }
    if entry.item.albumID != album.id {
      self.setCurrentAlbumID(album.id, for: entry.viewID)
    }
    return true
  }

  mutating func setCurrentAlbumID(
    _ albumID: ApprovedAlbum.ID?,
    for entryViewID: PlaybackQueueEntry.ID,
  ) {
    guard var session = self.session,
          session.queue.currentEntry.viewID == entryViewID else { return }
    let index = session.queue.currentIndex
    let entry = session.queue.entries[index]
    self.sourceAlbumIDs[entry.item.id] = albumID
    session.queue.entries[index] = PlaybackQueueEntry(
      id: entry.id,
      item: entry.item.withAlbumID(albumID),
      sourceEntryID: entry.sourceEntryID,
      viewID: entry.viewID,
    )
    self.session = session
    if self.pendingAlbumResolutionViewID == entryViewID, albumID != nil {
      self.pendingAlbumResolutionViewID = nil
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

private extension PlaybackQueueEntry {
  var hasNoQueueMetadata: Bool {
    self.item.playlistSource == nil
      && self.item.queueRole == nil
      && self.sourceEntryID == nil
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
