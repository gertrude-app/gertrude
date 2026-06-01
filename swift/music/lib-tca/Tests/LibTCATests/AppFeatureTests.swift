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
  func libraryPlayAlbumDelegateStartsAlbumQueuePlayback() async {
    let items = [
      playbackItem("track-1"),
      playbackItem("track-2", allowsArtwork: false),
      playbackItem("track-3"),
    ]
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.library(.delegate(.playAlbum(items: items, startIndex: 1))))
    await store.receive(.playback(.playAlbumQueue(items: items, startIndex: 1))) {
      $0.playback.session = .init(albumQueue: .init(items: items, currentIndex: 1))
    }
  }

  @Test
  func libraryTogglePlayPauseDelegateTogglesPlayback() async {
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.library(.delegate(.togglePlayPause)))
    await store.receive(.playback(.togglePlayPause))
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
    state.library.albumDetail = .init(
      album: album,
      tracks: library.tracks(for: album),
      transitionSourceID: album.id.rawValue,
    )
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.playback(.playTrack(item))) {
      $0.playback.session = .init(currentItem: item)
      guard var albumDetail = $0.library.albumDetail else { return }
      albumDetail.playStatus = .playing
      albumDetail.currentTrackID = track.id
      $0.library.albumDetail = albumDetail
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
