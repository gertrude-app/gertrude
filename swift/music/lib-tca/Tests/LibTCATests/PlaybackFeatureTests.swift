import ComposableArchitecture
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
  func playTrackStartsSession() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playTrack(item)) {
      $0.session = .init(playStatus: .loading, currentItem: item)
    }
    await store.receive(.playbackStarted) {
      $0.session?.playStatus = .playing
    }
  }

  @Test
  func playAlbumQueueStartsSessionAtStartIndex() async {
    let items = [
      playbackItem("track-1"),
      playbackItem("track-2"),
      playbackItem("track-3"),
    ]
    let recorder = PlaybackAlbumRecorder()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playAlbum = { items, startIndex in
        await recorder.record(items: items, startIndex: startIndex)
      }
    }

    await store.send(.playAlbumQueue(items: items, startIndex: 1)) {
      $0.session = .init(
        playStatus: .loading,
        albumQueue: .init(items: items, currentIndex: 1),
      )
    }
    await store.receive(.playbackStarted) {
      $0.session?.playStatus = .playing
    }

    #expect(await recorder.items == items)
    #expect(await recorder.startIndex == 1)
  }

  @Test
  func albumQueueTracksCurrentAndUpcomingItems() {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let queue = PlaybackFeature.AlbumQueue(items: items, currentIndex: 1)

    #expect(queue.currentItem == items[1])
    #expect(queue.upcomingItems == [items[2], items[0]])
  }

  @Test
  func playAlbumQueueWithEmptyTracksDoesNothing() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playAlbumQueue(items: [], startIndex: 0))
  }

  @Test
  func playAlbumQueueWithInvalidStartIndexDoesNothing() async {
    let items = [playbackItem("track-1")]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playAlbumQueue(items: items, startIndex: 1))
  }

  @Test
  func playbackFailurePausesCurrentSessionAndShowsFailure() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playTrack = { _ in throw PlaybackClientError.musicAccessDenied }
    }

    let item = playbackItem("track-1")

    await store.send(.playTrack(item)) {
      $0.session = .init(playStatus: .loading, currentItem: item)
    }
    await store.receive(.playbackFailed(.musicAccessDenied)) {
      $0.session?.playStatus = .paused
      $0.failure = .musicAccessDenied
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
  func playbackEventUpdatesCurrentSessionPlayStatus() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(currentItem: item))) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.playStatusChanged(.paused))) {
      $0.session?.playStatus = .paused
    }
    await store.send(.playbackEvent(.playStatusChanged(.playing))) {
      $0.session?.playStatus = .playing
    }
  }

  @Test
  func playbackEventUpdatesCurrentSessionProgress() async {
    let item = playbackItem("track-1")
    let progress = PlaybackProgress(elapsedTime: 42, duration: 180)
    let store = TestStore(initialState: .init(session: .init(currentItem: item))) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.progressChanged(progress))) {
      $0.session?.progress = progress
      $0.lastCachedProgressBucket = 8
    }
  }

  @Test
  func playbackEventUpdatesCurrentSessionItem() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let store = TestStore(initialState: .init(session: .init(
      albumQueue: .init(items: items, currentIndex: 0),
      progress: .init(elapsedTime: 40, duration: 180),
    ))) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.currentItemChanged(items[2].id))) {
      $0.session?.albumQueue.currentIndex = 2
      $0.session?.progress = .zero
    }
  }

  @Test
  func playbackEventWithUnknownCurrentItemDoesNothing() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let store = TestStore(initialState: .init(session: .init(
      albumQueue: .init(items: items, currentIndex: 0),
      progress: .init(elapsedTime: 40, duration: 180),
    ))) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.currentItemChanged("track-3")))
  }

  @Test
  func playbackEventWithSameCurrentItemDoesNothing() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let store = TestStore(initialState: .init(session: .init(
      albumQueue: .init(items: items, currentIndex: 0),
      progress: .init(elapsedTime: 40, duration: 180),
    ))) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.currentItemChanged(items[0].id)))
  }

  @Test
  func playbackEventWithoutSessionDoesNothing() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playbackEvent(.playStatusChanged(.paused)))
    await store.send(.playbackEvent(.currentItemChanged("track-1")))
    await store.send(.playbackEvent(.progressChanged(.init(elapsedTime: 42, duration: 180))))
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
    let store = TestStore(initialState: .init(session: .init(
      currentItem: item,
      progress: .init(elapsedTime: 10, duration: 180),
    ))) {
      PlaybackFeature()
    }

    await store.send(.seek(42)) {
      $0.session?.progress = .init(elapsedTime: 42, duration: 180)
    }
  }

  @Test
  func seekClampsToDuration() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init(session: .init(
      currentItem: item,
      progress: .init(elapsedTime: 10, duration: 180),
    ))) {
      PlaybackFeature()
    }

    await store.send(.seek(240)) {
      $0.session?.progress = .init(elapsedTime: 180, duration: 180)
    }
  }

  @Test
  func skipToNextRequestsMusicKitNextEntry() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(session: .init(
      albumQueue: .init(items: items, currentIndex: 0),
      progress: .init(elapsedTime: 42, duration: 180),
    ))) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.skipToNext = {
        await recorder.recordSkipToNext()
      }
    }

    await store.send(.skipToNext)

    #expect(await recorder.skipToNextCount == 1)
  }

  @Test
  func skipToNextWithSingleItemRequestsMusicKitNextEntry() async {
    let item = playbackItem("track-1")
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(session: .init(
      currentItem: item,
      progress: .init(elapsedTime: 42, duration: 180),
    ))) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.skipToNext = {
        await recorder.recordSkipToNext()
      }
    }

    await store.send(.skipToNext)

    #expect(await recorder.skipToNextCount == 1)
  }

  @Test
  func skipToPreviousAfterFirstThreeSecondsRestartsCurrentItem() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(session: .init(
      albumQueue: .init(items: items, currentIndex: 1),
      progress: .init(elapsedTime: 4, duration: 180),
    ))) {
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
    let store = TestStore(initialState: .init(session: .init(
      albumQueue: .init(items: items, currentIndex: 1),
      progress: .init(elapsedTime: 3, duration: 180),
    ))) {
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
  func skipToPreviousWrapsToLastItem() async {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(session: .init(
      albumQueue: .init(items: items, currentIndex: 0),
      progress: .init(elapsedTime: 2, duration: 180),
    ))) {
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
  func skipWithoutSessionDoesNothing() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.skipToNext)
    await store.send(.skipToPrevious)
  }

  @Test
  func restoreCachedSessionLoadsPausedSession() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let progress = PlaybackProgress(elapsedTime: 42, duration: 180)
    let cachedSession = CachedPlaybackSession(
      items: items,
      currentIndex: 1,
      progress: progress,
    )
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackSessionCache._load = { cachedSession }
    }

    await store.send(.restoreCachedSession)
    await store.receive(.cachedSessionLoaded(cachedSession)) {
      $0.session = .init(
        playStatus: .paused,
        albumQueue: .init(items: items, currentIndex: 1),
        progress: progress,
      )
      $0.requiresPlayerRestore = true
    }
  }

  @Test
  func restoreCachedSessionDoesNotReplaceExistingSession() async {
    let existingItem = playbackItem("track-1")
    let cachedSession = CachedPlaybackSession(
      items: [playbackItem("track-2")],
      currentIndex: 0,
      progress: .init(elapsedTime: 42, duration: 180),
    )
    let store = TestStore(initialState: .init(session: .init(currentItem: existingItem))) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackSessionCache._load = { cachedSession }
    }

    await store.send(.restoreCachedSession)
  }

  @Test
  func resumeRestoredSessionReloadsQueueFromCachedPosition() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let progress = PlaybackProgress(elapsedTime: 42, duration: 180)
    let recorder = PlaybackRestoreRecorder()
    var state = PlaybackFeature.State(session: .init(
      playStatus: .paused,
      albumQueue: .init(items: items, currentIndex: 1),
      progress: progress,
    ))
    state.requiresPlayerRestore = true
    let store = TestStore(initialState: state) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playAlbumFromPosition = { items, startIndex, position in
        await recorder.record(items: items, startIndex: startIndex, position: position)
      }
    }

    await store.send(.resume) {
      $0.session?.playStatus = .loading
    }
    await store.receive(.playbackStarted) {
      $0.requiresPlayerRestore = false
      $0.session?.playStatus = .playing
    }

    #expect(await recorder.items == items)
    #expect(await recorder.startIndex == 1)
    #expect(await recorder.position == 42)
  }

  @Test
  func saveCachedSessionPersistsCurrentSession() async {
    let item = playbackItem("track-1")
    let session = PlaybackFeature.Session(
      playStatus: .paused,
      currentItem: item,
      progress: .init(elapsedTime: 42, duration: 180),
    )
    let recorder = PlaybackSessionCacheRecorder()
    let store = TestStore(initialState: .init(session: session)) {
      PlaybackFeature()
    } withDependencies: {
      $0.playbackSessionCache._save = { session in
        await recorder.record(session)
      }
    }

    await store.send(.saveCachedSession)

    #expect(await recorder.session == CachedPlaybackSession(session: session))
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

private actor PlaybackAlbumRecorder {
  var items: [PlaybackItem]?
  var startIndex: Int?

  func record(items: [PlaybackItem], startIndex: Int) {
    self.items = items
    self.startIndex = startIndex
  }
}

private actor PlaybackRestoreRecorder {
  var items: [PlaybackItem]?
  var position: TimeInterval?
  var startIndex: Int?

  func record(items: [PlaybackItem], startIndex: Int, position: TimeInterval) {
    self.items = items
    self.position = position
    self.startIndex = startIndex
  }
}

private actor PlaybackSessionCacheRecorder {
  var session: CachedPlaybackSession?

  func record(_ session: CachedPlaybackSession) {
    self.session = session
  }
}

private actor PlaybackCommandRecorder {
  var restartCurrentEntryCount = 0
  var skipToNextCount = 0
  var skipToPreviousCount = 0
  var openSettingsCount = 0

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
