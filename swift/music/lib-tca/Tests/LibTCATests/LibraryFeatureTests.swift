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
  func showsEmptyStateWhenApprovedLibraryHasNoAlbums() async {
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
  func showsSubscriptionRequiredWhenApprovedLibraryRequiresPayment() async {
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.loadApprovedLibrary = { throw ApprovedMusicClientError.subscriptionRequired }
    }

    await store.send(.onAppear)
    await store.receive(.approvedLibrarySubscriptionRequired) {
      $0.status = .subscriptionRequired
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
  func albumTapNavigatesToAlbumScreen() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.albumTapped(album.id)) {
      $0.albumDetail = .init(
        album: album,
        transitionSourceID: album.id.rawValue,
      )
    }
  }

  @Test
  func albumDetailDismissedClearsAlbumDetail() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    var state = LibraryFeature.State(status: .loaded(library))
    state.albumDetail = .init(
      album: album,
      transitionSourceID: album.id.rawValue,
    )
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.albumDetailDismissed(album.id.rawValue)) {
      $0.albumDetail = nil
    }
  }

  @Test
  func staleAlbumDetailDismissalDoesNotClearNewAlbumDetail() async {
    let library = ApprovedMusicLibrary.mock
    let oldAlbum = library.albums[0]
    let newAlbum = library.albums[1]
    var state = LibraryFeature.State(status: .loaded(library))
    state.albumDetail = .init(
      album: newAlbum,
      transitionSourceID: newAlbum.id.rawValue,
    )
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.albumDetailDismissed(oldAlbum.id.rawValue))
  }

  @Test
  func albumDetailPlayDelegateIsForwarded() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    var state = LibraryFeature.State(status: .loaded(library))
    state.albumDetail = .init(album: album)
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    let items = [playbackItem("track-1")]
    await store.send(.albumDetail(.presented(.delegate(.playAlbum(items: items, startIndex: 0)))))
    await store.receive(.delegate(.playAlbum(items: items, startIndex: 0)))
  }
}

private struct TestError: Error {}

private func playbackItem(_ id: ApprovedTrack.ID) -> PlaybackItem {
  PlaybackItem(
    id: id,
    title: "Track \(id.rawValue)",
    artistName: "Artist",
    artworkURL: nil,
  )
}
