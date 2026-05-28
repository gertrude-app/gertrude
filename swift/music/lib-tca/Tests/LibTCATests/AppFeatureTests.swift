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
  func updatesNowPlayingPresentation() async {
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.nowPlayingPresentationChanged(true)) {
      $0.isNowPlayingPresented = true
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

  @Test
  func playbackStateUpdatesDirectAlbumDetailPlayingState() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let track = library.tracks(for: album)[1]
    let item = PlaybackItem(
      track: track,
      artworkURL: album.artworkURL,
      allowsArtwork: album.showsArtwork,
    )
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    state.library.destination = .album(.init(
      album: album,
      tracks: library.tracks(for: album),
      transitionSourceID: album.id.rawValue,
    ))
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.playback(.playTrack(item))) {
      $0.playback.status = .playingTrack(item)
      guard case .some(.album(var albumDetail)) = $0.library.destination else { return }
      albumDetail.isPlaying = true
      albumDetail.playingTrackID = track.id
      $0.library.destination = .album(albumDetail)
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

