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
  func playSuccess() async {
    let store = TestStore(initialState: .init(status: .readyToPlay)) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.playTestSong = {}
    }

    await store.send(.playButtonTapped)
    await store.receive(.playResponse) {
      $0.status = .playing
    }
  }

  @Test
  func playFailure() async {
    let store = TestStore(initialState: .init(status: .readyToPlay)) {
      MusicPocFeature()
    } withDependencies: {
      $0.appleMusic.playTestSong = { throw TestError() }
    }

    await store.send(.playButtonTapped)
    await store.receive(.playFailed) {
      $0.status = .failed("Unable to start playback.")
    }
  }
}

private struct TestError: Error {}
