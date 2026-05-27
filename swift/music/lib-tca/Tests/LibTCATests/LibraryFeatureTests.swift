import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct LibraryFeatureTests {
  @Test
  func loadsApprovedLibraryOnAppear() async {
    let library = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.loadApprovedLibrary = { library }
    }

    await store.send(.onAppear)
    await store.receive(.approvedLibraryLoaded(library)) {
      $0.status = .loaded(library)
    }
  }

  @Test
  func showsEmptyStateWhenApprovedLibraryIsEmpty() async {
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.loadApprovedLibrary = { .empty }
    }

    await store.send(.onAppear)
    await store.receive(.approvedLibraryLoaded(.empty)) {
      $0.status = .empty
    }
  }

  @Test
  func showsFailureStateWhenApprovedLibraryFailsToLoad() async {
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.loadApprovedLibrary = { throw TestError() }
    }

    await store.send(.onAppear)
    await store.receive(.approvedLibraryLoadFailed) {
      $0.status = .failed
    }
  }

  @Test
  func retryReturnsToLoading() async {
    let library = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init(status: .failed)) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.loadApprovedLibrary = { library }
    }

    await store.send(.onAppear) {
      $0.status = .loading
    }
    await store.receive(.approvedLibraryLoaded(library)) {
      $0.status = .loaded(library)
    }
  }

  @Test
  func albumsTitleNavigatesToAlbumsScreen() async {
    let library = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.albumsTitleTapped) {
      $0.destination = .albums(.init(albums: library.albums, tracks: library.tracks))
    }
  }

  @Test
  func albumTapNavigatesToAlbumScreen() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.albumTapped(album.id)) {
      $0.destination = .album(.init(
        album: album,
        tracks: library.tracks(for: album),
        transitionSourceID: album.id.rawValue,
      ))
    }
  }

  @Test
  func albumDetailDismissedClearsDestination() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    var state = LibraryFeature.State(status: .loaded(library))
    state.destination = .album(.init(
      album: album,
      tracks: library.tracks(for: album),
      transitionSourceID: album.id.rawValue,
    ))
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.albumDetailDismissed(album.id.rawValue)) {
      $0.destination = nil
    }
  }

  @Test
  func staleAlbumDetailDismissalDoesNotClearNewDestination() async {
    let library = ApprovedMusicLibrary.mock
    let oldAlbum = library.albums[0]
    let newAlbum = library.albums[1]
    var state = LibraryFeature.State(status: .loaded(library))
    state.destination = .album(.init(
      album: newAlbum,
      tracks: library.tracks(for: newAlbum),
      transitionSourceID: newAlbum.id.rawValue,
    ))
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.albumDetailDismissed(oldAlbum.id.rawValue))
  }

  @Test
  func albumDetailDismissalDoesNotClearOtherDestinations() async {
    let library = ApprovedMusicLibrary.mock
    var state = LibraryFeature.State(status: .loaded(library))
    state.destination = .albums(.init(albums: library.albums, tracks: library.tracks))
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.albumDetailDismissed(library.albums[0].id.rawValue))
  }

  @Test
  func directAlbumDetailPlayDelegateIsForwarded() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    var state = LibraryFeature.State(status: .loaded(library))
    state.destination = .album(.init(
      album: album,
      tracks: library.tracks(for: album),
    ))
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.destination(.presented(.album(.delegate(.playTrack(playbackItem("track-1")))))))
    await store.receive(.delegate(.playTrack(playbackItem("track-1"))))
  }

  @Test
  func albumListDetailPlayDelegateIsForwarded() async {
    let library = ApprovedMusicLibrary.mock
    var state = LibraryFeature.State(status: .loaded(library))
    state.destination = .albums(.init(albums: library.albums, tracks: library.tracks))
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.destination(.presented(.albums(.delegate(.playTrack(playbackItem("track-1")))))))
    await store.receive(.delegate(.playTrack(playbackItem("track-1"))))
  }

  @Test
  func artistsTitleNavigatesToArtistsScreen() async {
    let library = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.artistsTitleTapped) {
      $0.destination = .artists(.init(artists: library.artists))
    }
  }

  @Test
  func artistTapNavigatesToArtistScreen() async {
    let library = ApprovedMusicLibrary.mock
    let artist = library.artists[0]
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.artistTapped(artist.id)) {
      $0.destination = .artist(.init(
        title: artist.name,
        transitionSourceID: artist.id.rawValue,
      ))
    }
  }

  @Test
  func tracksTitleNavigatesToTracksScreen() async {
    let store = TestStore(initialState: .init(status: .loaded(.mock))) {
      LibraryFeature()
    }

    await store.send(.tracksTitleTapped) {
      $0.destination = .tracks(.init(title: "Tracks"))
    }
  }

  @Test
  func trackTapNavigatesToTrackScreen() async {
    let library = ApprovedMusicLibrary.mock
    let track = library.tracks[0]
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.trackTapped(track.id)) {
      $0.destination = .track(.init(
        title: track.title,
        transitionSourceID: track.id.rawValue,
        ))
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
