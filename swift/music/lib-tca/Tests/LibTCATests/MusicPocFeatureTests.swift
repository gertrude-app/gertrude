import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct MusicPocFeatureTests {
  @Test
  func authorizationSuccess() async {
    let store = TestStore(initialState: .init()) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.requestAuthorization = { true }
    }

    await store.send(.authorizeButtonTapped) {
      $0.status = .authorizing
    }
    await store.receive(.authorizationResponse(true)) {
      $0.status = .readyToPlay
    }
  }

  @Test
  func authorizationDenied() async {
    let store = TestStore(initialState: .init()) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.requestAuthorization = { false }
    }

    await store.send(.authorizeButtonTapped) {
      $0.status = .authorizing
    }
    await store.receive(.authorizationResponse(false)) {
      $0.status = .denied
    }
  }

  @Test
  func authorizationFailure() async {
    let store = TestStore(initialState: .init()) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.requestAuthorization = { throw TestError() }
    }

    await store.send(.authorizeButtonTapped) {
      $0.status = .authorizing
    }
    await store.receive(.authorizationFailed) {
      $0.status = .failed("Unable to authorize Apple Music.")
    }
  }

  @Test
  func playSuccessWithoutArtworkBlocking() async {
    let store = TestStore(initialState: .init(status: .readyToPlay)) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.playSong = { id, blocksArtwork in
        #expect(id == "1758369112")
        #expect(blocksArtwork == false)
      }
    }

    await store.send(.playPauseButtonTapped) {
      $0.isStarting = true
    }
    await store.receive(.playResponse) {
      $0.isPlaying = true
      $0.isStarting = false
    }
  }

  @Test
  func playSuccessWithArtworkBlocking() async {
    let store = TestStore(initialState: .init(status: .readyToPlay, blocksArtwork: true)) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.playSong = { id, blocksArtwork in
        #expect(id == "1758369112")
        #expect(blocksArtwork == true)
      }
    }

    await store.send(.playPauseButtonTapped) {
      $0.isStarting = true
    }
    await store.receive(.playResponse) {
      $0.isPlaying = true
      $0.isStarting = false
    }
  }

  @Test
  func pausePlayingTrack() async {
    let store = TestStore(initialState: .init(status: .readyToPlay, isPlaying: true)) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.pause = {}
    }

    await store.send(.playPauseButtonTapped) {
      $0.isPlaying = false
    }
    await store.receive(.pauseResponse)
  }

  @Test
  func toggleArtworkBlockingWhileStopped() async {
    let store = TestStore(initialState: .init(status: .readyToPlay)) {
      MusicPocFeature()
    }

    await store.send(.artworkBlockingChanged(true)) {
      $0.blocksArtwork = true
    }
  }

  @Test
  func toggleArtworkBlockingWhilePlaying() async {
    let store = TestStore(initialState: .init(status: .readyToPlay, isPlaying: true)) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.playSong = { id, blocksArtwork in
        #expect(id == "1758369112")
        #expect(blocksArtwork == true)
      }
    }

    await store.send(.artworkBlockingChanged(true)) {
      $0.blocksArtwork = true
      $0.isStarting = true
    }
    await store.receive(.playResponse) {
      $0.isStarting = false
    }
  }

  @Test
  func playFailure() async {
    let store = TestStore(initialState: .init(status: .readyToPlay)) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.playSong = { _, _ in throw TestError() }
    }

    await store.send(.playPauseButtonTapped) {
      $0.isStarting = true
    }
    await store.receive(.playFailed) {
      $0.isStarting = false
      $0.status = .failed("Unable to start playback.")
    }
  }
}

private struct TestError: Error {}
