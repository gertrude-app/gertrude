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
      playbackItem("track-2", allowsArtwork: false),
      playbackItem("track-3"),
    ]
    let recorder = PlaybackOrderRecorder()
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playTracksInOrder = { items in
        await recorder.record(items)
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

    let recordedItems = await recorder.items
    #expect(recordedItems == [items[1], items[2], items[0]])
  }

  @Test
  func albumQueueRotatesPlaybackOrderFromCurrentIndex() {
    let items = [playbackItem("track-1"), playbackItem("track-2"), playbackItem("track-3")]
    let queue = PlaybackFeature.AlbumQueue(items: items, currentIndex: 1)

    #expect(queue.currentItem == items[1])
    #expect(queue.playbackOrder == [items[1], items[2], items[0]])
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
  func skipToNextAdvancesCurrentItem() async {
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

    await store.send(.skipToNext) {
      $0.session?.albumQueue.currentIndex = 1
      $0.session?.progress = .zero
    }

    #expect(await recorder.skipToNextCount == 1)
  }

  @Test
  func skipToNextWithSingleItemRestartsCurrentItem() async {
    let item = playbackItem("track-1")
    let recorder = PlaybackCommandRecorder()
    let store = TestStore(initialState: .init(session: .init(
      currentItem: item,
      progress: .init(elapsedTime: 42, duration: 180),
    ))) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.seek = { time in
        await recorder.recordSeek(time)
      }
    }

    await store.send(.skipToNext) {
      $0.session?.progress = .init(duration: 180)
    }

    #expect(await recorder.seekTimes == [0])
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
      $0.playback.seek = { time in
        await recorder.recordSeek(time)
      }
    }

    await store.send(.skipToPrevious) {
      $0.session?.progress = .init(duration: 180)
    }

    #expect(await recorder.seekTimes == [0])
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

    await store.send(.skipToPrevious) {
      $0.session?.albumQueue.currentIndex = 0
      $0.session?.progress = .zero
    }

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

    await store.send(.skipToPrevious) {
      $0.session?.albumQueue.currentIndex = 2
      $0.session?.progress = .zero
    }

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

private actor PlaybackOrderRecorder {
  var items: [PlaybackItem]?

  func record(_ items: [PlaybackItem]) {
    self.items = items
  }
}

private actor PlaybackCommandRecorder {
  var seekTimes: [TimeInterval] = []
  var skipToNextCount = 0
  var skipToPreviousCount = 0
  var openSettingsCount = 0

  func recordSeek(_ time: TimeInterval) {
    self.seekTimes.append(time)
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

private func playbackItem(
  _ id: ApprovedTrack.ID,
  allowsArtwork: Bool = true,
) -> PlaybackItem {
  PlaybackItem(
    id: id,
    title: "Track \(id.rawValue)",
    artistName: "Artist",
    artworkURL: nil,
    allowsArtwork: allowsArtwork,
  )
}
