import ComposableArchitecture
import CustomDump
import Foundation
import Testing

@testable import LibTCA

@MainActor
struct PlaybackFeatureTests {
  @Test
  func startsWithoutSession() {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    #expect(store.state.session == nil)
  }

  @Test
  func playNowStartsRequestedSuffixWithoutSession() async {
    let items = [
      playbackItem("track-1"),
      playbackItem("track-2"),
      playbackItem("track-3"),
    ]
    let requestedItems = Array(items.dropFirst())
    let snapshot = playbackSnapshot(items: requestedItems)
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playNow(items: items, startIndex: 1)) {
      $0.pendingPlayNowItems = requestedItems
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: requestedItems),
      )
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlayNowItems = nil
      $0.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    }
  }

  @Test
  func playNowPrependsRequestedSuffixToExistingUpcoming() async {
    let existingItems = [
      playbackItem("current"),
      playbackItem("old-next-1"),
      playbackItem("old-next-2"),
    ]
    let requestedItems = [
      playbackItem("requested-1"),
      playbackItem("requested-2"),
      playbackItem("requested-3"),
    ]
    let composedItems = Array(requestedItems.dropFirst()) + Array(existingItems.dropFirst())
    let initialSnapshot = playbackSnapshot(items: existingItems)
    let composedSnapshot = playbackSnapshot(items: composedItems)
    let recorder = PlaybackQueueRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { items, startIndex in
        await recorder.record(items: items, startIndex: startIndex)
        return composedSnapshot
      }
    }

    await store.send(.playNow(items: requestedItems, startIndex: 1)) {
      $0.hasAuthoritativeSnapshot = false
      $0.lastCachedProgressBucket = nil
      $0.pendingPlayNowItems = composedItems
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: composedItems),
      )
    }
    await store.receive(.playNowFinished(composedSnapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlayNowItems = nil
      $0.session = PlaybackFeature.Session(snapshot: composedSnapshot, sourceAlbumIDs: [:])
    }

    let recordedItems = await recorder.items
    let recordedStartIndex = await recorder.startIndex
    expectNoDifference(recordedItems, requestedItems)
    expectNoDifference(recordedStartIndex, 1)
  }

  @Test
  func playNowPreservesDuplicateOccurrences() async {
    let duplicate = playbackItem("duplicate")
    let existingItems = [playbackItem("current"), duplicate]
    let requestedItems = [playbackItem("first"), duplicate, duplicate]
    let composedItems = requestedItems + [duplicate]
    let snapshot = playbackSnapshot(items: composedItems)
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(
        snapshot: playbackSnapshot(items: existingItems),
        sourceAlbumIDs: [:],
      ),
      hasAuthoritativeSnapshot: true,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playNow(items: requestedItems, startIndex: 0)) {
      $0.hasAuthoritativeSnapshot = false
      $0.pendingPlayNowItems = composedItems
      $0.session = .init(playStatus: .loading, queue: .init(items: composedItems))
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlayNowItems = nil
      $0.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    }

    expectNoDifference(store.state.session?.queue.items, composedItems)
    expectNoDifference(
      store.state.session?.queue.entries.map(\.id),
      ["entry-0", "entry-1", "entry-2", "entry-3"],
    )
  }

  @Test
  func playNowReconcilesPlaylistSourcesOntoMusicKitEntries() async {
    let firstSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let secondSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let items = [
      playbackItem("duplicate").withPlaylistSource(firstSource),
      playbackItem("duplicate").withPlaylistSource(secondSource),
    ]
    let snapshot = playbackSnapshot(items: items.map { $0.withPlaylistSource(nil) })
    let sourceHints = [
      "entry-0": firstSource,
      "entry-1": secondSource,
    ]
    let store = TestStore(initialState: PlaybackFeature.State()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playNow(items: items, startIndex: 0)) {
      $0.pendingPlayNowItems = items
      $0.pendingPlaylistSourcePlan = items.map {
        PlaybackSourceHintMatcher.Occurrence(item: $0)
      }
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: items),
      )
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlayNowItems = nil
      $0.pendingPlaylistSourcePlan = nil
      $0.playlistSourceHints = sourceHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        playlistSourceHints: sourceHints,
      )
    }

    expectNoDifference(store.state.session?.queue.items, items)
  }

  @Test
  func progressiveSnapshotsRetainSourcePlanUntilAllOccurrencesMaterialize() async {
    let firstSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let secondSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let sourcedItems = [
      playbackItem("first").withPlaylistSource(firstSource),
      playbackItem("second").withPlaylistSource(secondSource),
    ]
    let plan = sourcedItems.map {
      PlaybackSourceHintMatcher.Occurrence(item: $0)
    }
    let firstSnapshot = playbackSnapshot(items: [playbackItem("first")])
    let fullSnapshot = playbackSnapshot(items: [
      playbackItem("first"),
      playbackItem("second"),
    ])
    let firstHints = ["entry-0": firstSource]
    let fullHints = [
      "entry-0": firstSource,
      "entry-1": secondSource,
    ]
    var state = PlaybackFeature.State()
    state.pendingPlaylistSourcePlan = plan
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(firstSnapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.playlistSourceHints = firstHints
      $0.session = PlaybackFeature.Session(
        snapshot: firstSnapshot,
        sourceAlbumIDs: [:],
        playlistSourceHints: firstHints,
      )
    }
    await store.send(.playbackEvent(.snapshotChanged(fullSnapshot))) {
      $0.pendingPlaylistSourcePlan = nil
      $0.playlistSourceHints = fullHints
      $0.session = PlaybackFeature.Session(
        snapshot: fullSnapshot,
        sourceAlbumIDs: [:],
        playlistSourceHints: fullHints,
      )
    }
  }

  @Test
  func playlistSourceMatcherAlignsDuplicateOccurrencesAndPreservedTail() {
    let firstSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let secondSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let tailSource = PlaylistPlaybackSource(playlistID: UUID(4), entryID: UUID(5))
    let plan = [
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("duplicate").withPlaylistSource(firstSource),
      ),
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("duplicate").withPlaylistSource(secondSource),
      ),
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("tail").withPlaylistSource(tailSource),
        retainedEntryID: "old-tail",
      ),
    ]
    let entries = [
      PlaybackQueueEntry(id: "new-1", item: playbackItem("duplicate")),
      PlaybackQueueEntry(id: "new-2", item: playbackItem("duplicate")),
      PlaybackQueueEntry(id: "old-tail", item: playbackItem("tail")),
    ]

    let matched = PlaybackSourceHintMatcher.match(plan: plan, entries: entries)

    expectNoDifference(matched, [
      "new-1": firstSource,
      "new-2": secondSource,
      "old-tail": tailSource,
    ])
  }

  @Test
  func playlistSourceMatcherSupportsProgressiveMaterialization() {
    let firstSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let secondSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let plan = [
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("first").withPlaylistSource(firstSource),
      ),
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("second").withPlaylistSource(secondSource),
      ),
      PlaybackSourceHintMatcher.Occurrence(item: playbackItem("third")),
    ]
    let partialEntries = [
      PlaybackQueueEntry(id: "new-1", item: playbackItem("first")),
      PlaybackQueueEntry(id: "new-2", item: playbackItem("second")),
    ]

    let matched = PlaybackSourceHintMatcher.match(plan: plan, entries: partialEntries)

    expectNoDifference(matched, [
      "new-1": firstSource,
      "new-2": secondSource,
    ])
  }

  @Test
  func playlistSourceMatcherPreservesEntryIdentityAcrossReorderAndRemove() {
    let firstSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let secondSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let plan = [
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("first").withPlaylistSource(firstSource),
        retainedEntryID: "entry-1",
      ),
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("second").withPlaylistSource(secondSource),
        retainedEntryID: "entry-2",
      ),
    ]
    let reorderedEntries = [
      PlaybackQueueEntry(id: "entry-2", item: playbackItem("second")),
    ]

    let matched = PlaybackSourceHintMatcher.match(
      plan: plan,
      entries: reorderedEntries,
      existing: ["entry-1": firstSource, "entry-2": secondSource],
    )

    expectNoDifference(matched, ["entry-2": secondSource])
  }

  @Test
  func playlistSourceMatcherDoesNotGuessForUnattributedDuplicateSong() {
    let source = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let plan = [
      PlaybackSourceHintMatcher.Occurrence(item: playbackItem("duplicate")),
      PlaybackSourceHintMatcher.Occurrence(
        item: playbackItem("duplicate").withPlaylistSource(source),
      ),
    ]
    let entries = [
      PlaybackQueueEntry(id: "only", item: playbackItem("duplicate")),
    ]

    let matched = PlaybackSourceHintMatcher.match(plan: plan, entries: entries)

    expectNoDifference(matched, [:])
  }

  @Test
  func musicKitArtworkURLUsesWebFallbackWhenAvailable() {
    let webURL = URL(string: "https://example.com/album.jpg")!
    let libraryURL = URL(
      string: "musicKit://artwork/library/id/600x600?fat=https%3A%2F%2Fexample.com%2Falbum.jpg",
    )!
    let transientURL = URL(string: "musicKit://artwork/transient/600x600?id=artwork")!
    let libraryItem = PlaybackItem(
      id: "track-1",
      title: "Track",
      artistName: "Artist",
      artworkURL: libraryURL,
    )
    let transientItem = PlaybackItem(
      id: "track-2",
      title: "Other Track",
      artistName: "Artist",
      artworkURL: transientURL,
    )

    expectNoDifference(libraryItem.artworkURL, webURL)
    expectNoDifference(transientItem.artworkURL, transientURL)
  }

  @Test
  func progressOnlySnapshotsHaveTheSameSession() {
    let items = [playbackItem("track-1")]
    let initial = playbackSnapshot(items: items)
    let progressed = playbackSnapshot(
      items: items,
      progress: .init(elapsedTime: 1, duration: 180),
    )
    let paused = playbackSnapshot(items: items, playStatus: .paused)

    #expect(progressed.hasSameSession(as: initial))
    #expect(!paused.hasSameSession(as: initial))
  }

  @Test
  func terminalDetectorRecognizesNaturalFinalCompletion() {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let playingFinalItem = PlaybackTerminalDetector.Observation(
      isRepeatModeNone: true,
      snapshot: playbackSnapshot(
        items: items,
        currentIndex: 1,
        progress: .init(elapsedTime: 1.95, duration: 2),
      ),
      status: .playing,
    )
    let naturallyCompleted = PlaybackTerminalDetector.Observation(
      isRepeatModeNone: true,
      snapshot: playbackSnapshot(
        items: items,
        playStatus: .paused,
        progress: .init(elapsedTime: 0, duration: 2),
      ),
      status: .paused,
    )
    var detector = PlaybackTerminalDetector()

    let beganPlayback = detector.update(playingFinalItem)
    let endedQueue = detector.update(naturallyCompleted)
    #expect(!beganPlayback)
    #expect(endedQueue)
  }

  @Test
  func terminalDetectorDoesNotTreatPauseInterruptionOrStopAsCompletion() {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let playingFinalItem = PlaybackTerminalDetector.Observation(
      isRepeatModeNone: true,
      snapshot: playbackSnapshot(
        items: items,
        currentIndex: 1,
        progress: .init(elapsedTime: 1.95, duration: 2),
      ),
      status: .playing,
    )
    for status in [
      PlaybackObservationStatus.paused,
      .interrupted,
      .stopped,
    ] {
      var detector = PlaybackTerminalDetector()
      _ = detector.update(playingFinalItem)
      let retainedFinalItem = PlaybackTerminalDetector.Observation(
        isRepeatModeNone: true,
        snapshot: playbackSnapshot(
          items: items,
          currentIndex: 1,
          playStatus: .paused,
          progress: .init(elapsedTime: 1.95, duration: 2),
        ),
        status: status,
      )

      let endedQueue = detector.update(retainedFinalItem)
      #expect(!endedQueue)
    }
  }

  @Test
  func simulatorPlayNowPreservesExistingUpcoming() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated { _ in
      await clock.sleep()
    }
    let existingItems = [
      playbackItem("current"),
      playbackItem("old-next-1"),
      playbackItem("old-next-2"),
    ]
    let requestedItems = [
      playbackItem("requested-1"),
      playbackItem("requested-2"),
      playbackItem("requested-2"),
    ]
    _ = try await client.playNow(existingItems, 0)

    let snapshot = try await client.playNow(requestedItems, 1)

    expectNoDifference(
      snapshot.entries.map(\.item.id),
      ["requested-2", "requested-2", "old-next-1", "old-next-2"],
    )
    #expect(snapshot.currentEntryID == snapshot.entries.first?.id)
    #expect(Set(snapshot.entries.map(\.id)).count == 4)
    await client.clearQueue()
    await clock.advance()
  }

  @Test
  func simulatorProgressTickerEmitsProgressWithoutRepublishingSession() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated { _ in
      await clock.sleep()
    }
    let receivedEvents = Task {
      var events: [PlaybackEvent] = []
      for await event in client.events() {
        events.append(event)
        if events.count == 3 { return events }
      }
      return events
    }
    await Task.yield()
    _ = try await client.playNow([playbackItem("track-1")], 0)

    await clock.advance()
    let events = await receivedEvents.value

    #expect(events.count == 3)
    guard case .progressChanged(let progress) = events.last else {
      Issue.record("Expected a progress event")
      return
    }
    expectNoDifference(progress, .init(elapsedTime: 0.25, duration: 180))
    await client.clearQueue()
    await clock.advance()
  }

  @Test
  func simulatorPlayNextAndAddToQueueRetainOrdering() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated { _ in
      await clock.sleep()
    }
    let initialItems = [
      playbackItem("current"),
      playbackItem("old-next-1"),
      playbackItem("old-next-2"),
    ]
    _ = try await client.playNow(initialItems, 0)

    _ = try await client.insertIntoQueue(
      [playbackItem("play-next-1"), playbackItem("play-next-2")],
      .next,
    )
    let snapshot = try await client.insertIntoQueue([playbackItem("added")], .tail)

    expectNoDifference(
      snapshot.entries.map(\.item.id),
      ["current", "play-next-1", "play-next-2", "old-next-1", "old-next-2", "added"],
    )
    await client.clearQueue()
    await clock.advance()
  }

  @Test
  func simulatorTransitionConsumesVisibleHead() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated(defaultDuration: 0.25) { _ in
      await clock.sleep()
    }
    let items = [playbackItem("first"), playbackItem("second")]
    _ = try await client.playNow(items, 0)

    await clock.advance()
    await clock.waitUntilSleeping()
    let snapshot = try await client.insertIntoQueue([], .tail)

    expectNoDifference(snapshot.entries.map(\.item.id), ["first", "second"])
    #expect(snapshot.currentEntryID == snapshot.entries[1].id)
    await client.clearQueue()
    await clock.advance()
  }

  @Test
  func simulatorRestoreUsesPausedCurrentAndFutureOnly() async throws {
    let client = PlaybackClient.simulated()

    let snapshot = try await client.restoreQueue(.mock)

    expectNoDifference(snapshot.entries.map(\.item.id), ["track-2"])
    #expect(snapshot.currentEntryID == snapshot.entries[0].id)
    #expect(snapshot.playStatus == .paused)
    expectNoDifference(snapshot.progress, .init(elapsedTime: 42, duration: 180))
  }

  @Test
  func simulatorPauseOnFinalItemDoesNotEndQueue() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated(defaultDuration: 0.25) { _ in
      await clock.sleep()
    }
    let item = playbackItem("track-1")
    _ = try await client.playNow([item], 0)
    await clock.waitUntilSleeping()

    await client.pause()
    let snapshot = try await client.insertIntoQueue([], .tail)

    expectNoDifference(snapshot.entries.map(\.item.id), [item.id])
    #expect(snapshot.currentEntryID == snapshot.entries[0].id)
    #expect(snapshot.playStatus == .paused)
    await clock.advance()
  }

  @Test
  func simulatorNaturalFinalCompletionEmitsQueueEnded() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated(defaultDuration: 0.5) { _ in
      await clock.sleep()
    }
    let queueEnded = Task {
      for await event in client.events() {
        if event == .queueEnded {
          return true
        }
      }
      return false
    }
    await Task.yield()
    _ = try await client.playNow([playbackItem("track-1")], 0)

    await clock.advance()
    await clock.advance()

    #expect(await queueEnded.value)
  }

  @Test
  func newerPlayNowCancelsInFlightPlayNow() async {
    let firstItems = [playbackItem("first-1"), playbackItem("first-2")]
    let secondItems = [playbackItem("second-1"), playbackItem("second-2")]
    let secondSnapshot = playbackSnapshot(items: secondItems)
    let gate = PlaybackStartGate()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { items, startIndex in
        try await gate.start()
        return playbackSnapshot(items: Array(items[startIndex...]))
      }
    }

    await store.send(.playNow(items: firstItems, startIndex: 0)) {
      $0.pendingPlayNowItems = firstItems
      $0.session = .init(playStatus: .loading, queue: .init(items: firstItems))
    }
    await gate.waitUntilFirstStartBegins()

    await store.send(.playNow(items: secondItems, startIndex: 0)) {
      $0.pendingPlayNowItems = secondItems
      $0.session = .init(playStatus: .loading, queue: .init(items: secondItems))
    }
    await store.receive(.playNowFinished(secondSnapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlayNowItems = nil
      $0.session = PlaybackFeature.Session(snapshot: secondSnapshot, sourceAlbumIDs: [:])
    }

    await gate.releaseFirstStart()
    await store.finish()
  }

  @Test
  func queueEditCancelsInFlightPlayNow() async {
    let playNowItems = [playbackItem("first-1"), playbackItem("first-2")]
    let queuedItem = playbackItem("queued")
    let queuedSnapshot = playbackSnapshot(items: [queuedItem])
    let gate = PlaybackStartGate()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { _, _ in queuedSnapshot }
      $0.playback.playNow = { _, _ in
        try await gate.start()
        return .empty
      }
    }

    await store.send(.playNow(items: playNowItems, startIndex: 0)) {
      $0.pendingPlayNowItems = playNowItems
      $0.session = .init(playStatus: .loading, queue: .init(items: playNowItems))
    }
    await gate.waitUntilFirstStartBegins()

    await store.send(.addToQueue([queuedItem])) {
      $0.pendingPlayNowItems = nil
    }
    await store.receive(.playbackEvent(.snapshotChanged(queuedSnapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.session = PlaybackFeature.Session(snapshot: queuedSnapshot, sourceAlbumIDs: [:])
    }

    await gate.releaseFirstStart()
    await store.finish()
  }

  @Test
  func playNowKeepsPendingProjectionUntilFullSnapshotArrives() async {
    let items = [
      playbackItem("track-1"),
      playbackItem("track-2"),
      playbackItem("track-3"),
    ]
    let partialSnapshot = playbackSnapshot(items: [items[0]])
    let fullSnapshot = playbackSnapshot(items: items)
    let store = TestStore(initialState: .init(
      session: .init(playStatus: .loading, queue: .init(items: items)),
      pendingPlayNowItems: items,
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(partialSnapshot)))
    await store.send(.playbackEvent(.snapshotChanged(fullSnapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlayNowItems = nil
      $0.session = PlaybackFeature.Session(snapshot: fullSnapshot, sourceAlbumIDs: [:])
    }
  }

  @Test
  func playNowResponseUsesAuthoritativeLiveTail() async {
    let requestedItems = [playbackItem("requested-1"), playbackItem("requested-2")]
    let authoritativeItems = requestedItems + [playbackItem("restored-tail")]
    let snapshot = playbackSnapshot(items: authoritativeItems)
    let store = TestStore(initialState: .init(
      session: .init(playStatus: .loading, queue: .init(items: requestedItems)),
      pendingPlayNowItems: requestedItems,
    )) {
      PlaybackFeature()
    }

    await store.send(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlayNowItems = nil
      $0.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    }
  }

  @Test
  func queueTracksCurrentAndUpcomingItems() {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let queue = PlaybackFeature.Queue(items: items, currentIndex: 1)

    #expect(queue.currentItem == items[1])
    #expect(queue.upcomingItems == [items[2]])
  }

  @Test
  func playNowWithEmptyTracksDoesNothing() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playNow(items: [], startIndex: 0))
  }

  @Test
  func playNowWithInvalidStartIndexDoesNothing() async {
    let items = [playbackItem("track-1")]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playNow(items: items, startIndex: 1))
  }

  @Test
  func queueInsertionCommandsUseRequestedMusicKitPositions() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let insertedItem = playbackItem("track-3")
    let snapshot = playbackSnapshot(items: items)
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { items, position in
        await recorder.recordInsertion(items: items, position: position)
        return snapshot
      }
    }

    await store.send(.addToQueue([insertedItem]))
    await store.receive(.playbackEvent(.snapshotChanged(snapshot)))
    await store.send(.playNext([insertedItem]))
    await store.receive(.playbackEvent(.snapshotChanged(snapshot)))

    #expect(await recorder.insertions == [
      .init(items: [insertedItem], position: .tail),
      .init(items: [insertedItem], position: .next),
    ])
  }

  @Test
  func addToQueueWithoutPlaybackShowsLoadingThenUsesMusicKitSnapshot() async {
    let item = playbackItem("track-1")
    let snapshot = playbackSnapshot(items: [item])
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { _, _ in snapshot }
    }

    await store.send(.addToQueue([item])) {
      $0.session = .init(playStatus: .loading, currentItem: item)
    }
    await store.receive(.playbackEvent(.snapshotChanged(snapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    }
  }

  @Test
  func clearUpcomingPreservesCurrentPlayback() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let initialSnapshot = playbackSnapshot(
      items: items,
      currentIndex: 1,
      progress: .init(elapsedTime: 42, duration: 180),
    )
    let updatedSnapshot = PlaybackSnapshot(
      entries: Array(initialSnapshot.entries.prefix(2)),
      currentEntryID: initialSnapshot.currentEntryID,
      playStatus: .playing,
      progress: initialSnapshot.progress,
    )
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 8,
      progress: initialSnapshot.progress,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.clearUpcoming = {
        await recorder.recordClearUpcoming()
        return updatedSnapshot
      }
    }

    await store.send(.clearUpcomingButtonTapped)
    await store.receive(.playbackEvent(.snapshotChanged(updatedSnapshot))) {
      $0.session = PlaybackFeature.Session(snapshot: updatedSnapshot, sourceAlbumIDs: [:])
    }

    #expect(await recorder.clearUpcomingCount == 1)
  }

  @Test
  func queueEntryRemovalUsesOccurrenceIdentity() async {
    let items = [playbackItem("track-1"), playbackItem("track-1"), playbackItem("track-2")]
    let initialSnapshot = playbackSnapshot(items: items)
    let updatedSnapshot = PlaybackSnapshot(
      entries: [initialSnapshot.entries[0], initialSnapshot.entries[2]],
      currentEntryID: initialSnapshot.currentEntryID,
      playStatus: .playing,
      progress: .zero,
    )
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.removeQueueEntry = { entryID in
        await recorder.recordRemoval(entryID: entryID)
        return updatedSnapshot
      }
    }

    await store.send(.queueEntryRemoveRequested("entry-1"))
    await store.receive(.playbackEvent(.snapshotChanged(updatedSnapshot))) {
      $0.session = PlaybackFeature.Session(snapshot: updatedSnapshot, sourceAlbumIDs: [:])
    }

    #expect(await recorder.removedEntryIDs == ["entry-1"])
  }

  @Test
  func reorderUpcomingUsesMusicKitOccurrenceOrder() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let initialSnapshot = playbackSnapshot(items: items)
    let updatedSnapshot = PlaybackSnapshot(
      entries: [
        initialSnapshot.entries[0],
        initialSnapshot.entries[2],
        initialSnapshot.entries[1],
      ],
      currentEntryID: initialSnapshot.currentEntryID,
      playStatus: .playing,
      progress: .zero,
    )
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.reorderUpcoming = { entryIDs in
        await recorder.recordReorder(entryIDs: entryIDs)
        return updatedSnapshot
      }
    }

    await store.send(.reorderUpcoming(["entry-2", "entry-1"]))
    await store.receive(.playbackEvent(.snapshotChanged(updatedSnapshot))) {
      $0.session = PlaybackFeature.Session(snapshot: updatedSnapshot, sourceAlbumIDs: [:])
    }

    #expect(await recorder.reorderedEntryIDs == [["entry-2", "entry-1"]])
  }

  @Test
  func playbackFailurePausesCurrentSessionAndShowsFailure() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in throw PlaybackClientError.musicAccessDenied }
    }

    let item = playbackItem("track-1")

    await store.send(.playNow(items: [item], startIndex: 0)) {
      $0.pendingPlayNowItems = [item]
      $0.session = .init(playStatus: .loading, currentItem: item)
    }
    await store.receive(.playbackFailed(.musicAccessDenied)) {
      $0.failure = .musicAccessDenied
      $0.pendingPlayNowItems = nil
      $0.session?.playStatus = .paused
    }
  }

  @Test
  func dismissPlaybackFailureClearsFailure() async {
    let store = TestStore(initialState: .init(failure: .trackUnavailable)) {
      PlaybackFeature()
    }

    await store.send(.playbackFailureDismissed) {
      $0.failure = nil
    }
  }

  @Test
  func playbackFailureActionOpensSettingsWhenAvailable() async {
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(failure: .musicAccessDenied)) {
      PlaybackFeature()
    } withDependencies: {
      $0.systemSettings.openAppSettings = {
        await recorder.recordOpenSettings()
      }
    }

    await store.send(.playbackFailureActionTapped)
    #expect(await recorder.openSettingsCount == 1)
  }

  @Test
  func playbackSnapshotUpdatesCurrentSessionPlayStatus() async {
    let items = [playbackItem("track-1")]
    let playingSnapshot = playbackSnapshot(items: items)
    let pausedSnapshot = playbackSnapshot(items: items, playStatus: .paused)
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: playingSnapshot, sourceAlbumIDs: [:]),
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(pausedSnapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.session?.playStatus = .paused
      $0.lastCachedProgressBucket = 0
    }
    await store.send(.playbackEvent(.snapshotChanged(playingSnapshot))) {
      $0.session?.playStatus = .playing
      $0.lastCachedProgressBucket = 0
    }
  }

  @Test
  func playbackSnapshotUpdatesCurrentSessionProgress() async {
    let items = [playbackItem("track-1")]
    let initialSnapshot = playbackSnapshot(items: items)
    let progress = PlaybackProgress(elapsedTime: 42, duration: 180)
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(playbackSnapshot(
      items: items,
      progress: progress,
    )))) {
      $0.hasAuthoritativeSnapshot = true
      $0.progress = progress
      $0.lastCachedProgressBucket = 8
    }
  }

  @Test
  func progressEventUpdatesProgressWithoutReplacingSession() async {
    let item = playbackItem("track-1")
    let session = PlaybackFeature.Session(currentItem: item)
    let progress = PlaybackProgress(elapsedTime: 0.25, duration: 180)
    let store = TestStore(initialState: .init(
      session: session,
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.progressChanged(progress))) {
      $0.progress = progress
    }
    expectNoDifference(store.state.session, session)
  }

  @Test
  func progressEventFromReplacedQueueDoesNotUpdatePendingSession() async {
    let pendingItem = playbackItem("pending")
    let store = TestStore(initialState: .init(
      session: .init(playStatus: .loading, currentItem: pendingItem),
      pendingPlayNowItems: [pendingItem],
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.progressChanged(.init(
      elapsedTime: 42,
      duration: 180,
    ))))
  }

  @Test
  func playbackSnapshotUpdatesCurrentOccurrence() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let initialSnapshot = playbackSnapshot(
      items: items,
      progress: .init(elapsedTime: 40, duration: 180),
    )
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      progress: initialSnapshot.progress,
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(playbackSnapshot(
      items: items,
      currentIndex: 2,
    )))) {
      $0.hasAuthoritativeSnapshot = true
      $0.session?.queue.currentIndex = 2
      $0.progress = .zero
      $0.lastCachedProgressBucket = 0
    }
  }

  @Test
  func playbackSnapshotDistinguishesDuplicateOccurrences() {
    let item = playbackItem("track-1")
    let snapshot = playbackSnapshot(items: [item, item], currentIndex: 1)
    let session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])

    #expect(session?.queue.entries.map(\.id) == ["entry-0", "entry-1"])
    #expect(session?.queue.currentIndex == 1)
    #expect(session?.currentTrackID == item.id)
  }

  @Test
  func playbackSnapshotWithUnknownCurrentEntryDoesNothing() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let initialSnapshot = playbackSnapshot(items: items)
    let invalidSnapshot = PlaybackSnapshot(
      entries: initialSnapshot.entries,
      currentEntryID: "missing-entry",
      playStatus: .playing,
      progress: .zero,
    )
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(invalidSnapshot)))
  }

  @Test
  func playbackSnapshotCreatesSessionFromMusicKitState() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let snapshot = playbackSnapshot(items: items, currentIndex: 1, playStatus: .paused)
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(snapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
      $0.lastCachedProgressBucket = 0
    }
  }

  @Test
  func pausePausesCurrentSession() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(currentItem: item))) {
      PlaybackFeature()
    }

    await store.send(.pause) {
      $0.session?.playStatus = .paused
    }
  }

  @Test
  func resumeResumesCurrentSession() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(
      playStatus: .paused,
      currentItem: item,
    ))) {
      PlaybackFeature()
    }

    await store.send(.resume) {
      $0.session?.playStatus = .playing
    }
  }

  @Test
  func togglePlayPausePausesPlayingSession() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(currentItem: item))) {
      PlaybackFeature()
    }

    await store.send(.togglePlayPause)
    await store.receive(.pause) {
      $0.session?.playStatus = .paused
    }
  }

  @Test
  func togglePlayPauseResumesPausedSession() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(
      playStatus: .paused,
      currentItem: item,
    ))) {
      PlaybackFeature()
    }

    await store.send(.togglePlayPause)
    await store.receive(.resume) {
      $0.session?.playStatus = .playing
    }
  }

  @Test
  func seekUpdatesCurrentSessionProgress() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(
      session: .init(currentItem: item),
      progress: .init(elapsedTime: 10, duration: 180),
    )) {
      PlaybackFeature()
    }

    await store.send(.seek(42)) {
      $0.progress = .init(elapsedTime: 42, duration: 180)
    }
  }

  @Test
  func seekClampsToDuration() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(
      session: .init(currentItem: item),
      progress: .init(elapsedTime: 10, duration: 180),
    )) {
      PlaybackFeature()
    }

    await store.send(.seek(240)) {
      $0.progress = .init(elapsedTime: 180, duration: 180)
    }
  }

  @Test
  func skipToNextRequestsMusicKitNextEntry() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(
      session: .init(queue: .init(items: items, currentIndex: 0)),
      progress: .init(elapsedTime: 42, duration: 180),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.skipToNext = {
        await recorder.recordSkipToNext()
        return .advanced
      }
    }

    await store.send(.skipToNext)

    #expect(await recorder.skipToNextCount == 1)
  }

  @Test
  func skipToNextOnFinalItemEndsQueue() async {
    let item = playbackItem("track-1")
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(
      session: .init(currentItem: item),
      failure: .trackUnavailable,
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 8,
      pendingAlbumResolutionSongID: item.id,
      progress: .init(elapsedTime: 42, duration: 180),
      sourceAlbumIDs: [item.id: "album-1"],
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.clearQueue = {
        await recorder.recordClearQueue()
      }
      $0.playback.skipToNext = {
        await recorder.recordSkipToNext()
        return .queueEnded
      }
      $0.playbackSessionCache._delete = {
        await recorder.recordDeleteCheckpoint()
      }
    }

    await store.send(.skipToNext)
    await store.receive(.playbackEvent(.queueEnded)) {
      $0.failure = nil
      $0.hasAuthoritativeSnapshot = false
      $0.lastCachedProgressBucket = nil
      $0.pendingAlbumResolutionSongID = nil
      $0.progress = .zero
      $0.session = nil
      $0.sourceAlbumIDs.removeAll()
    }
    await store.finish()

    #expect(await recorder.clearQueueCount == 1)
    #expect(await recorder.deleteCheckpointCount == 1)
    #expect(await recorder.skipToNextCount == 1)
  }

  @Test
  func skipToPreviousAfterFirstThreeSecondsRestartsCurrentItem() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(
      session: .init(queue: .init(items: items, currentIndex: 1)),
      progress: .init(elapsedTime: 4, duration: 180),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restartCurrentEntry = {
        await recorder.recordRestartCurrentEntry()
      }
    }

    await store.send(.skipToPrevious)

    #expect(await recorder.restartCurrentEntryCount == 1)
  }

  @Test
  func skipToPreviousWithinFirstThreeSecondsMovesToPreviousItem() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(
      session: .init(queue: .init(items: items, currentIndex: 1)),
      progress: .init(elapsedTime: 3, duration: 180),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.skipToPrevious = {
        await recorder.recordSkipToPrevious()
      }
    }

    await store.send(.skipToPrevious)

    #expect(await recorder.skipToPreviousCount == 1)
  }

  @Test
  func skipToPreviousOnFirstItemRestartsWithoutWrapping() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(
      session: .init(queue: .init(items: items, currentIndex: 0)),
      progress: .init(elapsedTime: 2, duration: 180),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restartCurrentEntry = {
        await recorder.recordRestartCurrentEntry()
      }
    }

    await store.send(.skipToPrevious)

    #expect(await recorder.restartCurrentEntryCount == 1)
    #expect(await recorder.skipToPreviousCount == 0)
  }

  @Test
  func skipWithoutSessionDoesNothing() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.skipToNext)
    await store.send(.skipToPrevious)
  }

  @Test
  func restoreCachedSessionHydratesActiveMusicKitSnapshot() async {
    let snapshot = playbackSnapshot(
      items: [playbackItem("track-2")],
      playStatus: .paused,
      progress: .init(elapsedTime: 42, duration: 180),
    )
    let recorder = PlaybackCheckpointRestoreRecorder()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restoreQueue = { checkpoint in
        await recorder.record(checkpoint)
        return snapshot
      }
      $0.playbackSessionCache._load = { .mock }
    }

    await store.send(.restoreCachedSession)
    await store.receive(.checkpointLoaded(.mock)) {
      $0.isRestoringCheckpoint = true
    }
    await store.receive(.checkpointRestorationFinished(snapshot)) {
      $0.isRestoringCheckpoint = false
    }
    await store.receive(.playbackEvent(.snapshotChanged(snapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 8
      $0.progress = snapshot.progress
      $0.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    }

    let restoredCheckpoint = await recorder.checkpoint
    expectNoDifference(restoredCheckpoint, PlaybackCheckpoint.mock.activeQueue)
  }

  @Test
  func restoreCachedSessionRealignsDuplicatePlaylistSources() async {
    let firstSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let secondSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(3))
    let checkpoint = PlaybackCheckpoint(
      songIDs: ["duplicate", "duplicate"],
      currentIndex: 0,
      elapsedTime: 12,
      playlistSourceHints: [firstSource, secondSource],
    )
    let snapshot = playbackSnapshot(
      items: [playbackItem("duplicate"), playbackItem("duplicate")],
      playStatus: .paused,
    )
    let sourceHints = [
      "entry-0": firstSource,
      "entry-1": secondSource,
    ]
    let store = TestStore(initialState: PlaybackFeature.State()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restoreQueue = { _ in snapshot }
      $0.playbackSessionCache._load = { checkpoint }
    }

    await store.send(.restoreCachedSession)
    await store.receive(.checkpointLoaded(checkpoint)) {
      $0.isRestoringCheckpoint = true
      $0.pendingPlaylistSourcePlan = zip(
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
    }
    await store.receive(.checkpointRestorationFinished(snapshot)) {
      $0.isRestoringCheckpoint = false
    }
    await store.receive(.playbackEvent(.snapshotChanged(snapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingPlaylistSourcePlan = nil
      $0.playlistSourceHints = sourceHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        playlistSourceHints: sourceHints,
      )
    }

    expectNoDifference(
      store.state.session?.queue.items.map(\.playlistSource),
      [firstSource, secondSource],
    )
  }

  @Test
  func restoreCachedSessionDoesNotReplaceExistingSession() async {
    let existingItem = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(currentItem: existingItem))) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackSessionCache._load = { .mock }
    }

    await store.send(.restoreCachedSession)
  }

  @Test
  func failedCheckpointRestorationRetainsCheckpointForRetry() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restoreQueue = { _ in throw TestError() }
      $0.playbackSessionCache._load = { .mock }
    }

    await store.send(.restoreCachedSession)
    await store.receive(.checkpointLoaded(.mock)) {
      $0.isRestoringCheckpoint = true
    }
    await store.receive(.checkpointRestorationFinished(nil)) {
      $0.isRestoringCheckpoint = false
    }
  }

  @Test
  func saveCachedSessionPersistsAuthoritativeCheckpoint() async {
    let snapshot = playbackSnapshot(
      items: [playbackItem("track-1"), playbackItem("track-2")],
      currentIndex: 1,
      playStatus: .paused,
      progress: .init(elapsedTime: 42, duration: 180),
    )
    let recorder = PlaybackSessionCacheRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: ["track-1": "album-1"],
      ),
      hasAuthoritativeSnapshot: true,
      progress: snapshot.progress,
      sourceAlbumIDs: ["track-1": "album-1"],
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackSessionCache._save = { checkpoint in
        await recorder.record(checkpoint)
      }
    }

    await store.send(.saveCachedSession)

    let savedCheckpoint = await recorder.checkpoint
    expectNoDifference(savedCheckpoint, PlaybackCheckpoint.mock.activeQueue)
  }

  @Test
  func queueEndingCancelsInFlightCheckpointSaveBeforeDeleting() async {
    let item = playbackItem("track-1")
    let gate = PlaybackStartGate()
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(
      session: .init(currentItem: item),
      hasAuthoritativeSnapshot: true,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackSessionCache._delete = {
        await recorder.recordDeleteCheckpoint()
      }
      $0.playbackSessionCache._save = { _ in
        try await gate.start()
      }
    }

    await store.send(.saveCachedSession)
    await gate.waitUntilFirstStartBegins()
    await store.send(.playbackEvent(.queueEnded)) {
      $0.hasAuthoritativeSnapshot = false
      $0.session = nil
    }
    await store.finish()

    #expect(await recorder.deleteCheckpointCount == 1)
  }

  @Test
  func stopPausesCurrentSession() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(currentItem: item))) {
      PlaybackFeature()
    }

    await store.send(.stop) {
      $0.session?.playStatus = .paused
    }
  }
}

private actor PlaybackSimulatorClock {
  private var continuations: [CheckedContinuation<Void, Never>] = []
  private var sleepStartedContinuation: CheckedContinuation<Void, Never>?

  func advance() async {
    if self.continuations.isEmpty {
      await withCheckedContinuation { continuation in
        self.sleepStartedContinuation = continuation
      }
    }
    self.continuations.removeFirst().resume()
  }

  func sleep() async {
    await withCheckedContinuation { continuation in
      self.continuations.append(continuation)
      self.sleepStartedContinuation?.resume()
      self.sleepStartedContinuation = nil
    }
  }

  func waitUntilSleeping() async {
    guard self.continuations.isEmpty else { return }
    await withCheckedContinuation { continuation in
      self.sleepStartedContinuation = continuation
    }
  }
}

private actor PlaybackStartGate {
  private var callCount = 0
  private var firstReleaseContinuation: CheckedContinuation<Void, Never>?
  private var firstStartContinuation: CheckedContinuation<Void, Never>?
  private var firstStartHasBegun = false
  private var firstStartIsReleased = false

  func start() async throws {
    self.callCount += 1
    guard self.callCount == 1 else { return }
    self.firstStartHasBegun = true
    self.firstStartContinuation?.resume()
    self.firstStartContinuation = nil

    await withTaskCancellationHandler {
      await withCheckedContinuation { continuation in
        if self.firstStartIsReleased {
          continuation.resume()
        } else {
          self.firstReleaseContinuation = continuation
        }
      }
    } onCancel: {
      Task { await self.releaseFirstStart() }
    }
    try Task.checkCancellation()
  }

  func waitUntilFirstStartBegins() async {
    guard !self.firstStartHasBegun else { return }
    await withCheckedContinuation { continuation in
      self.firstStartContinuation = continuation
    }
  }

  func releaseFirstStart() {
    self.firstStartIsReleased = true
    self.firstReleaseContinuation?.resume()
    self.firstReleaseContinuation = nil
  }
}

private actor PlaybackQueueRecorder {
  var items: [PlaybackItem]?
  var startIndex: Int?

  func record(items: [PlaybackItem], startIndex: Int) {
    self.items = items
    self.startIndex = startIndex
  }
}

private actor PlaybackCheckpointRestoreRecorder {
  var checkpoint: PlaybackCheckpoint?

  func record(_ checkpoint: PlaybackCheckpoint) {
    self.checkpoint = checkpoint
  }
}

private actor PlaybackSessionCacheRecorder {
  var checkpoint: PlaybackCheckpoint?

  func record(_ checkpoint: PlaybackCheckpoint) {
    self.checkpoint = checkpoint
  }
}

private actor PlaybackQueueEditRecorder {
  struct Insertion: Equatable {
    var items: [PlaybackItem]
    var position: PlaybackQueueInsertionPosition
  }

  var clearUpcomingCount = 0
  var insertions: [Insertion] = []
  var removedEntryIDs: [PlaybackQueueEntry.ID] = []
  var reorderedEntryIDs: [[PlaybackQueueEntry.ID]] = []

  func recordClearUpcoming() {
    self.clearUpcomingCount += 1
  }

  func recordInsertion(
    items: [PlaybackItem],
    position: PlaybackQueueInsertionPosition,
  ) {
    self.insertions.append(.init(items: items, position: position))
  }

  func recordRemoval(entryID: PlaybackQueueEntry.ID) {
    self.removedEntryIDs.append(entryID)
  }

  func recordReorder(entryIDs: [PlaybackQueueEntry.ID]) {
    self.reorderedEntryIDs.append(entryIDs)
  }
}

private actor PlaybackCommandRecorder {
  var clearQueueCount = 0
  var deleteCheckpointCount = 0
  var restartCurrentEntryCount = 0
  var skipToNextCount = 0
  var skipToPreviousCount = 0
  var openSettingsCount = 0

  func recordClearQueue() {
    self.clearQueueCount += 1
  }

  func recordDeleteCheckpoint() {
    self.deleteCheckpointCount += 1
  }

  func recordRestartCurrentEntry() {
    self.restartCurrentEntryCount += 1
  }

  func recordSkipToNext() {
    self.skipToNextCount += 1
  }

  func recordSkipToPrevious() {
    self.skipToPreviousCount += 1
  }

  func recordOpenSettings() {
    self.openSettingsCount += 1
  }
}
