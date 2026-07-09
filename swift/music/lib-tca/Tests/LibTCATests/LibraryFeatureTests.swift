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
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { nil }
      $0.approvedMusic.loadRemoteApprovedLibrary = { library }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.approvedLibraryLoaded(library)) {
      $0.status = .loaded(library)
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func showsEmptyStateWhenApprovedLibraryHasNoMusic() async {
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { nil }
      $0.approvedMusic.loadRemoteApprovedLibrary = { .empty }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.approvedLibraryLoaded(.empty)) {
      $0.status = .empty
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func showsLibraryWhenApprovedLibraryHasOnlyArtists() async {
    let library = ApprovedMusicLibrary(albums: [], artists: ApprovedMusicLibrary.mock.artists)
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { nil }
      $0.approvedMusic.loadRemoteApprovedLibrary = { library }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.approvedLibraryLoaded(library)) {
      $0.status = .loaded(library)
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func showsFailureStateWhenApprovedLibraryFailsToLoad() async {
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { nil }
      $0.approvedMusic.loadRemoteApprovedLibrary = { throw TestError() }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.approvedLibraryLoadFailed) {
      $0.status = .failed
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func showsSubscriptionRequiredWhenApprovedLibraryRequiresPayment() async {
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { nil }
      $0.approvedMusic
        .loadRemoteApprovedLibrary = { throw ApprovedMusicClientError.subscriptionRequired }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.approvedLibrarySubscriptionRequired) {
      $0.status = .subscriptionRequired
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func retryReturnsToLoading() async {
    let library = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init(
      status: .failed,
      hasStartedInitialLibraryLoad: true,
    )) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { nil }
      $0.approvedMusic.loadRemoteApprovedLibrary = { library }
    }

    await store.send(.retryButtonTapped) {
      $0.status = .loading
      $0.isRefreshingRemoteLibrary = true
    }
    await store.receive(.approvedLibraryLoaded(library)) {
      $0.status = .loaded(library)
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func appearingAgainDoesNotRefreshLibrary() async {
    let store = TestStore(initialState: .init(
      status: .loaded(.mock),
      hasStartedInitialLibraryLoad: true,
    )) {
      LibraryFeature()
    }

    await store.send(.onAppear)
  }

  @Test
  func pullToRefreshReloadsRemoteLibrary() async {
    let cached = cachedApprovedMusicLibrary
    let remote = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init(status: .loaded(cached))) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadRemoteApprovedLibrary = { remote }
    }

    await store.send(.refreshPulled) {
      $0.isRefreshingRemoteLibrary = true
    }
    await store.receive(.approvedLibraryLoaded(remote)) {
      $0.status = .loaded(remote)
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func refreshPresentationStaysVisibleForMinimumDuration() async {
    let clock = TestClock()
    let cached = cachedApprovedMusicLibrary
    let remote = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init(status: .loaded(cached))) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = clock
      $0.approvedMusic.loadRemoteApprovedLibrary = { remote }
    }

    await store.send(.refreshPulled) {
      $0.isRefreshingRemoteLibrary = true
    }
    await store.receive(.approvedLibraryLoaded(remote)) {
      $0.status = .loaded(remote)
    }
    await clock.advance(by: .milliseconds(1500))
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func loadsCachedApprovedLibraryBeforeRefreshingRemoteLibrary() async {
    let cached = cachedApprovedMusicLibrary
    let remote = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { cached }
      $0.approvedMusic.loadRemoteApprovedLibrary = { remote }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.cachedApprovedLibraryLoaded(cached)) {
      $0.status = .loaded(cached)
    }
    await store.receive(.approvedLibraryLoaded(remote)) {
      $0.status = .loaded(remote)
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func loadsCachedEmptyStateBeforeRefreshingRemoteLibrary() async {
    let remote = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { .empty }
      $0.approvedMusic.loadRemoteApprovedLibrary = { remote }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.cachedApprovedLibraryLoaded(.empty)) {
      $0.status = .empty
    }
    await store.receive(.approvedLibraryLoaded(remote)) {
      $0.status = .loaded(remote)
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func keepsCachedApprovedLibraryWhenRemoteRefreshFails() async {
    let cached = cachedApprovedMusicLibrary
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { cached }
      $0.approvedMusic.loadRemoteApprovedLibrary = { throw TestError() }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.cachedApprovedLibraryLoaded(cached)) {
      $0.status = .loaded(cached)
    }
    await store.receive(.approvedLibraryLoadFailed)
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func subscriptionRequiredOverridesCachedApprovedLibrary() async {
    let cached = cachedApprovedMusicLibrary
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { cached }
      $0.approvedMusic
        .loadRemoteApprovedLibrary = { throw ApprovedMusicClientError.subscriptionRequired }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.cachedApprovedLibraryLoaded(cached)) {
      $0.status = .loaded(cached)
    }
    await store.receive(.approvedLibrarySubscriptionRequired) {
      $0.status = .subscriptionRequired
    }
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
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
