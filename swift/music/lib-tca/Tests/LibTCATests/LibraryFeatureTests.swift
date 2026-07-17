import ComposableArchitecture
import Foundation
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
  func artistPlayTapRequestsPlaybackForAllTopSongs() async {
    let topSongs = [
      ApprovedTrack(
        id: "song-1",
        title: "First",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/first.jpg"),
      ),
      ApprovedTrack(
        id: "song-2",
        title: "Second",
        artistName: "Artist",
        artworkURL: URL(string: "https://example.com/second.jpg"),
      ),
    ]
    let artist = ApprovedArtist(
      id: "artist-1",
      name: "Artist",
      topSongs: topSongs,
    )
    let library = ApprovedMusicLibrary(artists: [artist])
    let items = topSongs.map {
      PlaybackItem(track: $0, artworkURL: $0.artworkURL)
    }
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.artistPlayTapped(artist.id))
    await store.receive(.delegate(.artistPlaybackButtonTapped(items: items)))
  }

  @Test
  func artistTopSongTapQueuesAllTopSongsFromTappedSong() async {
    let topSongs = [
      ApprovedTrack(id: "song-1", title: "First", artistName: "Artist"),
      ApprovedTrack(id: "song-2", title: "Second", artistName: "Artist"),
    ]
    let artist = ApprovedArtist(
      id: "artist-1",
      name: "Artist",
      topSongs: topSongs,
    )
    let library = ApprovedMusicLibrary(artists: [artist])
    let items = topSongs.map {
      PlaybackItem(track: $0, artworkURL: $0.artworkURL)
    }
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.artistTopSongTapped(
      artistID: artist.id,
      trackID: topSongs[1].id,
    ))
    await store.receive(.delegate(.playNow(items: items, startIndex: 1)))
  }

  @Test
  func artistDetailQueueActionsDelegateApprovedTopSongs() async {
    let topSongs = [
      ApprovedTrack(id: "song-1", title: "First", artistName: "Artist"),
      ApprovedTrack(id: "song-2", title: "Second", artistName: "Artist"),
    ]
    let artist = ApprovedArtist(
      id: "artist-1",
      name: "Artist",
      topSongs: topSongs,
    )
    let library = ApprovedMusicLibrary(artists: [artist])
    let items = topSongs.map {
      PlaybackItem(track: $0, artworkURL: $0.artworkURL)
    }
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.artistTapped(artist.id)) {
      $0.path.append(.artist(.init(artistID: artist.id)))
    }
    await store.send(.path(.element(id: 0, action: .artist(.playNextTapped))))
    await store.receive(.delegate(.playNext(items: items)))
    await store.send(.path(.element(id: 0, action: .artist(.addToQueueTapped))))
    await store.receive(.delegate(.addToQueue(items: items)))
    await store.send(.path(.element(
      id: 0,
      action: .artist(.topSongPlayNextTapped(topSongs[1].id)),
    )))
    await store.receive(.delegate(.playNext(items: [items[1]])))
    await store.send(.path(.element(
      id: 0,
      action: .artist(.topSongAddToQueueTapped(topSongs[0].id)),
    )))
    await store.receive(.delegate(.addToQueue(items: [items[0]])))
  }

  @Test
  func albumCardQueueActionsDelegateLoadedTracksInOrder() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let library = ApprovedMusicLibrary(albums: [album])
    let items = playbackItems(album: album)
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.albumPlayNextTapped(album.id))
    await store.receive(.delegate(.playNext(items: items)))
    await store.send(.albumAddToQueueTapped(album.id))
    await store.receive(.delegate(.addToQueue(items: items)))
  }

  @Test
  func albumCardQueueActionLoadsTracksAndPreservesAlbumHint() async {
    var album = ApprovedMusicLibrary.mock.albums[0]
    let tracks = album.tracks
    album.tracks = []
    let albumID = album.id
    var loadedAlbum = album
    loadedAlbum.tracks = tracks
    let items = playbackItems(album: loadedAlbum)
    let library = ApprovedMusicLibrary(albums: [album])
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.loadAlbumTracks = { requestedAlbumID in
        #expect(requestedAlbumID == albumID)
        return tracks
      }
    }

    await store.send(.albumPlayNextTapped(albumID))
    await store.receive(.albumQueueTracksLoaded(albumID, tracks, .next))
    await store.receive(.delegate(.playNext(items: items)))
  }

  @Test
  func albumTapNavigatesToAlbumScreen() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.albumTapped(album.id)) {
      $0.path.append(.album(.init(
        album: album,
        transitionSourceID: album.id.rawValue,
      )))
    }
  }

  @Test
  func artistReleaseQueueActionsRouteThroughAlbumFlow() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let artist = ApprovedArtist(
      id: "artist-1",
      name: "Artist",
      releaseAlbumIds: [album.id],
    )
    let library = ApprovedMusicLibrary(albums: [album], artists: [artist])
    let items = playbackItems(album: album)
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.artistTapped(artist.id)) {
      $0.path.append(.artist(.init(artistID: artist.id)))
    }
    await store.send(.path(.element(
      id: 0,
      action: .artist(.releasePlayNextTapped(album.id)),
    )))
    await store.receive(.albumPlayNextTapped(album.id))
    await store.receive(.delegate(.playNext(items: items)))
    await store.send(.path(.element(
      id: 0,
      action: .artist(.releaseAddToQueueTapped(album.id)),
    )))
    await store.receive(.albumAddToQueueTapped(album.id))
    await store.receive(.delegate(.addToQueue(items: items)))
  }

  @Test
  func artistReleaseTapPushesAlbumAfterArtist() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let artist = ApprovedArtist(
      id: "artist-1",
      name: "Artist",
      releaseAlbumIds: [album.id],
    )
    let library = ApprovedMusicLibrary(albums: [album], artists: [artist])
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.artistTapped(artist.id)) {
      $0.path.append(.artist(.init(artistID: artist.id)))
    }
    await store.send(.path(.element(
      id: 0,
      action: .artist(.releaseTapped(album.id)),
    ))) {
      $0.path.append(.album(.init(
        album: album,
        transitionSourceID: album.id.rawValue,
      )))
    }
  }

  @Test
  func albumDetailDismissalClearsAlbumDetail() async {
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

    await store.send(.path(.popFrom(id: 0))) {
      $0.path.removeAll()
    }
  }

  @Test
  func albumTapReplacesCurrentAlbumDetail() async {
    let library = ApprovedMusicLibrary.mock
    let oldAlbum = library.albums[0]
    let newAlbum = library.albums[1]
    var state = LibraryFeature.State(status: .loaded(library))
    state.albumDetail = .init(
      album: oldAlbum,
      transitionSourceID: oldAlbum.id.rawValue,
    )
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.albumTapped(newAlbum.id)) {
      $0.albumDetail = .init(
        album: newAlbum,
        transitionSourceID: newAlbum.id.rawValue,
      )
    }
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
    await store.send(.path(.element(
      id: 0,
      action: .album(.delegate(.playNow(items: items, startIndex: 0))),
    )))
    await store.receive(.delegate(.playNow(items: items, startIndex: 0)))
  }
}
