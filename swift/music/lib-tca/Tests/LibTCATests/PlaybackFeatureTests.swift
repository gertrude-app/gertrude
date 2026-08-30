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
  func playbackModeButtonsEnforceMutualExclusivity() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.repeatButtonTapped) {
      $0.preferences.endBehavior = .loopCollection
    }
    await store.send(.repeatButtonTapped) {
      $0.preferences.endBehavior = .loopTrack
    }
    await store.send(.repeatButtonTapped) {
      $0.preferences.endBehavior = .finite
    }
    await store.send(.infiniteButtonTapped) {
      $0.preferences.endBehavior = .infinite
    }
    await store.send(.repeatButtonTapped) {
      $0.preferences.endBehavior = .loopCollection
    }
    await store.send(.infiniteButtonTapped) {
      $0.preferences.endBehavior = .infinite
    }
    await store.send(.infiniteButtonTapped) {
      $0.preferences.endBehavior = .finite
    }
    await store.send(.shuffleButtonTapped) {
      $0.preferences.isShuffleEnabled = true
    }
    await store.send(.shuffleButtonTapped) {
      $0.preferences.isShuffleEnabled = false
    }
  }

  @Test
  func activeInfiniteToggleCapsAndRestoresRemainingSourceQueue() async throws {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 13).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let source = PlaybackSource(items: items, selectedIndex: 0, context: nil)
    let currentEntry = PlaybackQueueEntry(
      id: "source-0",
      item: items[0].withQueueRole(.context),
      sourceEntryID: 0,
    )
    let explicitEntry = PlaybackQueueEntry(
      id: "explicit",
      item: items[0].withQueueRole(.queued),
      viewID: "explicit-view",
    )
    let sourceEntries = source.entries.dropFirst().map { entry in
      PlaybackQueueEntry(
        id: "source-\(entry.id)",
        item: entry.item.withQueueRole(.context),
        sourceEntryID: entry.id,
      )
    }
    let initialEntries = [currentEntry, explicitEntry] + sourceEntries
    let initialSnapshot = PlaybackSnapshot(
      entries: initialEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let enabledEntries = [currentEntry, explicitEntry] + Array(sourceEntries.prefix(10))
    let enabledSnapshot = PlaybackSnapshot(
      entries: enabledEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let disabledEntries = enabledEntries + [
      PlaybackQueueEntry(id: "restored-11", item: items[11]),
      PlaybackQueueEntry(id: "restored-12", item: items[12]),
    ]
    let disabledSnapshot = PlaybackSnapshot(
      entries: disabledEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let sourceAlbumIDs = Dictionary(
      uniqueKeysWithValues: items.map { ($0.id, album.id) },
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: sourceAlbumIDs,
    ))
    let recorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: session,
      hasAuthoritativeSnapshot: true,
      playbackSource: source,
      sourceAlbumIDs: sourceAlbumIDs,
    )
    state.recordMetadata(entries: initialEntries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return entries.count == 11 ? enabledSnapshot : disabledSnapshot
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.infiniteButtonTapped)

    #expect(store.state.preferences.endBehavior == .infinite)
    expectNoDifference(store.state.infinitePlaybackPlan, InfinitePlaybackPlan(
      remainingSourceEntryIDs: [11, 12],
      generatedItems: [],
    ))
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.sourceEntryID), [
      nil,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
    ])

    await store.receive(.playbackEvent(.snapshotChanged(enabledSnapshot)))
    await store.send(.infiniteButtonTapped)

    #expect(store.state.preferences.endBehavior == .finite)
    #expect(store.state.infinitePlaybackPlan == nil)

    await store.receive(.playbackEvent(.snapshotChanged(disabledSnapshot)))
    await store.finish()

    let updates = await recorder.upcomingUpdates
    expectNoDifference(updates.map { $0.map(\.sourceEntryID) }, [
      [nil, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
      [nil, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
    ])
    expectNoDifference(store.state.session?.queue.entries[1].viewID, explicitEntry.viewID)
    expectNoDifference(store.state.session?.queue.contextEntries.map(\.sourceEntryID), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
    ])
  }

  @Test
  func disablingInfiniteRemovesGeneratedRowsAndPreservesExplicitRows() async throws {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: [
        ApprovedTrack(id: "source", title: "Source", artistName: "Artist"),
        ApprovedTrack(id: "generated", title: "Generated", artistName: "Artist"),
      ],
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let source = PlaybackSource(items: [items[0]], selectedIndex: 0, context: nil)
    let currentEntry = PlaybackQueueEntry(
      id: "current",
      item: items[0].withQueueRole(.context),
      sourceEntryID: 0,
    )
    let explicitEntry = PlaybackQueueEntry(
      id: "explicit",
      item: items[0].withQueueRole(.queued),
      viewID: "explicit-view",
    )
    let generatedEntries = [
      PlaybackQueueEntry(
        id: "generated",
        item: items[1].withQueueRole(.context),
      ),
      PlaybackQueueEntry(
        id: "cycle",
        item: items[0].withQueueRole(.context),
      ),
    ]
    let initialSnapshot = PlaybackSnapshot(
      entries: [currentEntry, explicitEntry] + generatedEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let disabledSnapshot = PlaybackSnapshot(
      entries: [currentEntry, explicitEntry],
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: Dictionary(
        uniqueKeysWithValues: items.map { ($0.id, album.id) },
      ),
    ))
    var state = PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: session,
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [items[1]],
      ),
      playbackSource: source,
      preferences: .init(endBehavior: .infinite),
    )
    state.recordMetadata(entries: initialSnapshot.entries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { _ in disabledSnapshot }
    }
    store.exhaustivity = .off

    await store.send(.infiniteButtonTapped)
    await store.receive(.playbackEvent(.snapshotChanged(disabledSnapshot)))
    await store.finish()

    #expect(store.state.preferences.endBehavior == .finite)
    #expect(store.state.infinitePlaybackPlan == nil)
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.viewID), [
      explicitEntry.viewID,
    ])
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.role), [.queued])
  }

  @Test
  func restoresPlaybackPreferences() async {
    let preferences = PlaybackPreferences(
      endBehavior: .loopTrack,
      isShuffleEnabled: true,
    )
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setRepeatsCurrentEntry = { repeatsCurrentEntry in
        await recorder.recordSetRepeatsCurrentEntry(repeatsCurrentEntry)
      }
      $0.playbackPreferences.load = { preferences }
    }

    await store.send(.restorePlaybackPreferences)
    await store.receive(.playbackPreferencesLoaded(preferences)) {
      $0.preferences = preferences
    }
    await store.finish()

    let repeatCurrentEntryValues = await recorder.repeatCurrentEntryValues
    expectNoDifference(repeatCurrentEntryValues, [true])
  }

  @Test
  func repeatOneSynchronizesPlaybackClient() async {
    let recorder = PlaybackCommandRecorder()
    let enableStore = TestStore(initialState: .init(
      preferences: .init(endBehavior: .loopCollection),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setRepeatsCurrentEntry = { repeatsCurrentEntry in
        await recorder.recordSetRepeatsCurrentEntry(repeatsCurrentEntry)
      }
    }
    let disableStore = TestStore(initialState: .init(
      preferences: .init(endBehavior: .loopTrack),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setRepeatsCurrentEntry = { repeatsCurrentEntry in
        await recorder.recordSetRepeatsCurrentEntry(repeatsCurrentEntry)
      }
    }

    await enableStore.send(.repeatButtonTapped) {
      $0.preferences.endBehavior = .loopTrack
    }
    await enableStore.finish()
    await disableStore.send(.repeatButtonTapped) {
      $0.preferences.endBehavior = .finite
    }
    await disableStore.finish()

    let repeatCurrentEntryValues = await recorder.repeatCurrentEntryValues
    expectNoDifference(repeatCurrentEntryValues, [true, false])
  }

  @Test
  func unshuffledRepeatAllRestartsFullSourceWithoutExplicitEntries() async {
    let firstDuplicateSource = PlaylistPlaybackSource(
      playlistID: UUID(1),
      entryID: UUID(2),
    )
    let secondDuplicateSource = PlaylistPlaybackSource(
      playlistID: UUID(1),
      entryID: UUID(3),
    )
    let duplicate = playbackItem("duplicate")
    let sourceItems = [
      playbackItem("removed-prefix"),
      duplicate.withPlaylistSource(firstDuplicateSource),
      duplicate.withPlaylistSource(secondDuplicateSource),
      playbackItem("suffix"),
    ]
    let context = PlaybackContext(
      identity: .init(kind: .playlist, id: "playlist"),
      title: "Playlist",
    )
    var source = PlaybackSource(
      items: sourceItems,
      selectedIndex: 2,
      context: context,
    )
    source.remove(0)
    let finalSnapshot = PlaybackSnapshot(
      entries: [
        .init(
          id: "engine-selected",
          item: sourceItems[2].withQueueRole(.context),
          sourceEntryID: 2,
        ),
        .init(
          id: "engine-explicit",
          item: playbackItem("explicit").withQueueRole(.queued),
        ),
        .init(
          id: "engine-suffix",
          item: sourceItems[3].withQueueRole(.context),
          sourceEntryID: 3,
        ),
      ],
      currentEntryID: "engine-suffix",
      playStatus: .playing,
      progress: .init(elapsedTime: 180, duration: 180),
    )
    let restartedItems = sourceItems.dropFirst().map {
      $0.withQueueRole(.context)
    }
    let restartedSnapshot = playbackSnapshot(
      items: restartedItems.map { $0.withQueueRole(nil) },
    )
    let queueRecorder = PlaybackQueueRecorder()
    let commandRecorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: finalSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      playbackContext: context,
      playbackSource: source,
      preferences: .init(endBehavior: .loopCollection),
      progress: finalSnapshot.progress,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.clearQueue = {
        await commandRecorder.recordClearQueue()
      }
      $0.playback.playNow = { items, startIndex in
        await queueRecorder.record(items: items, startIndex: startIndex)
        return restartedSnapshot
      }
      $0.playbackSessionCache._delete = {
        await commandRecorder.recordDeleteCheckpoint()
      }
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.queueEnded))

    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [1, 2, 3])
    expectNoDifference(store.state.session?.queue.items, restartedItems)
    expectNoDifference(store.state.playbackSource, source)
    expectNoDifference(store.state.playbackContext, context)

    await store.receive(.playNowFinished(restartedSnapshot))
    await store.finish()

    let recordedItems = await queueRecorder.items
    let recordedStartIndex = await queueRecorder.startIndex
    expectNoDifference(recordedItems, restartedItems)
    expectNoDifference(recordedStartIndex, 0)
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [1, 2, 3])
    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .context,
      .context,
    ])
    #expect(await commandRecorder.clearQueueCount == 0)
    #expect(await commandRecorder.deleteCheckpointCount == 0)
  }

  @Test
  func infiniteQueueEndingRestartsWithAFullRollingLookahead() async {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 3).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let restartedItems = [items[2], items[0], items[1], items[2]].map {
      $0.withQueueRole(.context)
    }
    let snapshot = playbackSnapshot(items: restartedItems.map { $0.withQueueRole(nil) })
    let recorder = PlaybackQueueRecorder()
    let store = TestStore(initialState: PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: .init(currentItem: items[0].withQueueRole(.context)),
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [],
      ),
      preferences: .init(endBehavior: .infinite),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { playedItems, startIndex in
        await recorder.record(items: playedItems, startIndex: startIndex)
        return snapshot
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.queueEnded))

    expectNoDifference(store.state.session?.queue.items, restartedItems)
    expectNoDifference(store.state.infinitePlaybackPlan, InfinitePlaybackPlan(
      remainingSourceEntryIDs: [],
      generatedItems: [items[0], items[1]],
    ))

    await store.receive(.playNowFinished(snapshot))
    await store.finish()

    let recordedItems = await recorder.items
    let recordedStartIndex = await recorder.startIndex
    expectNoDifference(recordedItems, restartedItems)
    expectNoDifference(recordedStartIndex, 0)
  }

  @Test
  func shuffledRepeatAllUsesPreparedCycleOrder() async {
    let sourceItems = [
      playbackItem("first"),
      playbackItem("second"),
      playbackItem("third"),
    ]
    let source = PlaybackSource(
      items: sourceItems,
      selectedIndex: 0,
      context: nil,
    )
    let cycleEntryIDs = [1, 0, 2]
    let restartedItems = cycleEntryIDs.map {
      source.entries[$0].item.withQueueRole(.context)
    }
    let restartedSnapshot = playbackSnapshot(
      items: restartedItems.map { $0.withQueueRole(nil) },
    )
    let recorder = PlaybackQueueRecorder()
    let store = TestStore(initialState: .init(
      session: .init(
        queue: .init(
          items: [sourceItems[2].withQueueRole(.context)],
          sourceEntryIDs: [2],
        ),
      ),
      hasAuthoritativeSnapshot: true,
      pendingRepeatCycleEntryIDs: cycleEntryIDs,
      playbackSource: source,
      preferences: .init(
        endBehavior: .loopCollection,
        isShuffleEnabled: true,
      ),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { items, startIndex in
        await recorder.record(items: items, startIndex: startIndex)
        return restartedSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.queueEnded))
    await store.receive(.playNowFinished(restartedSnapshot))
    await store.finish()

    let recordedItems = await recorder.items
    expectNoDifference(recordedItems, restartedItems)
    expectNoDifference(
      store.state.session?.queue.entries.compactMap(\.sourceEntryID),
      cycleEntryIDs,
    )
  }

  @Test
  func shuffledRepeatAllPreparesNextCycleAtQueueBoundary() async throws {
    let sourceItems = (0 ..< 4).map { playbackItem("source-\($0)") }
    let source = PlaybackSource(
      items: sourceItems,
      selectedIndex: 0,
      context: nil,
    )
    let entries = source.entries.map { entry in
      PlaybackQueueEntry(
        id: "engine-\(entry.id)",
        item: entry.item.withQueueRole(.context),
        sourceEntryID: entry.id,
      )
    }
    let initialSnapshot = PlaybackSnapshot(
      entries: entries,
      currentEntryID: entries[2].id,
      playStatus: .playing,
      progress: .zero,
    )
    let finalSnapshot = PlaybackSnapshot(
      entries: entries,
      currentEntryID: entries[3].id,
      playStatus: .playing,
      progress: .zero,
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: [:],
    ))
    let store = TestStore(initialState: .init(
      session: session,
      hasAuthoritativeSnapshot: true,
      playbackSource: source,
      preferences: .init(
        endBehavior: .loopCollection,
        isShuffleEnabled: true,
      ),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.snapshotChanged(finalSnapshot)))
    await store.finish()

    let cycleEntryIDs = try #require(store.state.pendingRepeatCycleEntryIDs)
    expectNoDifference(Set(cycleEntryIDs), Set(source.entries.map(\.id)))
    #expect(cycleEntryIDs.count == source.entries.count)
    #expect(source.entries[cycleEntryIDs[0]].item.id != source.entries[3].item.id)
    expectNoDifference(
      store.state.repeatCollectionWrapEntry,
      source.entries[cycleEntryIDs[0]],
    )
  }

  @Test
  func unshuffledRepeatAllExposesFirstRetainedSourceAtQueueBoundary() {
    let sourceItems = (0 ..< 4).map { playbackItem("source-\($0)") }
    var source = PlaybackSource(
      items: sourceItems,
      selectedIndex: 2,
      context: nil,
    )
    source.remove(0)
    var state = PlaybackFeature.State(
      session: .init(
        queue: .init(
          items: [sourceItems[3].withQueueRole(.context)],
          sourceEntryIDs: [3],
        ),
      ),
      hasAuthoritativeSnapshot: true,
      playbackSource: source,
      preferences: .init(endBehavior: .loopCollection),
    )

    expectNoDifference(state.repeatCollectionWrapEntry, source.entries[1])

    state.preferences.isShuffleEnabled = true
    expectNoDifference(state.repeatCollectionWrapEntry, nil)

    state.pendingRepeatCycleEntryIDs = [2, 1, 3]
    expectNoDifference(state.repeatCollectionWrapEntry, source.entries[2])

    state.preferences.isShuffleEnabled = false
    state.pendingRepeatCycleEntryIDs = nil
    state.session = .init(
      queue: .init(
        items: sourceItems[2...].map { $0.withQueueRole(.context) },
        sourceEntryIDs: [2, 3],
      ),
    )
    expectNoDifference(state.repeatCollectionWrapEntry, nil)
  }

  @Test
  func playbackModeChangePersistsPreferences() async {
    let recorder = PlaybackPreferencesRecorder()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackPreferences.save = { preferences in
        await recorder.record(preferences)
      }
    }

    await store.send(.shuffleButtonTapped) {
      $0.preferences.isShuffleEnabled = true
    }
    await store.finish()

    let savedPreferences = await recorder.preferences
    expectNoDifference(
      savedPreferences,
      [.init(endBehavior: .finite, isShuffleEnabled: true)],
    )
  }

  @Test
  func shuffleToggleReplansOnlyTheActiveSourceQueue() async throws {
    let duplicate = playbackItem("duplicate")
    let sourceItems = [
      playbackItem("current"),
      duplicate,
      duplicate,
      playbackItem("last"),
    ]
    let source = PlaybackSource(
      items: sourceItems,
      selectedIndex: 0,
      context: nil,
    )
    let currentEntry = PlaybackQueueEntry(
      id: "engine-current",
      item: sourceItems[0].withQueueRole(.context),
      sourceEntryID: 0,
      viewID: "view-current",
    )
    let queuedEntries = [
      PlaybackQueueEntry(
        id: "engine-queued-1",
        item: playbackItem("queued-1").withQueueRole(.queued),
        viewID: "view-queued-1",
      ),
      PlaybackQueueEntry(
        id: "engine-queued-2",
        item: playbackItem("queued-2").withQueueRole(.queued),
        viewID: "view-queued-2",
      ),
    ]
    let contextEntries = source.entries.dropFirst().map { sourceEntry in
      PlaybackQueueEntry(
        id: "engine-source-\(sourceEntry.id)",
        item: sourceEntry.item.withQueueRole(.context),
        sourceEntryID: sourceEntry.id,
        viewID: "view-source-\(sourceEntry.id)",
      )
    }
    let progress = PlaybackProgress(elapsedTime: 42, duration: 180)
    let initialSnapshot = PlaybackSnapshot(
      entries: [currentEntry] + queuedEntries + contextEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: progress,
    )
    let shuffledUpcomingEntries = queuedEntries + [
      contextEntries[2],
      contextEntries[0],
      contextEntries[1],
    ]
    let orderedUpcomingEntries = queuedEntries + contextEntries
    let shuffledSnapshot = PlaybackSnapshot(
      entries: [currentEntry] + shuffledUpcomingEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: progress,
    )
    let orderedSnapshot = PlaybackSnapshot(
      entries: [currentEntry] + orderedUpcomingEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: progress,
    )
    let initialSession = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: [:],
    ))
    let preferencesRecorder = PlaybackPreferencesRecorder()
    let queueRecorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State(
      session: initialSession,
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 8,
      playbackSource: source,
      progress: progress,
    )
    state.recordMetadata(entries: initialSnapshot.entries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await queueRecorder.recordUpcomingUpdate(entries)
        return PlaybackSnapshot(
          entries: [currentEntry] + entries,
          currentEntryID: currentEntry.id,
          playStatus: .playing,
          progress: progress,
        )
      }
      $0.playbackPreferences.save = { preferences in
        await preferencesRecorder.record(preferences)
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }

    await store.send(.shuffleButtonTapped) {
      $0.pendingUpcomingViewIDs = shuffledUpcomingEntries.map(\.viewID)
      $0.preferences.isShuffleEnabled = true
      $0.session?.queue.entries = [currentEntry] + shuffledUpcomingEntries
    }
    await store.receive(.playbackEvent(.snapshotChanged(shuffledSnapshot))) {
      $0.pendingUpcomingViewIDs = nil
    }
    await store.send(.shuffleButtonTapped) {
      $0.pendingUpcomingViewIDs = orderedUpcomingEntries.map(\.viewID)
      $0.preferences.isShuffleEnabled = false
      $0.session?.queue.entries = [currentEntry] + orderedUpcomingEntries
    }
    await store.receive(.playbackEvent(.snapshotChanged(orderedSnapshot))) {
      $0.pendingUpcomingViewIDs = nil
    }
    await store.finish()

    let updates = await queueRecorder.upcomingUpdates
    expectNoDifference(updates.map { $0.map(\.id) }, [
      shuffledUpcomingEntries.map(\.id),
      orderedUpcomingEntries.map(\.id),
    ])
    expectNoDifference(updates.map { $0.map(\.viewID) }, [
      shuffledUpcomingEntries.map(\.viewID),
      orderedUpcomingEntries.map(\.viewID),
    ])
    expectNoDifference(updates.map { $0.map(\.sourceEntryID) }, [
      shuffledUpcomingEntries.map(\.sourceEntryID),
      orderedUpcomingEntries.map(\.sourceEntryID),
    ])
    expectNoDifference(store.state.session?.queue.currentEntry, currentEntry)
    expectNoDifference(store.state.progress, progress)
    let savedPreferences = await preferencesRecorder.preferences
    expectNoDifference(savedPreferences, [
      .init(endBehavior: .finite, isShuffleEnabled: true),
      .init(endBehavior: .finite, isShuffleEnabled: false),
    ])
  }

  @Test
  func shuffleSnapshotPreservesOccurrencesWhenEngineReusesDuplicateIDs() async throws {
    let currentArtworkURL = URL(string: "https://example.com/current.jpg")!
    let explicitArtworkURL = URL(string: "https://example.com/explicit.jpg")!
    let sourceArtworkURL = URL(string: "https://example.com/source.jpg")!
    let lastArtworkURL = URL(string: "https://example.com/last.jpg")!
    let currentItem = PlaybackItem(
      id: "duplicate",
      title: "Current",
      artistName: "Artist",
      artworkURL: currentArtworkURL,
    )
    let sourceItem = PlaybackItem(
      id: "duplicate",
      title: "Source duplicate",
      artistName: "Artist",
      artworkURL: sourceArtworkURL,
    )
    let lastItem = PlaybackItem(
      id: "last",
      title: "Last",
      artistName: "Artist",
      artworkURL: lastArtworkURL,
    )
    let source = PlaybackSource(
      items: [currentItem, sourceItem, lastItem],
      selectedIndex: 0,
      context: nil,
    )
    let currentEntry = PlaybackQueueEntry(
      id: "engine-current",
      item: currentItem.withQueueRole(.context),
      sourceEntryID: 0,
      viewID: "view-current",
    )
    let explicitEntry = PlaybackQueueEntry(
      id: "engine-explicit",
      item: PlaybackItem(
        id: "duplicate",
        title: "Explicit duplicate",
        artistName: "Artist",
        artworkURL: explicitArtworkURL,
        queueRole: .queued,
      ),
      viewID: "view-explicit",
    )
    let sourceEntry = PlaybackQueueEntry(
      id: "engine-source",
      item: sourceItem.withQueueRole(.context),
      sourceEntryID: 1,
      viewID: "view-source",
    )
    let lastEntry = PlaybackQueueEntry(
      id: "engine-last",
      item: lastItem.withQueueRole(.context),
      sourceEntryID: 2,
      viewID: "view-last",
    )
    let initialEntries = [currentEntry, explicitEntry, sourceEntry, lastEntry]
    let initialSnapshot = PlaybackSnapshot(
      entries: initialEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let shuffledSnapshot = PlaybackSnapshot(
      entries: [
        .init(id: sourceEntry.id, item: playbackItem("duplicate")),
        .init(id: currentEntry.id, item: playbackItem("duplicate")),
        .init(id: lastEntry.id, item: playbackItem("last")),
        .init(id: explicitEntry.id, item: playbackItem("duplicate")),
      ],
      currentEntryID: sourceEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let clearedSnapshot = PlaybackSnapshot(
      entries: [
        shuffledSnapshot.entries[0],
        shuffledSnapshot.entries[2],
        shuffledSnapshot.entries[3],
      ],
      currentEntryID: sourceEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: [:],
    ))
    var state = PlaybackFeature.State(
      session: session,
      hasAuthoritativeSnapshot: true,
      playbackSource: source,
    )
    state.recordMetadata(entries: initialEntries)
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return entries.count == 3 ? shuffledSnapshot : clearedSnapshot
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.shuffleButtonTapped)
    await store.receive(.playbackEvent(.snapshotChanged(shuffledSnapshot)))

    expectNoDifference(store.state.session?.queue.entries.map(\.viewID), [
      currentEntry.viewID,
      explicitEntry.viewID,
      lastEntry.viewID,
      sourceEntry.viewID,
    ])
    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .queued,
      .context,
      .context,
    ])
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [
      0,
      nil,
      2,
      1,
    ])
    expectNoDifference(store.state.session?.queue.items.map(\.artworkURL), [
      currentArtworkURL,
      explicitArtworkURL,
      lastArtworkURL,
      sourceArtworkURL,
    ])
    expectNoDifference(store.state.session?.queue.queuedEntries.map(\.viewID), [
      explicitEntry.viewID,
    ])

    await store.send(.clearQueueButtonTapped)
    await store.receive(.playbackEvent(.snapshotChanged(clearedSnapshot)))
    await store.finish()

    expectNoDifference(store.state.session?.queue.queuedEntries, [])
    expectNoDifference(store.state.session?.queue.contextEntries.map(\.viewID), [
      lastEntry.viewID,
      sourceEntry.viewID,
    ])
    let updates = await recorder.upcomingUpdates
    expectNoDifference(updates.map { $0.map(\.viewID) }, [
      [explicitEntry.viewID, lastEntry.viewID, sourceEntry.viewID],
      [lastEntry.viewID, sourceEntry.viewID],
    ])
  }

  @Test
  func infiniteShuffleReplansVisibleAndStoredSourceOccurrences() async throws {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 13).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let source = PlaybackSource(items: items, selectedIndex: 0, context: nil)
    let currentEntry = PlaybackQueueEntry(
      id: "source-0",
      item: items[0].withQueueRole(.context),
      sourceEntryID: 0,
    )
    let explicitEntry = PlaybackQueueEntry(
      id: "explicit",
      item: items[0].withQueueRole(.queued),
      viewID: "explicit-view",
    )
    let visibleSourceEntries = source.entries[1 ... 10].map { entry in
      PlaybackQueueEntry(
        id: "source-\(entry.id)",
        item: entry.item.withQueueRole(.context),
        sourceEntryID: entry.id,
      )
    }
    let initialEntries = [currentEntry, explicitEntry] + visibleSourceEntries
    let initialSnapshot = PlaybackSnapshot(
      entries: initialEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let shuffledSourceEntryIDs = [12] + Array(1 ... 9)
    let shuffledSnapshot = PlaybackSnapshot(
      entries: [currentEntry, explicitEntry] + shuffledSourceEntryIDs.map { entryID in
        PlaybackQueueEntry(
          id: "shuffled-\(entryID)",
          item: items[entryID],
        )
      },
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let orderedSnapshot = PlaybackSnapshot(
      entries: [currentEntry, explicitEntry] + (1 ... 10).map { entryID in
        PlaybackQueueEntry(
          id: "ordered-\(entryID)",
          item: items[entryID],
        )
      },
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let sourceAlbumIDs = Dictionary(
      uniqueKeysWithValues: items.map { ($0.id, album.id) },
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: sourceAlbumIDs,
    ))
    let recorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: session,
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [11, 12],
        generatedItems: [],
      ),
      playbackSource: source,
      preferences: .init(endBehavior: .infinite),
      sourceAlbumIDs: sourceAlbumIDs,
    )
    state.recordMetadata(entries: initialEntries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return entries.compactMap(\.sourceEntryID).first == 12
          ? shuffledSnapshot
          : orderedSnapshot
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.shuffleButtonTapped)

    expectNoDifference(store.state.session?.queue.contextEntries.map(\.sourceEntryID), [
      12,
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
    ])
    expectNoDifference(store.state.infinitePlaybackPlan?.remainingSourceEntryIDs, [10, 11])

    await store.receive(.playbackEvent(.snapshotChanged(shuffledSnapshot)))
    await store.send(.shuffleButtonTapped)

    expectNoDifference(store.state.session?.queue.contextEntries.map(\.sourceEntryID), [
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
    ])
    expectNoDifference(store.state.infinitePlaybackPlan?.remainingSourceEntryIDs, [11, 12])

    await store.receive(.playbackEvent(.snapshotChanged(orderedSnapshot)))
    await store.finish()

    #expect(!store.state.preferences.isShuffleEnabled)
    expectNoDifference(store.state.session?.queue.entries[1].viewID, explicitEntry.viewID)
    let updates = await recorder.upcomingUpdates
    expectNoDifference(updates.map { $0.compactMap(\.sourceEntryID) }, [
      shuffledSourceEntryIDs,
      Array(1 ... 10),
    ])
  }

  @Test
  func playbackSourceRetainsFullCollectionAndOccurrenceIdentity() {
    let duplicate = playbackItem("duplicate")
    let context = PlaybackContext(
      identity: .init(kind: .playlist, id: "playlist"),
      title: "Playlist",
    )
    var source = PlaybackSource(
      items: [playbackItem("first"), duplicate, duplicate],
      selectedIndex: 1,
      context: context,
    )

    source.remove(2)
    source.removeTracks(notIn: ["duplicate"])

    expectNoDifference(source.entries.map(\.id), [0, 1, 2])
    expectNoDifference(source.entries.map(\.item.id), ["first", "duplicate", "duplicate"])
    expectNoDifference(source.selectedEntryID, 1)
    expectNoDifference(source.context, context)
    expectNoDifference(source.removedEntryIDs, [0, 2])
    expectNoDifference(source.artistNames, ["Artist"])
    #expect(source.isValid)
  }

  @Test
  func infiniteQueueContextTransitionsFromSourceToInfinitePlay() {
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    var state = PlaybackFeature.State(
      session: .init(queue: .init(
        items: [
          playbackItem("current").withQueueRole(.context),
          playbackItem("source").withQueueRole(.context),
        ],
        sourceEntryIDs: [0, 1],
      )),
      playbackContext: context,
      preferences: .init(endBehavior: .infinite),
    )

    expectNoDifference(state.queueContextTitle, "Album")
    expectNoDifference(state.activePlaybackContext, context)

    state.session = .init(queue: .init(items: [
      playbackItem("generated-current").withQueueRole(.context),
      playbackItem("generated-next").withQueueRole(.context),
    ]))

    expectNoDifference(state.queueContextTitle, "Infinite Play")
    expectNoDifference(state.activePlaybackContext, nil)
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
    let playbackSource = PlaybackSource(
      items: items,
      selectedIndex: 1,
      context: context,
    )
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .context,
    ]
    let sourceEntryIDHints = ["entry-0": 1, "entry-1": 2]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playNow(
      items: items,
      start: .selectedEntry(index: 1),
      context: context,
    )) {
      $0.pendingMetadataPlan = zip(requestedItems, [1, 2]).map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0, sourceEntryID: $1)
      }
      $0.pendingPlayNowItems = requestedItems
      $0.playbackContext = context
      $0.playbackSource = playbackSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: requestedItems, sourceEntryIDs: [1, 2]),
      )
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.sourceEntryIDHints = sourceEntryIDHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
        sourceEntryIDHints: sourceEntryIDHints,
      )
    }
  }

  @Test
  func playNowWhileInfiniteProjectsInitialLookaheadAndRetainsRemainder() async throws {
    let sourceAlbum = ApprovedAlbum(
      id: "source-album",
      title: "Source Album",
      artistName: "Artist",
      tracks: [
        ApprovedTrack(id: "source-0", title: "Source 0", artistName: "Artist"),
        ApprovedTrack(id: "source-1", title: "Source 1", artistName: "Artist"),
        ApprovedTrack(id: "source-2", title: "Source 2", artistName: "Artist"),
      ],
    )
    let relatedAlbum = ApprovedAlbum(
      id: "related-album",
      title: "Related Album",
      artistName: "Artist",
      tracks: [
        ApprovedTrack(id: "related", title: "Related", artistName: "Artist"),
      ],
    )
    let otherAlbum = ApprovedAlbum(
      id: "other-album",
      title: "Other Album",
      artistName: "Other Artist",
      tracks: [
        ApprovedTrack(id: "other", title: "Other", artistName: "Other Artist"),
      ],
    )
    let library = ApprovedMusicLibrary(albums: [sourceAlbum, relatedAlbum, otherAlbum])
    let sourceItems = playbackItems(album: sourceAlbum)
    let relatedItem = playbackItems(album: relatedAlbum)[0]
    let otherItem = playbackItems(album: otherAlbum)[0]
    let explicitEntry = PlaybackQueueEntry(
      id: "explicit-entry",
      item: sourceItems[0].withQueueRole(.queued),
      viewID: "explicit-view",
    )
    let existingCurrentEntry = PlaybackQueueEntry(
      id: "existing-current",
      item: sourceItems[0].withQueueRole(.context),
      sourceEntryID: 0,
      viewID: "existing-current-view",
    )
    let existingQueue = try #require(PlaybackFeature.Queue(
      entries: [existingCurrentEntry, explicitEntry],
      currentEntryID: existingCurrentEntry.id,
    ))
    let composedItems = [
      sourceItems[1].withQueueRole(.context),
      explicitEntry.item,
      sourceItems[2].withQueueRole(.context),
      sourceItems[0].withQueueRole(.context),
      relatedItem.withQueueRole(.context),
      otherItem.withQueueRole(.context),
      sourceItems[1].withQueueRole(.context),
    ]
    let snapshot = playbackSnapshot(items: composedItems.map { $0.withQueueRole(nil) })
    let recorder = PlaybackQueueRecorder()
    let store = TestStore(initialState: PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: .init(queue: existingQueue),
      hasAuthoritativeSnapshot: true,
      preferences: .init(endBehavior: .infinite),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { items, startIndex in
        await recorder.record(items: items, startIndex: startIndex)
        return snapshot
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.playNow(
      items: sourceItems,
      start: .selectedEntry(index: 1),
      context: nil,
    ))

    expectNoDifference(store.state.infinitePlaybackPlan, InfinitePlaybackPlan(
      remainingSourceEntryIDs: [],
      generatedItems: [
        otherItem,
        sourceItems[0],
        sourceItems[2],
        relatedItem,
      ],
    ))
    expectNoDifference(store.state.session?.queue.items, composedItems)
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [
      1,
      nil,
      2,
      0,
      nil,
      nil,
      nil,
    ])
    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .queued,
      .context,
      .context,
      .context,
      .context,
      .context,
    ])
    expectNoDifference(store.state.session?.queue.entries[1], explicitEntry)

    await store.receive(.playNowFinished(snapshot))
    await store.finish()

    let recordedItems = await recorder.items
    let recordedStartIndex = await recorder.startIndex
    expectNoDifference(recordedItems, composedItems)
    expectNoDifference(recordedStartIndex, 0)
    expectNoDifference(store.state.session?.queue.entries[1].viewID, explicitEntry.viewID)
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [
      1,
      nil,
      2,
      0,
      nil,
      nil,
      nil,
    ])
  }

  @Test
  func infiniteSnapshotAdvancementAppendsPreparedSourceAndGeneratedRows() async throws {
    let artworkURL = URL(string: "https://example.com/album.jpg")!
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      artworkURL: artworkURL,
      tracks: (0 ..< 13).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let sourceItems = Array(items.prefix(12))
    let source = PlaybackSource(
      items: sourceItems,
      selectedIndex: 0,
      context: nil,
    )
    let explicitEntry = PlaybackQueueEntry(
      id: "explicit",
      item: playbackItem("explicit").withQueueRole(.queued),
      viewID: "explicit-view",
    )
    let visibleSourceEntries = source.entries.prefix(11).map { entry in
      PlaybackQueueEntry(
        id: "source-\(entry.id)",
        item: entry.item.withQueueRole(.context),
        sourceEntryID: entry.id,
      )
    }
    let initialEntries = [visibleSourceEntries[0], explicitEntry]
      + visibleSourceEntries.dropFirst()
    let initialSnapshot = PlaybackSnapshot(
      entries: initialEntries,
      currentEntryID: visibleSourceEntries[0].id,
      playStatus: .playing,
      progress: .zero,
    )
    let firstAdvancedSnapshot = PlaybackSnapshot(
      entries: initialEntries,
      currentEntryID: visibleSourceEntries[1].id,
      playStatus: .playing,
      progress: .zero,
    )
    let insertedSourceEntry = PlaybackQueueEntry(
      id: "inserted-source",
      item: playbackItem(sourceItems[11].id),
    )
    let firstInsertedSnapshot = PlaybackSnapshot(
      entries: Array(initialEntries.dropFirst()) + [insertedSourceEntry],
      currentEntryID: visibleSourceEntries[1].id,
      playStatus: .playing,
      progress: .zero,
    )
    let secondAdvancedSnapshot = PlaybackSnapshot(
      entries: firstInsertedSnapshot.entries,
      currentEntryID: visibleSourceEntries[2].id,
      playStatus: .playing,
      progress: .zero,
    )
    let insertedGeneratedEntry = PlaybackQueueEntry(
      id: "inserted-generated",
      item: playbackItem(items[12].id),
    )
    let secondInsertedSnapshot = PlaybackSnapshot(
      entries: firstInsertedSnapshot.entries + [insertedGeneratedEntry],
      currentEntryID: visibleSourceEntries[2].id,
      playStatus: .playing,
      progress: .zero,
    )
    let sourceAlbumIDs = Dictionary(
      uniqueKeysWithValues: items.map { ($0.id, album.id) },
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: sourceAlbumIDs,
    ))
    var state = PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: session,
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [11],
        generatedItems: [items[12]],
      ),
      playbackSource: source,
      preferences: .init(endBehavior: .infinite),
      sourceAlbumIDs: sourceAlbumIDs,
    )
    state.recordMetadata(entries: initialEntries)
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { insertedItems, target in
        let insertionNumber = await recorder.recordInsertion(
          items: insertedItems,
          target: target,
        )
        return insertionNumber == 1
          ? firstInsertedSnapshot
          : secondInsertedSnapshot
      }
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.snapshotChanged(firstAdvancedSnapshot)))

    expectNoDifference(
      store.state.pendingInfiniteLookaheadInsertion,
      PlaybackFeature.InfiniteLookaheadInsertion(
        entries: [.source(source.entries[11])],
        remainingPlan: .init(
          remainingSourceEntryIDs: [],
          generatedItems: [items[12]],
        ),
      ),
    )
    expectNoDifference(store.state.infinitePlaybackPlan, InfinitePlaybackPlan(
      remainingSourceEntryIDs: [11],
      generatedItems: [items[12]],
    ))

    await store.receive(.infiniteLookaheadInsertionFinished(firstInsertedSnapshot))

    expectNoDifference(store.state.infinitePlaybackPlan, InfinitePlaybackPlan(
      remainingSourceEntryIDs: [],
      generatedItems: [items[12]],
    ))
    expectNoDifference(store.state.session?.queue.entries.last?.sourceEntryID, 11)
    expectNoDifference(store.state.session?.queue.entries.last?.item.artworkURL, artworkURL)

    await store.send(.playbackEvent(.snapshotChanged(secondAdvancedSnapshot)))

    expectNoDifference(
      store.state.pendingInfiniteLookaheadInsertion,
      PlaybackFeature.InfiniteLookaheadInsertion(
        entries: [.generated(items[12])],
        remainingPlan: .init(
          remainingSourceEntryIDs: [],
          generatedItems: [],
        ),
      ),
    )

    await store.receive(.infiniteLookaheadInsertionFinished(secondInsertedSnapshot))
    await store.finish()

    let insertions = await recorder.insertions
    expectNoDifference(insertions.map(\.items), [
      [sourceItems[11].withQueueRole(.context)],
      [items[12].withQueueRole(.context)],
    ])
    expectNoDifference(insertions.map(\.target), [.tail, .tail])
    expectNoDifference(store.state.infinitePlaybackPlan, InfinitePlaybackPlan(
      remainingSourceEntryIDs: [],
      generatedItems: [],
    ))
    expectNoDifference(
      store.state.session?.queue.upcomingEntries.count { $0.role == .context },
      10,
    )
    expectNoDifference(store.state.session?.queue.entries.last?.sourceEntryID, nil)
    expectNoDifference(store.state.session?.queue.entries.last?.role, .context)
    expectNoDifference(store.state.session?.queue.entries.suffix(2).map(\.item.artworkURL), [
      artworkURL,
      artworkURL,
    ])
    expectNoDifference(store.state.session?.queue.entries.first?.viewID, explicitEntry.viewID)
  }

  @Test
  func infiniteAdvancementStartsAndRetainsAFreshLibraryCycle() async throws {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 4).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let entries = [items[0], items[1], items[2], items[3], items[0]].enumerated().map {
      index, item in
      PlaybackQueueEntry(
        id: "entry-\(index)",
        item: item.withQueueRole(.context),
      )
    }
    let initialSnapshot = PlaybackSnapshot(
      entries: entries,
      currentEntryID: entries[0].id,
      playStatus: .playing,
      progress: .zero,
    )
    let advancedSnapshot = PlaybackSnapshot(
      entries: entries,
      currentEntryID: entries[1].id,
      playStatus: .playing,
      progress: .zero,
    )
    let insertedEntry = PlaybackQueueEntry(
      id: "inserted",
      item: items[1],
    )
    let insertedSnapshot = PlaybackSnapshot(
      entries: entries + [insertedEntry],
      currentEntryID: entries[1].id,
      playStatus: .playing,
      progress: .zero,
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: Dictionary(
        uniqueKeysWithValues: items.map { ($0.id, album.id) },
      ),
    ))
    let recorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: session,
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [],
      ),
      preferences: .init(endBehavior: .infinite),
    )
    state.recordMetadata(entries: entries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { insertedItems, target in
        _ = await recorder.recordInsertion(items: insertedItems, target: target)
        return insertedSnapshot
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.snapshotChanged(advancedSnapshot)))

    expectNoDifference(
      store.state.pendingInfiniteLookaheadInsertion?.entries.map(\.item.id),
      [items[1].id],
    )
    expectNoDifference(
      store.state.pendingInfiniteLookaheadInsertion?.remainingPlan.generatedItems.map(\.id),
      [items[3].id, items[0].id, items[2].id],
    )

    await store.receive(.infiniteLookaheadInsertionFinished(insertedSnapshot))
    await store.finish()

    let insertions = await recorder.insertions
    expectNoDifference(insertions.map(\.items), [[items[1].withQueueRole(.context)]])
    expectNoDifference(store.state.infinitePlaybackPlan?.generatedItems.map(\.id), [
      items[3].id,
      items[0].id,
      items[2].id,
    ])
  }

  @Test
  func infiniteQueueRemovalRefillsFromTheStoredPlan() async throws {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      tracks: (0 ..< 5).map {
        ApprovedTrack(id: "track-\($0)", title: "Track \($0)", artistName: "Artist")
      },
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let entries = [items[0], items[1], items[2], items[3], items[4], items[0]]
      .enumerated().map { index, item in
        PlaybackQueueEntry(
          id: "entry-\(index)",
          item: item.withQueueRole(.context),
        )
      }
    let initialSnapshot = PlaybackSnapshot(
      entries: entries,
      currentEntryID: entries[0].id,
      playStatus: .playing,
      progress: .zero,
    )
    let retainedEntries = entries.filter { $0.id != entries[2].id }
    let removedSnapshot = PlaybackSnapshot(
      entries: retainedEntries,
      currentEntryID: entries[0].id,
      playStatus: .playing,
      progress: .zero,
    )
    let insertedEntry = PlaybackQueueEntry(id: "inserted", item: items[1])
    let insertedSnapshot = PlaybackSnapshot(
      entries: retainedEntries + [insertedEntry],
      currentEntryID: entries[0].id,
      playStatus: .playing,
      progress: .zero,
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: Dictionary(
        uniqueKeysWithValues: items.map { ($0.id, album.id) },
      ),
    ))
    var state = PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      session: session,
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [items[1]],
      ),
      preferences: .init(endBehavior: .infinite),
    )
    state.recordMetadata(entries: entries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { _, _ in insertedSnapshot }
      $0.playback.setUpcoming = { _ in removedSnapshot }
    }
    store.exhaustivity = .off

    await store.send(.queueEntryRemoveRequested(entries[2].viewID))
    await store.receive(.playbackEvent(.snapshotChanged(removedSnapshot)))

    expectNoDifference(
      store.state.pendingInfiniteLookaheadInsertion?.entries.map(\.item.id),
      [items[1].id],
    )

    await store.receive(.infiniteLookaheadInsertionFinished(insertedSnapshot))
    await store.finish()

    expectNoDifference(store.state.infinitePlaybackPlan?.generatedItems, [])
    expectNoDifference(
      store.state.session?.queue.upcomingEntries.count { $0.role == .context },
      5,
    )
  }

  @Test
  func selectedEntryShuffleIncludesPrefixAndPreservesQueuedItems() async {
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
      requestedItems[0].withQueueRole(.context),
    ]
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "new-album"),
      title: "New Album",
    )
    let composedSnapshot = playbackSnapshot(items: composedItems.map { $0.withQueueRole(nil) })
    let playbackSource = PlaybackSource(
      items: requestedItems,
      selectedIndex: 1,
      context: context,
    )
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .queued,
      "entry-2": .context,
      "entry-3": .context,
    ]
    let sourceEntryIDHints = ["entry-0": 1, "entry-2": 2, "entry-3": 0]
    let recorder = PlaybackQueueRecorder()
    let store = TestStore(initialState: .init(
      session: .init(queue: .init(items: existingItems)),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
      preferences: .init(isShuffleEnabled: true),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { items, startIndex in
        await recorder.record(items: items, startIndex: startIndex)
        return composedSnapshot
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }

    await store.send(.playNow(
      items: requestedItems,
      start: .selectedEntry(index: 1),
      context: context,
    )) {
      $0.hasAuthoritativeSnapshot = false
      $0.lastCachedProgressBucket = nil
      $0.pendingMetadataPlan = [
        .init(item: composedItems[0], sourceEntryID: 1),
        .init(item: composedItems[1], retainedEntryID: "pending:1:queued"),
        .init(item: composedItems[2], sourceEntryID: 2),
        .init(item: composedItems[3], sourceEntryID: 0),
      ]
      $0.pendingPlayNowItems = composedItems
      $0.playbackContext = context
      $0.playbackSource = playbackSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: composedItems, sourceEntryIDs: [1, nil, 2, 0]),
      )
    }
    await store.receive(.playNowFinished(composedSnapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.sourceEntryIDHints = sourceEntryIDHints
      $0.session = PlaybackFeature.Session(
        snapshot: composedSnapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
        sourceEntryIDHints: sourceEntryIDHints,
      )
    }

    let recordedItems = await recorder.items
    let recordedStartIndex = await recorder.startIndex
    expectNoDifference(recordedItems, composedItems)
    expectNoDifference(recordedStartIndex, 0)
  }

  @Test
  func collectionShufflePreservesDuplicateOccurrences() async {
    let duplicate = playbackItem("duplicate")
    let requestedItems = [playbackItem("first"), duplicate, duplicate]
    let library = ApprovedMusicLibrary(albums: [
      ApprovedAlbum(
        id: "album",
        title: "Album",
        artistName: "Artist",
        tracks: [
          ApprovedTrack(id: "first", title: "First", artistName: "Artist"),
          ApprovedTrack(id: "duplicate", title: "Duplicate", artistName: "Artist"),
        ],
      ),
    ])
    let composedItems = [requestedItems[2], requestedItems[0], requestedItems[1]].map {
      $0.withQueueRole(.context)
    }
    let snapshot = playbackSnapshot(items: composedItems.map { $0.withQueueRole(nil) })
    let playbackSource = PlaybackSource(
      items: requestedItems,
      selectedIndex: 0,
      context: nil,
    )
    let roleHints = Dictionary(
      uniqueKeysWithValues: snapshot.entries.map { ($0.id, PlaybackQueueRole.context) },
    )
    let sourceEntryIDHints = ["entry-0": 2, "entry-1": 0, "entry-2": 1]
    let store = TestStore(initialState: .init(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      preferences: .init(endBehavior: .infinite, isShuffleEnabled: true),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }

    await store.send(.playNow(
      items: requestedItems,
      start: .collection,
      context: nil,
    )) {
      $0.infinitePlaybackPlan = .init(
        remainingSourceEntryIDs: [],
        generatedItems: [],
      )
      $0.pendingMetadataPlan = zip(composedItems, [2, 0, 1]).map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0, sourceEntryID: $1)
      }
      $0.pendingPlayNowItems = composedItems
      $0.playbackSource = playbackSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: composedItems, sourceEntryIDs: [2, 0, 1]),
      )
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.sourceEntryIDHints = sourceEntryIDHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
        sourceEntryIDHints: sourceEntryIDHints,
      )
    }

    expectNoDifference(store.state.session?.queue.items, composedItems)
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [2, 0, 1])
    expectNoDifference(store.state.playbackSource?.entries.map(\.id), [0, 1, 2])
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
    let playbackSource = PlaybackSource(
      items: items,
      selectedIndex: 0,
      context: nil,
    )
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
    let sourceEntryIDHints = ["entry-0": 0, "entry-1": 1]
    await store.send(.playNow(
      items: items,
      start: .collection,
      context: nil,
    )) {
      $0.pendingMetadataPlan = zip(contextItems, [0, 1]).map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0, sourceEntryID: $1)
      }
      $0.pendingPlayNowItems = contextItems
      $0.playbackSource = playbackSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: contextItems, sourceEntryIDs: [0, 1]),
      )
    }
    await store.receive(.playNowFinished(snapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.playlistSourceHints = sourceHints
      $0.queueRoleHints = roleHints
      $0.sourceEntryIDHints = sourceEntryIDHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        playlistSourceHints: sourceHints,
        queueRoleHints: roleHints,
        sourceEntryIDHints: sourceEntryIDHints,
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
  func progressiveSnapshotsRetainAlbumPlanUntilAllOccurrencesMaterialize() async {
    let plan = [
      playbackItem("first").withAlbumID("album-a"),
      playbackItem("second").withAlbumID("album-b"),
    ].map {
      PlaybackMetadataHintMatcher.Occurrence(item: $0)
    }
    let firstSnapshot = playbackSnapshot(items: [playbackItem("first")])
    let fullSnapshot = playbackSnapshot(items: [
      playbackItem("first"),
      playbackItem("second"),
    ])
    let store = TestStore(initialState: PlaybackFeature.State(
      pendingMetadataPlan: plan,
    )) {
      PlaybackFeature()
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.snapshotChanged(firstSnapshot)))
    #expect(store.state.pendingMetadataPlan != nil)
    expectNoDifference(store.state.session?.currentItem.albumID, "album-a")

    await store.send(.playbackEvent(.snapshotChanged(fullSnapshot)))
    await store.finish()
    #expect(store.state.pendingMetadataPlan == nil)
    expectNoDifference(
      store.state.session?.queue.items.map(\.albumID),
      ["album-a", "album-b"],
    )
  }

  @Test
  func infiniteSnapshotRetainsTemporarilyMissingUpcomingMetadata() async throws {
    let currentEntry = PlaybackQueueEntry(
      id: "current",
      item: playbackItem("current").withQueueRole(.context),
    )
    let missingEntry = PlaybackQueueEntry(
      id: "provisional-missing",
      item: playbackItem("missing").withQueueRole(.context),
      viewID: "stable-missing",
    )
    let queue = try #require(PlaybackFeature.Queue(
      entries: [currentEntry, missingEntry],
      currentEntryID: currentEntry.id,
    ))
    var state = PlaybackFeature.State(
      session: .init(queue: queue),
      hasAuthoritativeSnapshot: true,
      preferences: PlaybackPreferences(endBehavior: .infinite),
    )
    state.recordMetadata(entries: queue.entries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.snapshotChanged(.init(
      entries: [
        PlaybackQueueEntry(
          id: currentEntry.id,
          item: currentEntry.item.withQueueRole(nil),
        ),
      ],
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    ))))
    await store.finish()

    expectNoDifference(store.state.temporarilyMissingUpcomingEntries, [missingEntry])
  }

  @Test
  func temporarilyMissingInfiniteEntrySurvivesAnInsertionWhileStillAbsent() async throws {
    let currentEntry = PlaybackQueueEntry(
      id: "current",
      item: playbackItem("current").withQueueRole(.context),
    )
    let missingEntry = PlaybackQueueEntry(
      id: "provisional-missing",
      item: playbackItem("missing").withQueueRole(.context),
      viewID: "stable-missing",
    )
    let insertedItem = playbackItem("inserted")
    let queue = try #require(PlaybackFeature.Queue(
      entries: [currentEntry],
      currentEntryID: currentEntry.id,
    ))
    var state = PlaybackFeature.State(
      session: .init(queue: queue),
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [],
      ),
      preferences: PlaybackPreferences(endBehavior: .infinite),
      temporarilyMissingUpcomingEntries: [missingEntry],
    )
    state.pendingInfiniteLookaheadInsertion = .init(
      entries: [.generated(insertedItem)],
      remainingPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [],
      ),
    )
    state.prepareMetadataPlan(
      prefixEntries: [currentEntry],
      appendedEntries: [.generated(insertedItem)],
    )
    let snapshot = PlaybackSnapshot(
      entries: [
        PlaybackQueueEntry(
          id: currentEntry.id,
          item: currentEntry.item.withQueueRole(nil),
        ),
        PlaybackQueueEntry(id: "inserted", item: insertedItem),
      ],
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    }
    store.exhaustivity = .off

    await store.send(.infiniteLookaheadInsertionFinished(snapshot))
    await store.finish()

    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .context,
    ])
    expectNoDifference(store.state.temporarilyMissingUpcomingEntries, [missingEntry])
  }

  @Test
  func returningInfiniteTailEntryRecoversMetadataBeforeNextInsertion() async throws {
    let artworkURL = URL(string: "https://example.com/missing.jpg")!
    let currentEntry = PlaybackQueueEntry(
      id: "current",
      item: playbackItem("current").withQueueRole(.context),
    )
    let missingEntry = PlaybackQueueEntry(
      id: "provisional-missing",
      item: playbackItem("missing")
        .withArtworkURL(artworkURL)
        .withQueueRole(.context),
      viewID: "stable-missing",
    )
    let insertedItem = playbackItem("inserted")
    let queue = try #require(PlaybackFeature.Queue(
      entries: [currentEntry],
      currentEntryID: currentEntry.id,
    ))
    var state = PlaybackFeature.State(
      session: .init(queue: queue),
      hasAuthoritativeSnapshot: true,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [],
      ),
      preferences: PlaybackPreferences(endBehavior: .infinite),
      temporarilyMissingUpcomingEntries: [missingEntry],
    )
    state.pendingInfiniteLookaheadInsertion = .init(
      entries: [.generated(insertedItem)],
      remainingPlan: .init(
        remainingSourceEntryIDs: [],
        generatedItems: [],
      ),
    )
    state.prepareMetadataPlan(
      prefixEntries: [currentEntry],
      appendedEntries: [.generated(insertedItem)],
    )
    let snapshot = PlaybackSnapshot(
      entries: [
        PlaybackQueueEntry(
          id: currentEntry.id,
          item: currentEntry.item.withQueueRole(nil),
        ),
        PlaybackQueueEntry(
          id: "returned-missing",
          item: playbackItem("missing"),
        ),
        PlaybackQueueEntry(id: "inserted", item: insertedItem),
      ],
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    }
    store.exhaustivity = .off

    await store.send(.infiniteLookaheadInsertionFinished(snapshot))
    await store.finish()

    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .context,
      .context,
    ])
    expectNoDifference(store.state.session?.queue.entries.map(\.viewID), [
      currentEntry.viewID,
      missingEntry.viewID,
      "inserted",
    ])
    expectNoDifference(store.state.session?.queue.entries[1].item.artworkURL, artworkURL)
    expectNoDifference(store.state.temporarilyMissingUpcomingEntries, [])
  }

  @Test
  func stalePartialSnapshotDoesNotConsumeFutureMetadataOccurrence() async {
    let firstItem = playbackItem("first").withQueueRole(.context)
    let secondItem = playbackItem("second").withQueueRole(.context)
    let futureItem = playbackItem("future").withQueueRole(.context)
    let previousEntries = [
      PlaybackQueueEntry(id: "old-first", item: firstItem),
      PlaybackQueueEntry(id: "old-second", item: secondItem),
    ]
    let plan = [
      PlaybackMetadataHintMatcher.Occurrence(
        item: firstItem,
        retainedEntryID: previousEntries[0].id,
      ),
      PlaybackMetadataHintMatcher.Occurrence(
        item: secondItem,
        retainedEntryID: previousEntries[1].id,
      ),
      PlaybackMetadataHintMatcher.Occurrence(item: futureItem),
    ]
    let partialSnapshot = PlaybackSnapshot(
      entries: [
        PlaybackQueueEntry(id: "new-first", item: firstItem.withQueueRole(nil)),
        PlaybackQueueEntry(id: "new-second", item: secondItem.withQueueRole(nil)),
      ],
      currentEntryID: "new-first",
      playStatus: .playing,
      progress: .zero,
    )
    let fullSnapshot = PlaybackSnapshot(
      entries: partialSnapshot.entries + [
        PlaybackQueueEntry(id: "new-future", item: futureItem.withQueueRole(nil)),
      ],
      currentEntryID: "new-first",
      playStatus: .playing,
      progress: .zero,
    )
    var state = PlaybackFeature.State(
      session: .init(queue: .init(
        items: previousEntries.map(\.item),
      )),
      hasAuthoritativeSnapshot: true,
      pendingMetadataPlan: plan,
    )
    state.recordMetadata(entries: previousEntries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.snapshotChanged(partialSnapshot)))

    expectNoDifference(store.state.pendingMetadataPlan, plan)
    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .context,
    ])

    await store.send(.playbackEvent(.snapshotChanged(fullSnapshot)))
    await store.finish()

    expectNoDifference(store.state.pendingMetadataPlan, nil)
    expectNoDifference(store.state.session?.queue.entries.map(\.role), [
      .context,
      .context,
      .context,
    ])
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
  func metadataMatcherAlignsNewTailAfterDroppedRetainedPrefix() {
    let appendedSource = PlaylistPlaybackSource(playlistID: UUID(1), entryID: UUID(2))
    let plan = [
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("dropped"),
        retainedEntryID: "dropped-entry",
      ),
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("current"),
        retainedEntryID: "current-entry",
      ),
      PlaybackMetadataHintMatcher.Occurrence(
        item: playbackItem("appended").withPlaylistSource(appendedSource),
      ),
    ]
    let entries = [
      PlaybackQueueEntry(id: "current-entry", item: playbackItem("current")),
      PlaybackQueueEntry(id: "appended-entry", item: playbackItem("appended")),
    ]

    let matched = PlaybackMetadataHintMatcher.match(plan: plan, entries: entries)

    expectNoDifference(matched, ["appended-entry": appendedSource])
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
  func playbackSnapshotReplacesTransientArtworkWithApprovedWebArtwork() async {
    let webURL = URL(string: "https://example.com/album.jpg")!
    let transientURL = URL(string: "musicKit://artwork/transient/600x600?id=artwork")!
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      artworkURL: webURL,
      tracks: [ApprovedTrack(id: "track", title: "Track", artistName: "Artist")],
    )
    let library = ApprovedMusicLibrary(albums: [album])
    let transientItem = PlaybackItem(
      id: album.tracks[0].id,
      title: album.tracks[0].title,
      artistName: album.tracks[0].artistName,
      artworkURL: transientURL,
    )
    let snapshot = playbackSnapshot(items: [transientItem])
    let restoredSnapshot = playbackSnapshot(items: [
      transientItem.withArtworkURL(webURL),
    ])
    let sourceAlbumIDs = [album.tracks[0].id: album.id]
    let store = TestStore(initialState: PlaybackFeature.State(
      approvedLibrary: library,
      approvedTrackIDs: library.approvedTrackIDs,
      sourceAlbumIDs: sourceAlbumIDs,
    )) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.snapshotChanged(snapshot))) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.session = PlaybackFeature.Session(
        snapshot: restoredSnapshot,
        sourceAlbumIDs: sourceAlbumIDs,
      )
    }
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
  func simulatorSetUpcomingCanAddNewEntries() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated { _ in
      await clock.sleep()
    }
    let initialSnapshot = try await client.playNow([
      playbackItem("current"),
      playbackItem("existing"),
    ], 0)

    let snapshot = try await client.setUpcoming([
      initialSnapshot.entries[1],
      PlaybackQueueEntry(id: "pending:new", item: playbackItem("new")),
    ])

    expectNoDifference(snapshot.entries.map(\.item.id), ["current", "existing", "new"])
    expectNoDifference(snapshot.entries[1].id, initialSnapshot.entries[1].id)
    #expect(snapshot.entries[2].id != "pending:new")
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
  func simulatorRepeatOneRepeatsNaturallyAndKeepsManualNavigation() async throws {
    let clock = PlaybackSimulatorClock()
    let client = PlaybackClient.simulated(defaultDuration: 0.5) { _ in
      await clock.sleep()
    }
    let items = [
      playbackItem("first"),
      playbackItem("second"),
      playbackItem("third"),
    ]
    await client.setRepeatsCurrentEntry(true)
    let initialSnapshot = try await client.playNow(items, 0)

    await clock.advance()
    await clock.advance()
    await clock.waitUntilSleeping()
    let repeatedSnapshot = try await client.insertIntoQueue([], .tail)

    expectNoDifference(repeatedSnapshot.currentEntryID, initialSnapshot.entries[0].id)
    expectNoDifference(
      repeatedSnapshot.progress,
      .init(elapsedTime: 0, duration: 0.5),
    )
    expectNoDifference(repeatedSnapshot.playStatus, .playing)

    let nextOutcome = try await client.skipToNext()
    let nextSnapshot = try await client.insertIntoQueue([], .tail)
    try await client.skipToPrevious()
    let previousSnapshot = try await client.insertIntoQueue([], .tail)

    expectNoDifference(nextOutcome, .advanced)
    expectNoDifference(nextSnapshot.currentEntryID, initialSnapshot.entries[1].id)
    expectNoDifference(previousSnapshot.currentEntryID, initialSnapshot.entries[0].id)
    await client.clearQueue()
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
    let firstSource = PlaybackSource(items: firstItems, selectedIndex: 0, context: nil)
    let secondSource = PlaybackSource(items: secondItems, selectedIndex: 0, context: nil)
    let secondSnapshot = playbackSnapshot(items: secondContextItems)
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .context,
    ]
    let sourceEntryIDHints = ["entry-0": 0, "entry-1": 1]
    let gate = PlaybackStartGate()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playNow = { items, startIndex in
        try await gate.start()
        return playbackSnapshot(items: Array(items[startIndex...]))
      }
    }

    await store.send(.playNow(items: firstItems, start: .collection, context: nil)) {
      $0.pendingMetadataPlan = zip(firstContextItems, [0, 1]).map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0, sourceEntryID: $1)
      }
      $0.pendingPlayNowItems = firstContextItems
      $0.playbackSource = firstSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: firstContextItems, sourceEntryIDs: [0, 1]),
      )
    }
    await gate.waitUntilFirstStartBegins()

    await store.send(.playNow(items: secondItems, start: .collection, context: nil)) {
      $0.pendingMetadataPlan = zip(secondContextItems, [0, 1]).map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0, sourceEntryID: $1)
      }
      $0.pendingPlayNowItems = secondContextItems
      $0.playbackSource = secondSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: secondContextItems, sourceEntryIDs: [0, 1]),
      )
    }
    await store.receive(.playNowFinished(secondSnapshot)) {
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 0
      $0.pendingMetadataPlan = nil
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = roleHints
      $0.sourceEntryIDHints = sourceEntryIDHints
      $0.session = PlaybackFeature.Session(
        snapshot: secondSnapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
        sourceEntryIDHints: sourceEntryIDHints,
      )
    }

    await gate.releaseFirstStart()
    await store.finish()
  }

  @Test
  func queueEditCancelsInFlightPlayNow() async {
    let playNowItems = [playbackItem("first-1"), playbackItem("first-2")]
    let contextItems = playNowItems.map { $0.withQueueRole(.context) }
    let playbackSource = PlaybackSource(
      items: playNowItems,
      selectedIndex: 0,
      context: nil,
    )
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

    await store.send(.playNow(items: playNowItems, start: .collection, context: nil)) {
      $0.pendingMetadataPlan = zip(contextItems, [0, 1]).map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0, sourceEntryID: $1)
      }
      $0.pendingPlayNowItems = contextItems
      $0.playbackSource = playbackSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: contextItems, sourceEntryIDs: [0, 1]),
      )
    }
    await gate.waitUntilFirstStartBegins()

    await store.send(.addToQueue([queuedItem])) {
      $0.pendingMetadataPlan = [
        .init(
          item: contextItems[0],
          retainedEntryID: "pending:0:first-1",
          sourceEntryID: 0,
        ),
        .init(item: queuedItem),
        .init(
          item: contextItems[1],
          retainedEntryID: "pending:1:first-2",
          sourceEntryID: 1,
        ),
      ]
      $0.pendingPlayNowItems = nil
      $0.queueRoleHints = [
        "pending:0:first-1": .context,
        "pending:1:first-2": .context,
      ]
      $0.sourceEntryIDHints = [
        "pending:0:first-1": 0,
        "pending:1:first-2": 1,
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
        sourceEntryIDHints: $0.sourceEntryIDHints,
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

    await store.send(.playNow(items: [], start: .collection, context: nil))
  }

  @Test
  func playNowWithInvalidStartIndexDoesNothing() async {
    let items = [playbackItem("track-1")]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playNow(
      items: items,
      start: .selectedEntry(index: 1),
      context: nil,
    ))
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
        .init(
          id: "engine-current",
          item: currentItem,
          sourceEntryID: 0,
          viewID: "stable-current",
        ),
        .init(
          id: "engine-duplicate",
          item: removedItem,
          sourceEntryID: 1,
          viewID: "stable-duplicate",
        ),
        .init(
          id: "engine-retained",
          item: retainedItem,
          sourceEntryID: 2,
          viewID: "stable-retained",
        ),
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
    let playbackSource = PlaybackSource(
      items: [currentItem, removedItem, retainedItem],
      selectedIndex: 0,
      context: nil,
    )
    let recorder = PlaybackQueueEditRecorder()
    let store = TestStore(initialState: .init(
      session: PlaybackFeature.Session(snapshot: initialSnapshot, sourceAlbumIDs: [:]),
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 0,
      playbackSource: playbackSource,
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
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [0, 2])
    expectNoDifference(store.state.playbackSource?.removedEntryIDs, [1])
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
    let initialEntries = items.enumerated().map { index, item in
      PlaybackQueueEntry(
        id: "entry-\(index)",
        item: item,
        sourceEntryID: index,
      )
    }
    let initialSnapshot = PlaybackSnapshot(
      entries: initialEntries,
      currentEntryID: initialEntries[0].id,
      playStatus: .playing,
      progress: .zero,
    )
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
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [0, 2, 1])
  }

  @Test
  func shuffledManualReorderControlsCurrentPassButFutureCycleIsFresh() async throws {
    let sourceItems = (0 ..< 4).map { playbackItem("source-\($0)") }
    let source = PlaybackSource(
      items: sourceItems,
      selectedIndex: 0,
      context: nil,
    )
    let currentEntry = PlaybackQueueEntry(
      id: "current",
      item: source.entries[0].item.withQueueRole(.context),
      sourceEntryID: 0,
    )
    let queuedEntries = [
      PlaybackQueueEntry(
        id: "queued-1",
        item: playbackItem("queued-1").withQueueRole(.queued),
      ),
      PlaybackQueueEntry(
        id: "queued-2",
        item: playbackItem("queued-2").withQueueRole(.queued),
      ),
    ]
    let contextEntries = source.entries.dropFirst().map { entry in
      PlaybackQueueEntry(
        id: "source-\(entry.id)",
        item: entry.item.withQueueRole(.context),
        sourceEntryID: entry.id,
      )
    }
    let initialSnapshot = PlaybackSnapshot(
      entries: [currentEntry] + queuedEntries + contextEntries,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let manuallyOrderedUpcoming = queuedEntries + [
      contextEntries[2],
      contextEntries[0],
      contextEntries[1],
    ]
    let manuallyOrderedSnapshot = PlaybackSnapshot(
      entries: [currentEntry] + manuallyOrderedUpcoming,
      currentEntryID: currentEntry.id,
      playStatus: .playing,
      progress: .zero,
    )
    let finalSnapshot = PlaybackSnapshot(
      entries: manuallyOrderedSnapshot.entries,
      currentEntryID: contextEntries[1].id,
      playStatus: .playing,
      progress: .zero,
    )
    let session = try #require(PlaybackFeature.Session(
      snapshot: initialSnapshot,
      sourceAlbumIDs: [:],
    ))
    let recorder = PlaybackQueueEditRecorder()
    var state = PlaybackFeature.State(
      session: session,
      hasAuthoritativeSnapshot: true,
      playbackSource: source,
      preferences: .init(
        endBehavior: .loopCollection,
        isShuffleEnabled: true,
      ),
    )
    state.recordMetadata(entries: initialSnapshot.entries)
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.setUpcoming = { entries in
        await recorder.recordUpcomingUpdate(entries)
        return PlaybackSnapshot(
          entries: [currentEntry] + entries,
          currentEntryID: currentEntry.id,
          playStatus: .playing,
          progress: .zero,
        )
      }
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.reorderUpcoming(
      entryViewIDs: manuallyOrderedUpcoming.map(\.viewID),
      queuedEntryCount: queuedEntries.count,
    ))
    await store.receive(.playbackEvent(.snapshotChanged(manuallyOrderedSnapshot)))

    expectNoDifference(
      store.state.session?.queue.upcomingEntries.map(\.viewID),
      manuallyOrderedUpcoming.map(\.viewID),
    )
    expectNoDifference(store.state.session?.queue.upcomingEntries.map(\.role), [
      .queued,
      .queued,
      .context,
      .context,
      .context,
    ])
    #expect(store.state.preferences.isShuffleEnabled)
    expectNoDifference(store.state.playbackSource, source)
    expectNoDifference(store.state.pendingRepeatCycleEntryIDs, nil)

    await store.send(.playbackEvent(.snapshotChanged(finalSnapshot)))
    await store.finish()

    let updates = await recorder.upcomingUpdates
    expectNoDifference(updates.map { $0.map(\.viewID) }, [
      manuallyOrderedUpcoming.map(\.viewID),
    ])
    expectNoDifference(store.state.pendingRepeatCycleEntryIDs, [3, 0, 1, 2])
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
    let playbackSource = PlaybackSource(items: [item], selectedIndex: 0, context: nil)

    await store.send(.playNow(
      items: [item],
      start: .selectedEntry(index: 0),
      context: nil,
    )) {
      $0.pendingMetadataPlan = [
        PlaybackMetadataHintMatcher.Occurrence(item: contextItem, sourceEntryID: 0),
      ]
      $0.pendingPlayNowItems = [contextItem]
      $0.playbackSource = playbackSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: [contextItem], sourceEntryIDs: [0]),
      )
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
    let playbackSource = PlaybackSource(items: [item], selectedIndex: 0, context: nil)

    await store.send(.playNow(
      items: [item],
      start: .selectedEntry(index: 0),
      context: nil,
    )) {
      $0.pendingMetadataPlan = [
        PlaybackMetadataHintMatcher.Occurrence(item: contextItem, sourceEntryID: 0),
      ]
      $0.pendingPlayNowItems = [contextItem]
      $0.playbackSource = playbackSource
      $0.session = .init(
        playStatus: .loading,
        queue: .init(items: [contextItem], sourceEntryIDs: [0]),
      )
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
  func playbackSnapshotPreservesAlbumPerDuplicateOccurrence() async {
    let item = playbackItem("duplicate")
    let items = [
      item.withAlbumID("album-a"),
      item.withAlbumID("album-b"),
    ]
    let store = TestStore(initialState: PlaybackFeature.State(
      session: .init(queue: .init(items: items)),
      sourceAlbumIDs: [item.id: "album-b"],
    )) {
      PlaybackFeature()
    }
    store.exhaustivity = .off

    await store.send(.playbackEvent(.snapshotChanged(playbackSnapshot(items: [item, item]))))
    await store.finish()

    expectNoDifference(
      store.state.session?.queue.entries.map(\.item.albumID),
      ["album-a", "album-b"],
    )
  }

  @Test
  func albumResolutionDoesNotUpdateDifferentCurrentOccurrence() throws {
    let item = playbackItem("duplicate")
    let entries = [
      PlaybackQueueEntry(id: "first", item: item, viewID: "first-view"),
      PlaybackQueueEntry(id: "second", item: item, viewID: "second-view"),
    ]
    let queue = try #require(PlaybackFeature.Queue(
      entries: entries,
      currentEntryID: "second",
    ))
    var state = PlaybackFeature.State(
      session: .init(queue: queue),
      pendingAlbumResolutionViewID: "first-view",
    )

    state.setCurrentAlbumID("album-a", for: "first-view")

    expectNoDifference(state.session?.queue.items.map(\.albumID), [nil, nil])
    expectNoDifference(state.pendingAlbumResolutionViewID, "first-view")
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
    await store.receive(.resumeFinished)
  }

  @Test
  func failedResumeDoesNotReportSuccess() async {
    struct ResumeError: Error {}

    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(
      playStatus: .paused,
      currentItem: item,
    ))) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.resume = { throw ResumeError() }
    }

    await store.send(.resume) {
      $0.session?.playStatus = .playing
    }
    await store.receive(.playbackFailed(.init(failure: .playbackFailed))) {
      $0.failure = .playbackFailed
      $0.session?.playStatus = .paused
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
    await store.receive(.resumeFinished)
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
    await store.receive(.skipToNextFinished(.advanced))

    #expect(await recorder.skipToNextCount == 1)
  }

  @Test
  func skipToNextOnFinalItemEndsQueue() async {
    let item = playbackItem("track-1")
    let recorder = PlaybackCommandRecorder()
    let playbackSource = PlaybackSource(items: [item], selectedIndex: 0, context: nil)
    let preferences = PlaybackPreferences(
      endBehavior: .infinite,
      isShuffleEnabled: true,
    )
    let store = TestStore(initialState: .init(
      session: .init(currentItem: item),
      failure: .trackUnavailable,
      hasAuthoritativeSnapshot: true,
      lastCachedProgressBucket: 8,
      pendingAlbumResolutionViewID: "pending:0:track-1",
      playbackSource: playbackSource,
      preferences: preferences,
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
    await store.receive(.skipToNextFinished(.queueEnded))
    await store.receive(.playbackEvent(.queueEnded)) {
      $0.failure = nil
      $0.hasAuthoritativeSnapshot = false
      $0.lastCachedProgressBucket = nil
      $0.pendingAlbumResolutionViewID = nil
      $0.playbackSource = nil
      $0.progress = .zero
      $0.session = nil
      $0.sourceAlbumIDs.removeAll()
    }
    await store.finish()

    expectNoDifference(store.state.preferences, preferences)
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
    await store.receive(.skipToPreviousFinished)

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
    await store.receive(.skipToPreviousFinished)

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
    await store.receive(.skipToPreviousFinished)

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
  func restoreCachedSessionRestoresFullPlaybackSource() async {
    let sourceItems = [
      playbackItem("track-1"),
      playbackItem("track-2"),
      playbackItem("track-3"),
    ]
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    var playbackSource = PlaybackSource(
      items: sourceItems,
      selectedIndex: 1,
      context: context,
    )
    playbackSource.remove(0)
    let infinitePlaybackPlan = InfinitePlaybackPlan(
      remainingSourceEntryIDs: [],
      generatedItems: [playbackItem("generated")],
    )
    let checkpoint = PlaybackCheckpoint(
      songIDs: ["track-2", "track-3"],
      currentIndex: 0,
      elapsedTime: 42,
      infinitePlaybackPlan: infinitePlaybackPlan,
      playbackSource: playbackSource,
      sourceEntryIDs: [1, 2],
      context: context,
    )
    let snapshot = playbackSnapshot(
      items: Array(sourceItems.dropFirst()),
      playStatus: .paused,
      progress: .init(elapsedTime: 42, duration: 180),
    )
    let store = TestStore(initialState: PlaybackFeature.State(
      preferences: .init(endBehavior: .infinite),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restoreQueue = { _ in snapshot }
      $0.playbackSessionCache._load = { checkpoint }
    }

    await store.send(.restoreCachedSession)
    await store.receive(.checkpointLoaded(checkpoint)) {
      $0.infinitePlaybackPlan = infinitePlaybackPlan
      $0.isRestoringCheckpoint = true
      $0.pendingMetadataPlan = zip(checkpoint.songIDs, [1, 2]).map { songID, sourceEntryID in
        PlaybackMetadataHintMatcher.Occurrence(
          item: PlaybackItem(
            id: songID,
            title: "",
            artistName: "",
            artworkURL: nil,
          ),
          sourceEntryID: sourceEntryID,
        )
      }
      $0.playbackContext = context
      $0.playbackSource = playbackSource
    }
    await store.receive(.checkpointRestorationFinished(snapshot)) {
      $0.isRestoringCheckpoint = false
    }
    await store.receive(.playbackEvent(.snapshotChanged(snapshot))) {
      let sourceEntryIDHints = ["entry-0": 1, "entry-1": 2]
      $0.hasAuthoritativeSnapshot = true
      $0.lastCachedProgressBucket = 8
      $0.pendingMetadataPlan = nil
      $0.progress = snapshot.progress
      $0.sourceEntryIDHints = sourceEntryIDHints
      $0.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        sourceEntryIDHints: sourceEntryIDHints,
      )
    }

    expectNoDifference(store.state.infinitePlaybackPlan, infinitePlaybackPlan)
    expectNoDifference(store.state.playbackSource, playbackSource)
    expectNoDifference(store.state.session?.queue.entries.map(\.sourceEntryID), [1, 2])
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
  func restoreCachedSessionPreservesAlbumPerDuplicateOccurrence() async {
    let item = playbackItem("duplicate")
    let checkpoint = PlaybackCheckpoint(
      songIDs: [item.id, item.id],
      albumIDs: ["album-a", "album-b"],
      currentIndex: 0,
      elapsedTime: 12,
    )
    let snapshot = playbackSnapshot(
      items: [item, item],
      playStatus: .paused,
    )
    let store = TestStore(initialState: PlaybackFeature.State()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.restoreQueue = { _ in snapshot }
      $0.playbackSessionCache._load = { checkpoint }
    }
    store.exhaustivity = .off

    await store.send(.restoreCachedSession)
    await store.receive(.checkpointLoaded(checkpoint))
    await store.receive(.checkpointRestorationFinished(snapshot))
    await store.receive(.playbackEvent(.snapshotChanged(snapshot)))
    await store.finish()

    expectNoDifference(
      store.state.session?.queue.entries.map(\.item.albumID),
      ["album-a", "album-b"],
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
  func approvedLibraryUpdateReplacesSnapshotAndDerivedTrackIDs() async {
    let cached = cachedApprovedMusicLibrary
    let remote = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: PlaybackFeature.State()) {
      PlaybackFeature()
    }

    await store.send(.approvedLibraryUpdated(cached)) {
      $0.approvedLibrary = cached
      $0.approvedTrackIDs = cached.approvedTrackIDs
    }
    await store.send(.approvedLibraryUpdated(remote)) {
      $0.approvedLibrary = remote
      $0.approvedTrackIDs = remote.approvedTrackIDs
    }
    await store.send(.approvedLibraryUpdated(.empty)) {
      $0.approvedLibrary = .empty
      $0.approvedTrackIDs = []
    }
  }

  @Test
  func infiniteApprovalUpdateFiltersPlanAndAddsNewlyApprovedTracks() async {
    let allowed = ApprovedTrack(id: "allowed", title: "Allowed", artistName: "Artist")
    let revoked = ApprovedTrack(id: "revoked", title: "Revoked", artistName: "Artist")
    let added = ApprovedTrack(id: "added", title: "Added", artistName: "Artist")
    let oldLibrary = ApprovedMusicLibrary(albums: [
      ApprovedAlbum(
        id: "old-album",
        title: "Old Album",
        artistName: "Artist",
        tracks: [allowed, revoked],
      ),
    ])
    let newAlbum = ApprovedAlbum(
      id: "new-album",
      title: "New Album",
      artistName: "Artist",
      tracks: [allowed, added],
    )
    let newLibrary = ApprovedMusicLibrary(albums: [newAlbum])
    let source = PlaybackSource(
      items: playbackItems(album: oldLibrary.albums[0]),
      selectedIndex: 0,
      context: nil,
    )
    let store = TestStore(initialState: PlaybackFeature.State(
      approvedLibrary: oldLibrary,
      approvedTrackIDs: oldLibrary.approvedTrackIDs,
      infinitePlaybackPlan: .init(
        remainingSourceEntryIDs: [1],
        generatedItems: [source.entries[1].item],
      ),
      playbackSource: source,
      preferences: .init(endBehavior: .infinite),
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.withRandomNumberGenerator = .init(MaxRandomNumberGenerator())
    }
    store.exhaustivity = .off

    await store.send(.approvedLibraryUpdated(newLibrary))

    expectNoDifference(store.state.infinitePlaybackPlan, InfinitePlaybackPlan(
      remainingSourceEntryIDs: [],
      generatedItems: [playbackItems(album: newAlbum)[1]],
    ))
    expectNoDifference(store.state.playbackSource?.removedEntryIDs, [1])
  }

  @Test
  func approvalUpdatePersistsRemovedSourceEntriesOutsideTheActiveQueue() async {
    let current = playbackItem("current")
    let playbackSource = PlaybackSource(
      items: [playbackItem("consumed"), current],
      selectedIndex: 1,
      context: nil,
    )
    let recorder = PlaybackSessionCacheRecorder()
    let store = TestStore(initialState: .init(
      session: .init(currentItem: current),
      hasAuthoritativeSnapshot: true,
      playbackSource: playbackSource,
    )) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackSessionCache._save = { checkpoint in
        await recorder.record(checkpoint)
      }
    }

    await store.send(.approvedTrackIDsUpdated(["current"])) {
      $0.approvedTrackIDs = ["current"]
      $0.playbackSource?.removedEntryIDs = [0]
    }
    await store.finish()

    let savedCheckpoint = await recorder.checkpoint
    expectNoDifference(savedCheckpoint?.playbackSource?.removedEntryIDs, [0])
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
    let playbackSource = PlaybackSource(
      items: [
        playbackItem("revoked-current"),
        playbackItem("allowed"),
        playbackItem("revoked-tail"),
      ],
      selectedIndex: 0,
      context: context,
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
      playbackSource: playbackSource,
      playlistSourceHints: [nil, source, nil],
      queueRoles: [.context, .queued, .context],
      sourceEntryIDs: [0, 1, 2],
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
    expectNoDifference(cachedCheckpoint?.sourceEntryIDs, [1])
    expectNoDifference(store.state.session?.currentTrackID, "allowed")
    expectNoDifference(store.state.session?.queue.currentEntry.role, .queued)
    expectNoDifference(store.state.session?.queue.currentEntry.sourceEntryID, 1)
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

private actor PlaybackPreferencesRecorder {
  var preferences: [PlaybackPreferences] = []

  func record(_ preferences: PlaybackPreferences) {
    self.preferences.append(preferences)
  }
}

private struct MaxRandomNumberGenerator: RandomNumberGenerator, Sendable {
  mutating func next() -> UInt64 {
    .max
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
  var repeatCurrentEntryValues: [Bool] = []
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

  func recordSetRepeatsCurrentEntry(_ repeatsCurrentEntry: Bool) {
    self.repeatCurrentEntryValues.append(repeatsCurrentEntry)
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
