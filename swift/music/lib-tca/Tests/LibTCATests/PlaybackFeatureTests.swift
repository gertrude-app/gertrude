import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct PlaybackFeatureTests {
  @Test
  func playTrackUpdatesStatus() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playTrack(item)) {
      $0.status = .playingTrack(item)
    }
  }

  @Test
  func playTracksInOrderUpdatesStatus() async {
    let items = [playbackItem("track-1"), playbackItem("track-2", allowsArtwork: false)]
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playTracksInOrder(items)) {
      $0.status = .playingTracksInOrder(items)
    }
  }

  @Test
  func playTracksInOrderWithEmptyTracksDoesNothing() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    }

    await store.send(.playTracksInOrder([]))
  }

  @Test
  func playbackFailureStopsPlayback() async {
    let store = TestStore(initialState: .init()) {
      PlaybackFeature()
    } withDependencies: {
      $0.playback.playTrack = { _ in throw TestError() }
    }

    let item = playbackItem("track-1")

    await store.send(.playTrack(item)) {
      $0.status = .playingTrack(item)
    }
    await store.receive(.playbackFailed) {
      $0.status = .stopped
    }
  }

  @Test
  func stopUpdatesStatus() async {
    let store = TestStore(initialState: .init(status: .playingTrack(playbackItem("track-1")))) {
      PlaybackFeature()
    }

    await store.send(.stop) {
      $0.status = .stopped
    }
  }
}

private struct TestError: Error {}

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
