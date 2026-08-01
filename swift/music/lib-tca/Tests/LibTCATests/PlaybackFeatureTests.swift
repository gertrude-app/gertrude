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
    let requestedItems = Array(items.dropFirst()).map { $0.withQueueRole(.context) }
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    let snapshot = playbackSnapshot(items: requestedItems.map { $0.withQueueRole(nil) })
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .context,
    ]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playNow(
      items: items,
      startIndex: 1,
      context: context,
    )) {
      $0.pendingMetadataPlan = requestedItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.pendingPlayNowItems = requestedItems
      $0.playbackContext = context
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: requestedItems),
      )
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }
  }

  @Test
  func playNowPreservesQueuedItemsAndReplacesPreviousContext() async {
    let existingItems = [
      playbackItem("current").withQueueRole(.context),
      playbackItem("queued").withQueueRole(.queued),
      playbackItem("old-context").withQueueRole(.context),
    ]
    let requestedItems = [
      playbackItem("requested-1"),
      playbackItem("requested-2"),
      playbackItem("requested-3"),
    ]
    let composedItems = [
      requestedItems[1].withQueueRole(.context),
      existingItems[1],
      requestedItems[2].withQueueRole(.context),
    ]
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "new-album"),
      title: "New Album",
    )
    let composedSnapshot = playbackSnapshot(items: composedItems.map { $0.withQueueRole(nil) })
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .queued,
      "entry-2": .context,
    ]
    let recorder = PlaybackQueueRecorder()
    let store = TestStore(initialState: .init(
      session: .init(queue: .init(items: existingItems)),
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

    await store.send(.playNow(
      items: requestedItems,
      startIndex: 1,
      context: context,
    )) {
      $0.hasAuthoritativeSnapshot = false
      $0.lastCachedProgressBucket = nil
      $0.pendingMetadataPlan = composedItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.pendingPlayNowItems = composedItems
      $0.playbackContext = context
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: composedItems),
      )
    }
    await store.receive(.playNowFinished(composedSnapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.session = PlaybackFeature.Session(
        snapshot: composedSnapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }

    let recordedItems = await recorder.items
    let recordedStartIndex = await recorder.startIndex
    expectNoDifference(recordedItems, composedItems)
    expectNoDifference(recordedStartIndex, 0)
  }

  @Test
  func playNowPreservesDuplicateOccurrences() async {
    let duplicate = playbackItem("duplicate")
    let requestedItems = [playbackItem("first"), duplicate, duplicate]
    let composedItems = requestedItems.map { $0.withQueueRole(.context) }
    let snapshot = playbackSnapshot(items: composedItems.map { $0.withQueueRole(nil) })
    let roleHints = Dictionary(
      uniqueKeysWithValues: snapshot.entries.map { ($0.id, PlaybackQueueRole.context) },
    )
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playNow(
      items: requestedItems,
      startIndex: 0,
      context: nil,
    )) {
      $0.pendingMetadataPlan = composedItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.pendingPlayNowItems = composedItems
      $0.session = .init(playStatus: .loading, queue: .init(items: composedItems))
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }

    expectNoDifference(store.state.session?.queue.items, composedItems)
    expectNoDifference(
      store.state.session?.queue.entries.map(\.id),
      ["entry-0", "entry-1", "entry-2"],
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

    let contextItems = items.map { $0.withQueueRole(.context) }
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .context,
    ]
    await store.send(.playNow(
      items: items,
      startIndex: 0,
      context: nil,
    )) {
      $0.pendingMetadataPlan = contextItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.pendingPlayNowItems = contextItems
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: contextItems),
      )
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.playlistSourceHints = sourceHints
      $0.queueRoleHints = roleHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        playlistSourceHints: sourceHints,
        queueRoleHints: roleHints,
      )
    }

    expectNoDifference(store.state.session?.queue.items, contextItems)
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
      PlaybackMetadataHintMatcher.Occurrence(item: $0)
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
    state.pendingMetadataPlan = plan
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
      $0.pendingMetadataPlan = nil
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
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("duplicate").withPlaylistSource(firstSource),
      ),
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("duplicate").withPlaylistSource(secondSource),
      ),
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("tail").withPlaylistSource(tailSource),
        retainedEntryID: "old-tail",
      ),
    ]
    let entries = [
      PlaybackQueueEntry(id: "new-1", item: playbackItem("duplicate")),
      PlaybackQueueEntry(id: "new-2", item: playbackItem("duplicate")),
      PlaybackQueueEntry(id: "old-tail", item: playbackItem("tail")),
    ]

    let matched = PlaybackMetadataHintMatcher.match(plan: plan, entries: entries)

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
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("first").withPlaylistSource(firstSource),
      ),
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("second").withPlaylistSource(secondSource),
      ),
      PlaybackMetadataHintMatcher.Occurrence(item: playbackItem("third")),
    ]
    let partialEntries = [
      PlaybackQueueEntry(id: "new-1", item: playbackItem("first")),
      PlaybackQueueEntry(id: "new-2", item: playbackItem("second")),
    ]

    let matched = PlaybackMetadataHintMatcher.match(plan: plan, entries: partialEntries)

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
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("first").withPlaylistSource(firstSource),
        retainedEntryID: "entry-1",
      ),
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("second").withPlaylistSource(secondSource),
        retainedEntryID: "entry-2",
      ),
    ]
    let reorderedEntries = [
      PlaybackQueueEntry(id: "entry-2", item: playbackItem("second")),
    ]

    let matched = PlaybackMetadataHintMatcher.match(
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
      PlaybackMetadataHintMatcher.Occurrence(item: playbackItem("duplicate")),
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("duplicate").withPlaylistSource(source),
      ),
    ]
    let entries = [
      PlaybackQueueEntry(id: "only", item: playbackItem("duplicate")),
    ]

    let matched = PlaybackMetadataHintMatcher.match(plan: plan, entries: entries)

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
  func simulatorPlayNowReplacesExistingUpcoming() async throws {
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
      ["requested-2", "requested-2"],
    )
    #expect(snapshot.currentEntryID == snapshot.entries.first?.id)
    #expect(Set(snapshot.entries.map(\.id)).count == 2)
    await client.clearQueue()
    await clock.advance()
  }

  @Test
  func simulatorReplacesQueueWithExistingOccurrencesAndPreservesPausedState() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated { _ in
      await clock.sleep()
    }
    let initialSnapshot = try await client.playNow([
      playbackItem("revoked"),
      playbackItem("duplicate"),
      playbackItem("allowed"),
      playbackItem("duplicate"),
    ], 0)

    let snapshot = try await client.replaceQueue([
      initialSnapshot.entries[2],
      initialSnapshot.entries[3],
      initialSnapshot.entries[1],
    ], false)

    expectNoDifference(snapshot.entries.map(\.id), [
      initialSnapshot.entries[2].id,
      initialSnapshot.entries[3].id,
      initialSnapshot.entries[1].id,
    ])
    expectNoDifference(snapshot.entries.map(\.item.id), [
      "allowed",
      "duplicate",
      "duplicate",
    ])
    #expect(snapshot.currentEntryID == snapshot.entries.first?.id)
    #expect(snapshot.playStatus == .paused)
    expectNoDifference(snapshot.progress, .init(elapsedTime: 0, duration: 180))
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
    let initialSnapshot = try await client.playNow(initialItems, 0)

    _ = try await client.insertIntoQueue(
      [playbackItem("play-next-1"), playbackItem("play-next-2")],
      .next,
    )
    let snapshot = try await client.insertIntoQueue(
      [playbackItem("added")],
      .before(.init(id: "stale", item: initialSnapshot.entries[1].item)),
    )

    expectNoDifference(
      snapshot.entries.map(\.item.id),
      ["current", "play-next-1", "play-next-2", "added", "old-next-1", "old-next-2"],
    )
    await client.clearQueue()
    await clock.advance()
  }

  @Test
  func simulatorRepeatedReorderingRetainsEveryOccurrence() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated { _ in
      await clock.sleep()
    }
    let items = [
      playbackItem("current"),
      playbackItem("duplicate"),
      playbackItem("other"),
      playbackItem("duplicate"),
    ]
    let initialSnapshot = try await client.playNow(items, 0)
    let initialEntryIDs = initialSnapshot.entries.map(\.id)

    _ = try await client.setUpcoming([
      initialSnapshot.entries[3],
      initialSnapshot.entries[1],
      initialSnapshot.entries[2],
    ])
    let snapshot = try await client.setUpcoming([
      .init(id: "stale-other", item: initialSnapshot.entries[2].item),
      .init(id: "stale-duplicate-1", item: initialSnapshot.entries[3].item),
      .init(id: "stale-duplicate-2", item: initialSnapshot.entries[1].item),
    ])

    expectNoDifference(snapshot.entries.map(\.id), [
      initialEntryIDs[0],
      initialEntryIDs[2],
      initialEntryIDs[3],
      initialEntryIDs[1],
    ])
    expectNoDifference(snapshot.entries.map(\.item.id), [
      "current",
      "other",
      "duplicate",
      "duplicate",
    ])
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
    let firstContextItems = firstItems.map { $0.withQueueRole(.context) }
    let secondContextItems = secondItems.map { $0.withQueueRole(.context) }
    let secondSnapshot = playbackSnapshot(items: secondContextItems)
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .context,
    ]
    let gate = PlaybackStartGate()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { items, startIndex in
        try await gate.start()
        return playbackSnapshot(items: Array(items[startIndex...]))
      }
    }

    await store.send(.playNow(items: firstItems, startIndex: 0, context: nil)) {
      $0.pendingMetadataPlan = firstContextItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.pendingPlayNowItems = firstContextItems
      $0.session = .init(playStatus: .loading, queue: .init(items: firstContextItems))
    }
    await gate.waitUntilFirstStartBegins()

    await store.send(.playNow(items: secondItems, startIndex: 0, context: nil)) {
      $0.pendingMetadataPlan = secondContextItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.pendingPlayNowItems = secondContextItems
      $0.session = .init(playStatus: .loading, queue: .init(items: secondContextItems))
    }
    await store.receive(.playNowFinished(secondSnapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.session = PlaybackFeature.Session(
        snapshot: secondSnapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }

    await gate.releaseFirstStart()
    await store.finish()
  }

  @Test
  func queueEditCancelsInFlightPlayNow() async {
    let playNowItems = [playbackItem("first-1"), playbackItem("first-2")]
    let contextItems = playNowItems.map { $0.withQueueRole(.context) }
    let queuedItem = playbackItem("queued").withQueueRole(.queued)
    let queuedSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "pending:0:first-1", item: playNowItems[0]),
        .init(id: "queued-entry", item: queuedItem.withQueueRole(nil)),
        .init(id: "pending:1:first-2", item: playNowItems[1]),
      ],
      currentEntryID: "pending:0:first-1",
      playStatus: .playing,
      progress: .zero,
    )
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "pending:0:first-1": .context,
      "queued-entry": .queued,
      "pending:1:first-2": .context,
    ]
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

    await store.send(.playNow(items: playNowItems, startIndex: 0, context: nil)) {
      $0.pendingMetadataPlan = contextItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.pendingPlayNowItems = contextItems
      $0.session = .init(playStatus: .loading, queue: .init(items: contextItems))
    }
    await gate.waitUntilFirstStartBegins()

    await store.send(.addToQueue([queuedItem])) {
      $0.pendingMetadataPlan = [
        .init(item: contextItems[0], retainedEntryID: "pending:0:first-1"),
        .init(item: queuedItem),
        .init(item: contextItems[1], retainedEntryID: "pending:1:first-2"),
      ]
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = [
        "pending:0:first-1": .context,
        "pending:1:first-2": .context,
      ]
    }
    await store.receive(.playbackEvent(.snapshotChanged(queuedSnapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.queueRoleHints = roleHints
      $0.session = PlaybackFeature.Session(
        snapshot: queuedSnapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
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

    await store.send(.playNow(items: [], startIndex: 0, context: nil))
  }

  @Test
  func playNowWithInvalidStartIndexDoesNothing() async {
    let items = [playbackItem("track-1")]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playNow(items: items, startIndex: 1, context: nil))
  }

  @Test
  func queueInsertionCommandsUseManualQueueBoundaries() async {
    let currentItem = playbackItem("current").withQueueRole(.context)
    let contextItem = playbackItem("context").withQueueRole(.context)
    let addedItem = playbackItem("added").withQueueRole(.queued)
    let nextItem = playbackItem("next").withQueueRole(.queued)
    let initialSnapshot = playbackSnapshot(items: [currentItem, contextItem])
    let firstSnapshot = PlaybackSnapshot(
      entries: [
        initialSnapshot.entries[0],
        .init(id: "added-entry", item: addedItem.withQueueRole(nil)),
        initialSnapshot.entries[1],
      ],
      currentEntryID: initialSnapshot.currentEntryID,
      playStatus: .playing,
      progress: .zero,
    )
    let secondSnapshot = PlaybackSnapshot(
      entries: [
        initialSnapshot.entries[0],
        .init(id: "next-entry", item: nextItem.withQueueRole(nil)),
        .init(id: "added-entry", item: addedItem.withQueueRole(nil)),
        initialSnapshot.entries[1],
      ],
      currentEntryID: initialSnapshot.currentEntryID,
      playStatus: .playing,
      progress: .zero,
    )
    let firstRoleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "added-entry": .queued,
      "entry-1": .context,
    ]
    let secondRoleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "next-entry": .queued,
      "added-entry": .queued,
      "entry-1": .context,
    ]
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { items, target in
        let insertionCount = await recorder.recordInsertion(items: items, target: target)
        return insertionCount == 1 ? firstSnapshot : secondSnapshot
      }
    }

    await store.send(.addToQueue([addedItem])) {
      $0.pendingMetadataPlan = [
        .init(item: currentItem, retainedEntryID: "entry-0"),
        .init(item: addedItem),
        .init(item: contextItem, retainedEntryID: "entry-1"),
      ]
      $0.queueRoleHints = ["entry-0": .context, "entry-1": .context]
    }
    await store.receive(.playbackEvent(.snapshotChanged(firstSnapshot))) {
      $0.pendingMetadataPlan = nil
      $0.queueRoleHints = firstRoleHints
      $0.session = PlaybackFeature.Session(
        snapshot: firstSnapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: firstRoleHints,
      )
    }
    await store.send(.playNext([nextItem])) {
      $0.pendingMetadataPlan = [
        .init(item: currentItem, retainedEntryID: "entry-0"),
        .init(item: nextItem),
        .init(item: addedItem, retainedEntryID: "added-entry"),
        .init(item: contextItem, retainedEntryID: "entry-1"),
      ]
    }
    await store.receive(.playbackEvent(.snapshotChanged(secondSnapshot))) {
      $0.pendingMetadataPlan = nil
      $0.queueRoleHints = secondRoleHints
      $0.session = PlaybackFeature.Session(
        snapshot: secondSnapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: secondRoleHints,
      )
    }

    #expect(await recorder.insertions == [
      .init(items: [addedItem], target: .before(initialSnapshot.entries[1])),
      .init(items: [nextItem], target: .next),
    ])
  }

  @Test
  func addToQueueWithoutPlaybackShowsLoadingThenUsesMusicKitSnapshot() async {
    let item = playbackItem("track-1")
    let queuedItem = item.withQueueRole(.queued)
    let snapshot = playbackSnapshot(items: [item])
    let roleHints = ["entry-0": PlaybackQueueRole.queued]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { _, _ in snapshot }
    }

    await store.send(.addToQueue([item])) {
      $0.pendingMetadataPlan = [
        PlaybackMetadataHintMatcher.Occurrence(item: queuedItem),
      ]
      $0.session = .init(playStatus: .loading, currentItem: queuedItem)
    }
    await store.receive(.playbackEvent(.snapshotChanged(snapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.queueRoleHints = roleHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }
  }

  @Test
  func clearQueueSendsTheCompleteRemainingTarget() async {
    let items = [
      playbackItem("current").withQueueRole(.context),
      playbackItem("queued").withQueueRole(.queued),
      playbackItem("context").withQueueRole(.context),
    ]
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
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return updatedSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.clearQueueButtonTapped)
    await store.finish()

    let updates = await recorder.upcomingUpdates
    expectNoDifference(
      updates.map { $0.map(\.viewID) },
      [["entry-2"]],
    )
    expectNoDifference(
      store.state.session?.queue.upcomingEntries.map(\.viewID),
      ["entry-2"],
    )
  }

  @Test
  func queueEntryRemovalUsesStableIdentityAndPreservesDisplayedMetadata() async {
    let currentItem = PlaybackItem(
      id: "duplicate",
      title: "Current",
      artistName: "Artist",
      artworkURL: URL(string: "https://example.com/current.jpg"),
    )
    let removedItem = PlaybackItem(
      id: "duplicate",
      title: "Duplicate",
      artistName: "Artist",
      artworkURL: URL(string: "https://example.com/duplicate.jpg"),
    )
    let retainedItem = PlaybackItem(
      id: "retained",
      title: "Retained",
      artistName: "Artist",
      artworkURL: URL(string: "https://example.com/retained.jpg"),
    )
    let initialSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "engine-current", item: currentItem, viewID: "stable-current"),
        .init(id: "engine-duplicate", item: removedItem, viewID: "stable-duplicate"),
        .init(id: "engine-retained", item: retainedItem, viewID: "stable-retained"),
      ],
      currentEntryID: "engine-current",
      playStatus: .playing,
      progress: .zero,
    )
    let updatedSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "new-current", item: playbackItem("duplicate")),
        .init(id: "new-retained", item: playbackItem("retained")),
      ],
      currentEntryID: "new-current",
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
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return updatedSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.queueEntryRemoveRequested("stable-duplicate"))
    await store.finish()

    let updates = await recorder.upcomingUpdates
    expectNoDifference(
      updates.map { $0.map(\.viewID) },
      [["stable-retained"]],
    )
    expectNoDifference(store.state.session?.queue.entries.map(\.viewID), [
      "stable-current",
      "stable-retained",
    ])
    expectNoDifference(store.state.session?.queue.items.map(\.artworkURL), [
      currentItem.artworkURL,
      retainedItem.artworkURL,
    ])
  }

  @Test
  func crossingQueueBoundaryWithoutChangingOrderOnlyUpdatesRoles() async {
    let items = [
      playbackItem("current").withQueueRole(.context),
      playbackItem("queued-1").withQueueRole(.queued),
      playbackItem("queued-2").withQueueRole(.queued),
      playbackItem("context").withQueueRole(.context),
    ]
    let snapshot = playbackSnapshot(items: items)
    let cacheRecorder = PlaybackSessionCacheRecorder()
    let queueRecorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await queueRecorder.recordUpcomingUpdate(entries)
        return snapshot
      }
      $0.playbackSessionCache._save = { checkpoint in
        await cacheRecorder.record(checkpoint)
      }
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-1", "entry-2", "entry-3"],
      queuedEntryCount: 1,
    ))
    await store.finish()

    let updates = await queueRecorder.upcomingUpdates
    let checkpoint = await cacheRecorder.checkpoint
    #expect(updates.isEmpty)
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.role), [
      .queued,
      .context,
      .context,
    ])
    expectNoDifference(checkpoint?.queueRoles, [
      .context,
      .queued,
      .context,
      .context,
    ])
  }

  @Test
  func reorderUpcomingSendsCompleteTargetAndPreservesDisplayedMetadata() async {
    let items = [
      PlaybackItem(
        id: "track-1",
        title: "Track 1",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/track-1.jpg"),
      ),
      PlaybackItem(
        id: "track-2",
        title: "Track 2",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/track-2.jpg"),
      ),
      PlaybackItem(
        id: "track-3",
        title: "Track 3",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/track-3.jpg"),
      ),
    ]
    let initialSnapshot = playbackSnapshot(items: items)
    let updatedSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "new-current", item: playbackItem("track-1")),
        .init(id: "new-track-3", item: playbackItem("track-3")),
        .init(id: "new-track-2", item: playbackItem("track-2")),
      ],
      currentEntryID: "new-current",
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
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return updatedSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-2", "entry-1"],
      queuedEntryCount: 1,
    ))
    await store.finish()

    let updates = await recorder.upcomingUpdates
    expectNoDifference(
      updates.map { $0.map(\.viewID) },
      [["entry-2", "entry-1"]],
    )
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      "entry-2",
      "entry-1",
    ])
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.role), [
      .queued,
      .context,
    ])
    expectNoDifference(store.state.session?.queue.items.map(\.artworkURL), [
      items[0].artworkURL,
      items[2].artworkURL,
      items[1].artworkURL,
    ])
  }

  @Test
  func movingANonBoundaryContextItemQueuesOnlyThatOccurrence() async {
    let items = [
      playbackItem("current").withQueueRole(.context),
      playbackItem("queued-1").withQueueRole(.queued),
      playbackItem("queued-2").withQueueRole(.queued),
      playbackItem("context-1").withQueueRole(.context),
      playbackItem("context-2").withQueueRole(.context),
      playbackItem("context-3").withQueueRole(.context),
    ]
    let initialSnapshot = playbackSnapshot(items: items)
    let requestedViewIDs = ["entry-1", "entry-5", "entry-2", "entry-3", "entry-4"]
    let updatedSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "new-current", item: playbackItem("current")),
        .init(id: "new-queued-1", item: playbackItem("queued-1")),
        .init(id: "new-context-3", item: playbackItem("context-3")),
        .init(id: "new-queued-2", item: playbackItem("queued-2")),
        .init(id: "new-context-1", item: playbackItem("context-1")),
        .init(id: "new-context-2", item: playbackItem("context-2")),
      ],
      currentEntryID: "new-current",
      playStatus: .playing,
      progress: .zero,
    )
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { _ in updatedSnapshot }
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: requestedViewIDs,
      queuedEntryCount: 3,
    ))
    await store.finish()

    expectNoDifference(
      store.state.session?.queue.upcomingEntries.map(\.viewID),
      requestedViewIDs,
    )
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.role), [
      .queued,
      .queued,
      .queued,
      .context,
      .context,
    ])
  }

  @Test
  func staleSnapshotDoesNotUndoOptimisticQueueReorder() async {
    let items = [
      playbackItem("current").withQueueRole(.context),
      playbackItem("queued").withQueueRole(.queued),
      playbackItem("context").withQueueRole(.context),
    ]
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
    let gate = PlaybackStartGate()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { _ in
        try await gate.start()
        return updatedSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-2", "entry-1"],
      queuedEntryCount: 0,
    ))
    await gate.waitUntilFirstStartBegins()
    await store.send(.playbackEvent(.snapshotChanged(initialSnapshot)))

    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      "entry-2",
      "entry-1",
    ])
    expectNoDifference(store.state.pendingUpcomingViewIDs, ["entry-2", "entry-1"])

    await gate.releaseFirstStart()
    await store.receive(.playbackEvent(.snapshotChanged(updatedSnapshot)))
    await store.finish()

    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      "entry-2",
      "entry-1",
    ])
    #expect(store.state.pendingUpcomingViewIDs == nil)
  }

  @Test
  func refreshedMusicKitIDsDoNotConfirmAnIntermediateOrder() async {
    let items = [
      playbackItem("current").withQueueRole(.context),
      playbackItem("queued").withQueueRole(.queued),
      playbackItem("context").withQueueRole(.context),
    ]
    let initialSnapshot = playbackSnapshot(items: items)
    let intermediateSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "new-current", item: playbackItem("current")),
        .init(id: "new-queued", item: playbackItem("queued")),
        .init(id: "new-context", item: playbackItem("context")),
      ],
      currentEntryID: "new-current",
      playStatus: .playing,
      progress: .zero,
    )
    let updatedSnapshot = PlaybackSnapshot(
      entries: [
        intermediateSnapshot.entries[0],
        intermediateSnapshot.entries[2],
        intermediateSnapshot.entries[1],
      ],
      currentEntryID: intermediateSnapshot.currentEntryID,
      playStatus: .playing,
      progress: .zero,
    )
    let gate = PlaybackStartGate()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { _ in
        try await gate.start()
        return intermediateSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-2", "entry-1"],
      queuedEntryCount: 0,
    ))
    await gate.waitUntilFirstStartBegins()
    await gate.releaseFirstStart()
    await store.receive(.playbackEvent(.snapshotChanged(intermediateSnapshot)))

    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      "entry-2",
      "entry-1",
    ])
    expectNoDifference(store.state.pendingUpcomingViewIDs, ["entry-2", "entry-1"])

    await store.send(.playbackEvent(.snapshotChanged(updatedSnapshot)))

    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      "entry-2",
      "entry-1",
    ])
    #expect(store.state.pendingUpcomingViewIDs == nil)
  }

  @Test
  func boundaryChangeKeepsTheInFlightPhysicalOrderUpdate() async {
    let items = [
      playbackItem("current").withQueueRole(.context),
      playbackItem("queued").withQueueRole(.queued),
      playbackItem("context").withQueueRole(.context),
    ]
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
    let gate = PlaybackStartGate()
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        try await gate.start()
        return updatedSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-2", "entry-1"],
      queuedEntryCount: 0,
    ))
    await gate.waitUntilFirstStartBegins()
    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-2", "entry-1"],
      queuedEntryCount: 1,
    ))

    expectNoDifference(store.state.pendingUpcomingViewIDs, ["entry-2", "entry-1"])
    let updatesBeforeCompletion = await recorder.upcomingUpdates
    #expect(updatesBeforeCompletion.count == 1)

    await gate.releaseFirstStart()
    await store.receive(.playbackEvent(.snapshotChanged(updatedSnapshot)))
    await store.finish()

    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      "entry-2",
      "entry-1",
    ])
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.role), [
      .queued,
      .context,
    ])
  }

  @Test
  func newerReorderReplacesTheInFlightTarget() async {
    let items = [
      playbackItem("current"),
      playbackItem("first"),
      playbackItem("second"),
      playbackItem("third"),
    ]
    let initialSnapshot = playbackSnapshot(items: items)
    let gate = PlaybackStartGate()
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        try await gate.start()
        return PlaybackSnapshot(
          entries: [initialSnapshot.entries[0]] + entries,
          currentEntryID: initialSnapshot.currentEntryID,
          playStatus: .playing,
          progress: .zero,
        )
      }
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-3", "entry-1", "entry-2"],
      queuedEntryCount: 1,
    ))
    await gate.waitUntilFirstStartBegins()
    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-2", "entry-3", "entry-1"],
      queuedEntryCount: 2,
    ))
    await store.finish()

    let updates = await recorder.upcomingUpdates
    expectNoDifference(
      updates.map { $0.map(\.viewID) },
      [
        ["entry-3", "entry-1", "entry-2"],
        ["entry-2", "entry-3", "entry-1"],
      ],
    )
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      "entry-2",
      "entry-3",
      "entry-1",
    ])
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.role), [
      .queued,
      .queued,
      .context,
    ])
  }

  @Test
  func reorderRequiresEveryStableOccurrenceExactlyOnce() async {
    let snapshot = playbackSnapshot(items: [
      playbackItem("current"),
      playbackItem("first"),
      playbackItem("second"),
    ])
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:]),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return snapshot
      }
    }

    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-1", "entry-1"],
      queuedEntryCount: 1,
    ))
    await store.send(.reorderUpcoming(
      entryViewIDs: ["entry-1", "entry-2"],
      queuedEntryCount: 3,
    ))

    let updates = await recorder.upcomingUpdates
    #expect(updates.isEmpty)
  }

  @Test
  func playbackFailurePausesCurrentSessionAndShowsFailure() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in throw PlaybackClientError.musicAccessDenied }
    }

    let item = playbackItem("track-1")
    let contextItem = item.withQueueRole(.context)

    await store.send(.playNow(items: [item], startIndex: 0, context: nil)) {
      $0.pendingMetadataPlan = [
        PlaybackMetadataHintMatcher.Occurrence(item: contextItem),
      ]
      $0.pendingPlayNowItems = [contextItem]
      $0.session = .init(playStatus: .loading, currentItem: contextItem)
    }
    await store.receive(.playbackFailed(.init(failure: .musicAccessDenied))) {
      $0.failure = .musicAccessDenied
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.session?.playStatus = .paused
    }
  }

  @Test
  func revokedUserTokenSurfacesSignInRequiredWithPreservedDiagnostic() async {
    let diagnostic = PlaybackDiagnostic(summary: "tokenRequest.userTokenRevoked")
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in
        throw PlaybackClientError.appleMusicSignInRequired(diagnostic)
      }
    }

    let item = playbackItem("track-1")
    let contextItem = item.withQueueRole(.context)

    await store.send(.playNow(items: [item], startIndex: 0, context: nil)) {
      $0.pendingMetadataPlan = [
        PlaybackMetadataHintMatcher.Occurrence(item: contextItem),
      ]
      $0.pendingPlayNowItems = [contextItem]
      $0.session = .init(playStatus: .loading, currentItem: contextItem)
    }
    await store.receive(
      .playbackFailed(.init(failure: .appleMusicSignInRequired, diagnostic: diagnostic)),
    ) {
      $0.failure = .appleMusicSignInRequired
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.session?.playStatus = .paused
    }
  }

  @Test
  func signInRequiredLogDetailDistinguishesUnderlyingTokenError() {
    let notSignedIn = PlaybackFailureReport(
      failure: .appleMusicSignInRequired,
      diagnostic: .init(summary: "tokenRequest.userNotSignedIn"),
    )
    let revoked = PlaybackFailureReport(
      failure: .appleMusicSignInRequired,
      diagnostic: .init(summary: "tokenRequest.userTokenRevoked"),
    )

    #expect(notSignedIn.logDetail == "appleMusicSignInRequired tokenRequest.userNotSignedIn")
    #expect(revoked.logDetail == "appleMusicSignInRequired tokenRequest.userTokenRevoked")
    #expect(notSignedIn.failure.eventId == revoked.failure.eventId) // same event, different detail
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
      $0.pendingMetadataPlan = zip(
        checkpoint.songIDs,
        checkpoint.playlistSourceHints,
      ).map { songID, source in
        PlaybackMetadataHintMatcher.Occurrence(item: PlaybackItem(
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
      $0.pendingMetadataPlan = nil
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
  func confirmedApprovedTracksRemoveEveryRevokedUpcomingOccurrence() async {
    let current = playbackItem("current").withQueueRole(.context)
    let revoked = playbackItem("revoked").withQueueRole(.queued)
    let allowed = playbackItem("allowed").withQueueRole(.context)
    let initialSnapshot = playbackSnapshot(items: [current, revoked, allowed, revoked])
    let updatedSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "new-current", item: current.withQueueRole(nil)),
        .init(id: "new-allowed", item: allowed.withQueueRole(nil)),
      ],
      currentEntryID: "new-current",
      playStatus: .playing,
      progress: .zero,
    )
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    let cacheRecorder = PlaybackSessionCacheRecorder()
    let queueRecorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State()
    state.hasAuthoritativeSnapshot = true
    state.lastCachedProgressBucket = 0
    state.playbackContext = context
    state.session = PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:])
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await queueRecorder.recordUpcomingUpdate(entries)
        return updatedSnapshot
      }
      $0.playbackSessionCache._save = { checkpoint in
        await cacheRecorder.record(checkpoint)
      }
    }
    store.exhaustivity = .off

    await store.send(.approvedTrackIDsUpdated(["current", "allowed"]))
    await store.receive(.playbackEvent(.snapshotChanged(updatedSnapshot)))
    await store.finish()

    let updates = await queueRecorder.upcomingUpdates
    expectNoDifference(updates.map { $0.map(\.viewID) }, [["entry-2"]])
    expectNoDifference(store.state.session?.queue.entries.map(\.viewID), [
      "entry-0",
      "entry-2",
    ])
    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .context,
    ])
    expectNoDifference(store.state.playbackContext, context)
    let cachedCheckpoint = await cacheRecorder.checkpoint
    expectNoDifference(cachedCheckpoint?.songIDs, ["current", "allowed"])
    #expect(store.state.pendingUpcomingViewIDs == nil)
    #expect(!store.state.shouldClearPlaybackOnUpcomingUpdateFailure)
  }

  @Test
  func revokedPlayingTrackAdvancesToFirstApprovedOccurrence() async {
    let revoked = playbackItem("revoked").withQueueRole(.context)
    let queued = playbackItem("queued").withQueueRole(.queued)
    let contextItem = playbackItem("context").withQueueRole(.context)
    let revokedTail = playbackItem("revoked-tail").withQueueRole(.context)
    let progress = PlaybackProgress(elapsedTime: 42, duration: 180)
    let initialSnapshot = playbackSnapshot(
      items: [revoked, queued, contextItem, revokedTail],
      progress: progress,
    )
    let replacementSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: "new-queued", item: queued.withQueueRole(nil)),
        .init(id: "new-context", item: contextItem.withQueueRole(nil)),
      ],
      currentEntryID: "new-queued",
      playStatus: .playing,
      progress: .zero,
    )
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    let cacheRecorder = PlaybackSessionCacheRecorder()
    let queueRecorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State()
    state.hasAuthoritativeSnapshot = true
    state.lastCachedProgressBucket = 8
    state.playbackContext = context
    state.progress = progress
    state.session = PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:])
    state.sourceAlbumIDs = [
      "revoked": "revoked-album",
      "queued": "queued-album",
      "context": "context-album",
    ]
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.replaceQueue = { entries, shouldPlay in
        await queueRecorder.recordReplacement(entries, shouldPlay: shouldPlay)
        return replacementSnapshot
      }
      $0.playbackSessionCache._save = { checkpoint in
        await cacheRecorder.record(checkpoint)
      }
    }
    store.exhaustivity = .off

    await store.send(.approvedTrackIDsUpdated(["queued", "context"]))
    await store.receive(.playbackEvent(.snapshotChanged(replacementSnapshot)))
    await store.finish()

    let replacements = await queueRecorder.replacements
    expectNoDifference(replacements.map { $0.entries.map(\.viewID) }, [
      ["entry-1", "entry-2"],
    ])
    expectNoDifference(replacements.map(\.shouldPlay), [true])
    expectNoDifference(store.state.session?.currentTrackID, "queued")
    expectNoDifference(store.state.session?.queue.entries.map(\.viewID), [
      "entry-1",
      "entry-2",
    ])
    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .queued,
      .context,
    ])
    expectNoDifference(store.state.session?.playStatus, .playing)
    expectNoDifference(store.state.playbackContext, context)
    expectNoDifference(store.state.progress, .zero)
    #expect(store.state.sourceAlbumIDs["revoked"] == nil)
    let cachedCheckpoint = await cacheRecorder.checkpoint
    expectNoDifference(cachedCheckpoint?.songIDs, ["queued", "context"])
  }

  @Test
  func revokedPausedTrackAdvancesWithoutStartingPlayback() async {
    let revoked = playbackItem("revoked")
    let allowed = playbackItem("allowed")
    let initialSnapshot = playbackSnapshot(
      items: [revoked, allowed],
      playStatus: .paused,
    )
    let replacementSnapshot = playbackSnapshot(
      items: [allowed],
      playStatus: .paused,
    )
    let queueRecorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State()
    state.hasAuthoritativeSnapshot = true
    state.session = PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:])
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.replaceQueue = { entries, shouldPlay in
        await queueRecorder.recordReplacement(entries, shouldPlay: shouldPlay)
        return replacementSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.approvedTrackIDsUpdated(["allowed"]))
    await store.receive(.playbackEvent(.snapshotChanged(replacementSnapshot)))
    await store.finish()

    let replacements = await queueRecorder.replacements
    expectNoDifference(replacements.map(\.shouldPlay), [false])
    expectNoDifference(store.state.session?.currentTrackID, "allowed")
    expectNoDifference(store.state.session?.playStatus, .paused)
  }

  @Test
  func confirmedEmptyApprovalClearsPlaybackAndCheckpoint() async {
    let recorder = PlaybackCommandRecorder()
    var state = PlaybackFeature.State()
    state.hasAuthoritativeSnapshot = true
    state.session = .init(currentItem: playbackItem("revoked"))
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.clearQueue = {
        await recorder.recordClearQueue()
      }
      $0.playbackSessionCache._delete = {
        await recorder.recordDeleteCheckpoint()
      }
    }
    store.exhaustivity = .off

    await store.send(.approvedTrackIDsUpdated([]))
    await store.receive(.playbackEvent(.queueEnded))
    await store.finish()

    #expect(store.state.session == nil)
    #expect(store.state.approvedTrackIDs == [])
    #expect(await recorder.clearQueueCount == 1)
    #expect(await recorder.deleteCheckpointCount == 1)
  }

  @Test
  func approvedTracksFilterCheckpointBeforeRestoration() async {
    let source = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    let checkpoint = PlaybackCheckpoint(
      songIDs: ["revoked-current", "allowed", "revoked-tail"],
      currentIndex: 0,
      elapsedTime: 42,
      durationFallback: 180,
      sourceAlbumHints: [
        .init(songID: "revoked-current", albumID: "album"),
        .init(songID: "allowed", albumID: "album"),
      ],
      playlistSourceHints: [nil, source, nil],
      queueRoles: [.context, .queued, .context],
      context: context,
    )
    let restoredSnapshot = playbackSnapshot(
      items: [playbackItem("allowed")],
      playStatus: .paused,
    )
    let cacheRecorder = PlaybackSessionCacheRecorder()
    let restoreRecorder = PlaybackCheckpointRestoreRecorder()
    let store = TestStore(initialState: PlaybackFeature.State()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restoreQueue = { filteredCheckpoint in
        await restoreRecorder.record(filteredCheckpoint)
        return restoredSnapshot
      }
      $0.playbackSessionCache._load = { checkpoint }
      $0.playbackSessionCache._save = { filteredCheckpoint in
        await cacheRecorder.record(filteredCheckpoint)
      }
    }
    store.exhaustivity = .off

    await store.send(.approvedTrackIDsUpdated(["allowed"]))
    await store.send(.restoreCachedSession)
    await store.receive(.checkpointLoaded(checkpoint))
    await store.receive(.checkpointRestorationFinished(restoredSnapshot))
    await store.receive(.playbackEvent(.snapshotChanged(restoredSnapshot)))
    await store.finish()

    let restoredCheckpoint = await restoreRecorder.checkpoint
    let cachedCheckpoint = await cacheRecorder.checkpoint
    expectNoDifference(
      restoredCheckpoint,
      checkpoint.filtered(to: ["allowed"]),
    )
    expectNoDifference(cachedCheckpoint?.songIDs, ["allowed"])
    expectNoDifference(store.state.session?.currentTrackID, "allowed")
    expectNoDifference(store.state.session?.queue.currentEntry.role, .queued)
    #expect(store.state.playbackContext == nil)
  }

  @Test
  func failedApprovedUpcomingUpdateClearsPlayback() async {
    let recorder = PlaybackCommandRecorder()
    let snapshot = playbackSnapshot(items: [
      playbackItem("current"),
      playbackItem("revoked"),
    ])
    var state = PlaybackFeature.State()
    state.hasAuthoritativeSnapshot = true
    state.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.clearQueue = {
        await recorder.recordClearQueue()
      }
      $0.playback.setUpcoming = { _ in throw TestError() }
      $0.playbackSessionCache._delete = {
        await recorder.recordDeleteCheckpoint()
      }
    }
    store.exhaustivity = .off

    await store.send(.approvedTrackIDsUpdated(["current"]))
    await store.receive(.upcomingQueueUpdateFailed(
      expectedViewIDs: [],
      failure: .init(error: TestError()),
    ))
    await store.receive(.playbackEvent(.queueEnded))
    await store.finish()

    #expect(store.state.session == nil)
    #expect(await recorder.clearQueueCount == 1)
    #expect(await recorder.deleteCheckpointCount == 1)
  }

  @Test
  func failedRevokedCurrentReplacementClearsPlayback() async {
    let recorder = PlaybackCommandRecorder()
    let snapshot = playbackSnapshot(items: [
      playbackItem("revoked"),
      playbackItem("allowed"),
    ])
    var state = PlaybackFeature.State()
    state.hasAuthoritativeSnapshot = true
    state.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.clearQueue = {
        await recorder.recordClearQueue()
      }
      $0.playback.replaceQueue = { _, _ in throw TestError() }
      $0.playbackSessionCache._delete = {
        await recorder.recordDeleteCheckpoint()
      }
    }
    store.exhaustivity = .off

    await store.send(.approvedTrackIDsUpdated(["allowed"]))
    await store.receive(.queueReplacementFailed(
      expectedViewIDs: ["entry-1"],
      failure: .init(error: TestError()),
    ))
    await store.receive(.playbackEvent(.queueEnded))
    await store.finish()

    #expect(store.state.session == nil)
    #expect(await recorder.clearQueueCount == 1)
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
    var target: PlaybackQueueInsertionTarget
  }

  struct Replacement: Equatable {
    var entries: [PlaybackQueueEntry]
    var shouldPlay: Bool
  }

  var insertions: [Insertion] = []
  var replacements: [Replacement] = []
  var upcomingUpdates: [[PlaybackQueueEntry]] = []

  func recordInsertion(
    items: [PlaybackItem],
    target: PlaybackQueueInsertionTarget,
  ) -> Int {
    self.insertions.append(.init(items: items, target: target))
    return self.insertions.count
  }

  func recordReplacement(
    _ entries: [PlaybackQueueEntry],
    shouldPlay: Bool,
  ) {
    self.replacements.append(.init(entries: entries, shouldPlay: shouldPlay))
  }

  func recordUpcomingUpdate(_ entries: [PlaybackQueueEntry]) {
    self.upcomingUpdates.append(entries)
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
