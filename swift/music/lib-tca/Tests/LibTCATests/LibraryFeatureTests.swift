import ComposableArchitecture
import CustomDump
import Foundation
import MusicRoute
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
    await store.receive(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))
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
    await store.receive(.delegate(.approvedTrackIDsUpdated([])))
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
    await store.receive(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))
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
  func showsMusicUnavailableWhenApprovedLibraryRequiresPayment() async {
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { nil }
      $0.approvedMusic
        .loadRemoteApprovedLibrary = { throw ApprovedMusicClientError.musicAccessUnavailable }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.approvedLibraryMusicAccessUnavailable) {
      $0.status = .musicAccessUnavailable
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
    await store.receive(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))
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
    await store.receive(.delegate(.approvedTrackIDsUpdated(remote.approvedTrackIDs)))
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
    await store.receive(.delegate(.approvedTrackIDsUpdated(remote.approvedTrackIDs)))
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
    await store.receive(.delegate(.approvedTrackIDsUpdated(cached.approvedTrackIDs)))
    await store.receive(.approvedLibraryLoaded(remote)) {
      $0.status = .loaded(remote)
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(remote.approvedTrackIDs)))
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
    await store.receive(.delegate(.approvedTrackIDsUpdated([])))
    await store.receive(.approvedLibraryLoaded(remote)) {
      $0.status = .loaded(remote)
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(remote.approvedTrackIDs)))
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
    await store.receive(.delegate(.approvedTrackIDsUpdated(cached.approvedTrackIDs)))
    await store.receive(.approvedLibraryLoadFailed)
    await store.receive(.refreshPresentationFinished) {
      $0.isRefreshingRemoteLibrary = false
    }
  }

  @Test
  func musicAccessUnavailableOverridesCachedApprovedLibrary() async {
    let cached = cachedApprovedMusicLibrary
    let store = TestStore(initialState: .init()) {
      LibraryFeature()
    } withDependencies: {
      $0.continuousClock = ImmediateClock()
      $0.approvedMusic.loadCachedApprovedLibrary = { cached }
      $0.approvedMusic
        .loadRemoteApprovedLibrary = { throw ApprovedMusicClientError.musicAccessUnavailable }
    }

    await store.send(.onAppear) {
      $0.isRefreshingRemoteLibrary = true
      $0.hasStartedInitialLibraryLoad = true
    }
    await store.receive(.cachedApprovedLibraryLoaded(cached)) {
      $0.status = .loaded(cached)
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(cached.approvedTrackIDs)))
    await store.receive(.approvedLibraryMusicAccessUnavailable) {
      $0.status = .musicAccessUnavailable
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
    await store.receive(.delegate(.artistPlaybackButtonTapped(
      items: items,
      context: PlaybackContext(
        identity: .artist(artist.id),
        title: artist.name,
      ),
    )))
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
    await store.receive(.delegate(.playNow(
      items: items,
      startIndex: 1,
      context: PlaybackContext(
        identity: .artist(artist.id),
        title: artist.name,
      ),
    )))
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
  func albumCardQueueActionDoesNothingForIncompleteAlbum() async {
    var album = ApprovedMusicLibrary.mock.albums[0]
    album.tracks = []
    let library = ApprovedMusicLibrary(albums: [album])
    let store = TestStore(initialState: .init(status: .loaded(library))) {
      LibraryFeature()
    }

    await store.send(.albumPlayNextTapped(album.id))
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
    await store.receive(.delegate(.playNow(
      items: items,
      startIndex: 0,
      context: PlaybackContext(
        identity: .album(album.id),
        title: album.title,
      ),
    )))
  }

  @Test
  func refreshDoesNotRacePlaylistMutation() async {
    var state = LibraryFeature.State(status: .loaded(.mock))
    state.isPlaylistMutationInFlight = true
    let store = TestStore(initialState: state) {
      LibraryFeature()
    }

    await store.send(.refreshPulled)
  }

  @Test
  func createsEmptyPlaylistAndStaysInLibrary() async {
    let playlist = self.playlistLibrary().playlists[0]
    let updatedLibrary = ApprovedMusicLibrary(playlists: [playlist])
    let now = Date(timeIntervalSince1970: 100)
    let recorder = LibraryRecencyRecorder()
    let store = TestStore(initialState: LibraryFeature.State(status: .empty)) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.createPlaylist = { _ in .updated(updatedLibrary) }
      $0.date.now = now
      $0.libraryCollectionRecency.save = { await recorder.save($0) }
    }

    await store.send(.createPlaylistSubmitted("  Favorites  ")) {
      $0.isPlaylistMutationInFlight = true
      $0.playlistIDsBeforeCreate = []
    }
    await store.receive(.playlistMutationResponse(
      .updated(updatedLibrary),
      rollback: nil,
    )) {
      $0.isPlaylistMutationInFlight = false
      $0.status = .loaded(updatedLibrary)
      $0.playlistIDsBeforeCreate = nil
      $0.collectionRecency.recordPlay(
        of: .playlist(playlist.id),
        observedAddedAt: playlist.createdAt,
        at: now,
      )
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(updatedLibrary.approvedTrackIDs)))
    await store.finish()

    let savedRecency = await recorder.value
    expectNoDifference(savedRecency, store.state.collectionRecency)
  }

  @Test
  func newlyCreatedPlaylistSortsAbovePreviouslyPlayedCollection() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let playlist = self.playlistLibrary().playlists[0]
    let updatedLibrary = {
      var updatedLibrary = library
      updatedLibrary.playlists = [playlist]
      return updatedLibrary
    }()
    var state = LibraryFeature.State(status: .loaded(library))
    state.collectionRecency.recordPlay(
      of: .album(album.id),
      observedAddedAt: album.addedAt,
      at: Date(timeIntervalSince1970: 90),
    )
    let now = Date(timeIntervalSince1970: 100)
    let store = TestStore(initialState: state) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.createPlaylist = { _ in .updated(updatedLibrary) }
      $0.date.now = now
    }

    await store.send(.createPlaylistSubmitted("Favorites")) {
      $0.isPlaylistMutationInFlight = true
      $0.playlistIDsBeforeCreate = Set(library.playlists.map(\.id))
    }
    await store.receive(.playlistMutationResponse(
      .updated(updatedLibrary),
      rollback: nil,
    )) {
      $0.isPlaylistMutationInFlight = false
      $0.status = .loaded(updatedLibrary)
      $0.playlistIDsBeforeCreate = nil
      $0.collectionRecency.recordPlay(
        of: .playlist(playlist.id),
        observedAddedAt: playlist.createdAt,
        at: now,
      )
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(updatedLibrary.approvedTrackIDs)))
    await store.finish()

    let firstItemID = updatedLibrary.collectionItems(
      recency: store.state.collectionRecency,
    ).first?.id
    expectNoDifference(
      firstItemID,
      .some("playlist-\(playlist.id.rawValue.uuidString)"),
    )
  }

  @Test
  func duplicateTrackRequiresConfirmationBeforeAddingAgain() async {
    let library = self.playlistLibrary()
    let playlist = library.playlists[0]
    let album = library.albums[0]
    let track = album.tracks[0]
    let confirmation = MusicPlaylistDuplicateConfirmation.track(
      playlistId: playlist.id.rawValue,
      duplicate: .init(
        trackId: track.id.rawValue,
        title: track.title,
        existingCount: 1,
      ),
    )
    var updatedLibrary = library
    updatedLibrary.playlists[0].revision += 1
    updatedLibrary.playlists[0].entries.append(.init(
      id: .init(rawValue: UUID(4)),
      track: track,
    ))
    let results = PlaylistMutationResultSequence([
      .duplicateConfirmationRequired(
        library: library,
        confirmation: confirmation,
      ),
      .updated(updatedLibrary),
    ])
    let source = MusicPlaylistSourceSelection.track(
      trackId: track.id.rawValue,
      albumId: album.id.rawValue,
    )
    let store = TestStore(initialState: LibraryFeature.State(status: .loaded(library))) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.addToPlaylist = { _ in await results.next() }
    }

    await store.send(.addTrackToPlaylistTapped(
      trackID: track.id,
      albumID: album.id,
    )) {
      $0.addToPlaylist = .init(source: source)
    }
    await store.send(.addToPlaylistDestinationSelected(playlist.id)) {
      $0.addToPlaylist?.destinationPlaylistID = playlist.id
      $0.isPlaylistMutationInFlight = true
    }
    await store.receive(.addToPlaylistMutationResponse(.confirmationRequired(
      library,
      confirmation,
    ))) {
      $0.isPlaylistMutationInFlight = false
      $0.addToPlaylist?.confirmation = confirmation
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))
    await store.send(.addToPlaylistDuplicateResolutionSelected(.addAgain)) {
      $0.addToPlaylist?.confirmation = nil
      $0.isPlaylistMutationInFlight = true
    }
    await store.receive(.addToPlaylistMutationResponse(.updated(updatedLibrary))) {
      $0.addToPlaylist = nil
      $0.isPlaylistMutationInFlight = false
      $0.status = .loaded(updatedLibrary)
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(updatedLibrary.approvedTrackIDs)))
  }

  @Test
  func directPlaylistRenameUsesTheAuthoritativeMutationPipeline() async {
    let library = self.playlistLibrary()
    let playlist = library.playlists[0]
    let updatedLibrary = {
      var updatedLibrary = library
      updatedLibrary.playlists[0].name = "Road Trip"
      updatedLibrary.playlists[0].revision = 2
      return updatedLibrary
    }()
    let store = TestStore(initialState: LibraryFeature.State(status: .loaded(library))) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.renamePlaylist = { _ in .updated(updatedLibrary) }
    }

    var optimisticLibrary = library
    optimisticLibrary.playlists[0].name = "Road Trip"
    await store.send(.playlistRenameSubmitted(
      playlistID: playlist.id,
      expectedRevision: playlist.revision,
      name: "  Road Trip  ",
    )) {
      $0.isPlaylistMutationInFlight = true
      $0.applyLibrary(optimisticLibrary)
    }
    await store.receive(.playlistMutationResponse(
      .updated(updatedLibrary),
      rollback: library,
    )) {
      $0.isPlaylistMutationInFlight = false
      $0.applyLibrary(updatedLibrary)
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(updatedLibrary.approvedTrackIDs)))
  }

  @Test
  func failedRenameRollsBackOptimisticName() async {
    let library = self.playlistLibrary()
    let playlist = library.playlists[0]
    var state = LibraryFeature.State(status: .loaded(library))
    state.playlistDetail = .init(playlist: playlist)
    let pathID = state.path.ids.last!
    let store = TestStore(initialState: state) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.renamePlaylist = { _ in throw TestError() }
    }

    var optimisticLibrary = library
    optimisticLibrary.playlists[0].name = "New Name"
    await store.send(.path(.element(
      id: pathID,
      action: .playlist(.delegate(.rename("New Name"))),
    ))) {
      $0.isPlaylistMutationInFlight = true
      $0.applyLibrary(optimisticLibrary)
    }
    await store.receive(.playlistMutationResponse(.failed, rollback: library)) {
      $0.isPlaylistMutationInFlight = false
      $0.playlistMutationFailure = .failed
      $0.applyLibrary(library)
    }
  }

  @Test
  func playlistMutationLosingMusicAccessGoesUnavailable() async {
    let library = self.playlistLibrary()
    let playlist = library.playlists[0]
    var state = LibraryFeature.State(status: .loaded(library))
    state.playlistDetail = .init(playlist: playlist)
    let pathID = state.path.ids.last!
    let store = TestStore(initialState: state) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic
        .renamePlaylist = { _ in throw ApprovedMusicClientError.musicAccessUnavailable }
    }

    var optimisticLibrary = library
    optimisticLibrary.playlists[0].name = "New Name"
    await store.send(.path(.element(
      id: pathID,
      action: .playlist(.delegate(.rename("New Name"))),
    ))) {
      $0.isPlaylistMutationInFlight = true
      $0.applyLibrary(optimisticLibrary)
    }
    await store.receive(.approvedLibraryMusicAccessUnavailable) {
      $0.status = .musicAccessUnavailable // not .playlistMutationFailure, and no stale library
      $0.isPlaylistMutationInFlight = false // latch guards every mutation, must not stick
    }
  }

  @Test
  func addToPlaylistLosingMusicAccessDismissesSheetAndFreesLaterMutations() async {
    let library = self.playlistLibrary()
    let playlist = library.playlists[0]
    let album = library.albums[0]
    let track = album.tracks[0]
    let store = TestStore(initialState: LibraryFeature.State(status: .loaded(library))) {
      LibraryFeature()
    } withDependencies: {
      $0.approvedMusic.addToPlaylist = { _ in
        throw ApprovedMusicClientError.musicAccessUnavailable
      }
      $0.approvedMusic.createPlaylist = { _ in .updated(library) }
      $0.date.now = Date(timeIntervalSince1970: 100)
    }

    await store.send(.addTrackToPlaylistTapped(trackID: track.id, albumID: album.id)) {
      $0.addToPlaylist = .init(source: .track(
        trackId: track.id.rawValue,
        albumId: album.id.rawValue,
      ))
    }
    await store.send(.addToPlaylistDestinationSelected(playlist.id)) {
      $0.addToPlaylist?.destinationPlaylistID = playlist.id
      $0.isPlaylistMutationInFlight = true
    }
    await store.receive(.approvedLibraryMusicAccessUnavailable) {
      $0.status = .musicAccessUnavailable
      $0.addToPlaylist = nil // sheet would otherwise stay open over the unavailable wall
      $0.isPlaylistMutationInFlight = false
    }

    await store.send(.approvedLibraryLoaded(library)) { // account reactivated
      $0.applyLibrary(library)
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))
    await store.send(.createPlaylistSubmitted("Road Trip")) { // not swallowed by a stuck latch
      $0.isPlaylistMutationInFlight = true
      $0.playlistIDsBeforeCreate = [playlist.id]
    }
    await store.receive(.playlistMutationResponse(.updated(library), rollback: nil)) {
      $0.isPlaylistMutationInFlight = false
      $0.playlistIDsBeforeCreate = nil
    }
    await store.receive(.delegate(.approvedTrackIDsUpdated(library.approvedTrackIDs)))
  }

  @Test
  func collectionOrderUsesRecencyThenObservedAdditionDate() {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      addedAt: Date(timeIntervalSince1970: 10),
    )
    let artist = ApprovedArtist(
      id: "artist",
      name: "Artist",
      addedAt: Date(timeIntervalSince1970: 30),
    )
    let playlist = MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Playlist",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 20),
      updatedAt: Date(timeIntervalSince1970: 20),
    )
    let library = ApprovedMusicLibrary(
      albums: [album],
      artists: [artist],
      playlists: [playlist],
    )
    var recency = LibraryCollectionRecency()

    #expect(library.collectionItems(recency: recency).map(\.id) == [
      "artist-artist",
      "playlist-\(playlist.id.rawValue.uuidString)",
      "album-album",
    ])

    recency.recordPlay(
      of: .album(album.id),
      observedAddedAt: album.addedAt,
      at: Date(timeIntervalSince1970: 40),
    )
    #expect(library.collectionItems(recency: recency).map(\.id) == [
      "album-album",
      "artist-artist",
      "playlist-\(playlist.id.rawValue.uuidString)",
    ])

    let reapprovedAlbum = ApprovedAlbum(
      id: album.id,
      title: album.title,
      artistName: album.artistName,
      addedAt: Date(timeIntervalSince1970: 15),
    )
    let reapprovedLibrary = ApprovedMusicLibrary(
      albums: [reapprovedAlbum],
      artists: [artist],
      playlists: [playlist],
    )
    #expect(reapprovedLibrary.collectionItems(recency: recency).map(\.id) == [
      "artist-artist",
      "playlist-\(playlist.id.rawValue.uuidString)",
      "album-album",
    ])
  }

  @Test
  func successfulCollectionPlayRecordsDeviceLocalRecency() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let identity = LibraryCollectionIdentity.album(album.id)
    let now = Date(timeIntervalSince1970: 1000)
    let recorder = LibraryRecencyRecorder()
    let store = TestStore(initialState: LibraryFeature.State(status: .loaded(library))) {
      LibraryFeature()
    } withDependencies: {
      $0.date.now = now
      $0.libraryCollectionRecency.save = { await recorder.save($0) }
    }

    await store.send(.collectionPlayNowSucceeded(identity)) {
      $0.collectionRecency.recordPlay(
        of: identity,
        observedAddedAt: album.addedAt,
        at: now,
      )
    }
    await store.finish()

    let savedRecency = await recorder.value
    #expect(savedRecency == store.state.collectionRecency)
  }

  private func playlistLibrary() -> ApprovedMusicLibrary {
    var library = ApprovedMusicLibrary.mock
    let playlist = MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Favorites",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 10),
      updatedAt: Date(timeIntervalSince1970: 10),
      entries: [
        .init(
          id: .init(rawValue: UUID(2)),
          track: library.albums[0].tracks[0],
        ),
      ],
    )
    library.playlists = [playlist]
    return library
  }
}

private actor PlaylistMutationResultSequence {
  private var results: [MusicPlaylistMutationResult]

  init(_ results: [MusicPlaylistMutationResult]) {
    self.results = results
  }

  func next() -> MusicPlaylistMutationResult {
    self.results.removeFirst()
  }
}

private actor LibraryRecencyRecorder {
  private(set) var value: LibraryCollectionRecency?

  func save(_ value: LibraryCollectionRecency) {
    self.value = value
  }
}
