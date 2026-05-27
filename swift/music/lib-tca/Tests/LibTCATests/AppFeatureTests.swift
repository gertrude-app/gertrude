import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct AppFeatureTests {
  @Test
  func updatesSearchText() async {
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.searchTextChanged("Väsen")) {
      $0.searchText = "Väsen"
    }
  }

  @Test
  func libraryPlayAlbumDelegateStartsTracksInOrderPlayback() async {
    let items = [playbackItem("track-1"), playbackItem("track-2", allowsArtwork: false)]
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.library(.delegate(.playAlbum(items))))
    await store.receive(.playback(.playTracksInOrder(items))) {
      $0.playback.status = .playingTracksInOrder(items)
    }
  }

  @Test
  func libraryPlayTrackDelegateStartsTrackPlayback() async {
    let item = playbackItem("track-1")
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.library(.delegate(.playTrack(item))))
    await store.receive(.playback(.playTrack(item))) {
      $0.playback.status = .playingTrack(item)
    }
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

