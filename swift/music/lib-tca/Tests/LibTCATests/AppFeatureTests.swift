import ComposableArchitecture
import CustomDump
import Foundation
import Testing

@testable import LibTCA

@MainActor
struct AppFeatureTests {
  @Test
  func tabSelectionUpdatesState() async {
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.tabSelected(.queue)) {
      $0.selectedTab = .queue
    }
  }

  @Test
  func queueBrowseLibraryButtonSelectsLibraryTab() async {
    var state = AppFeature.State()
    state.selectedTab = .queue
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.queueBrowseLibraryButtonTapped) {
      $0.selectedTab = .library
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
  func nowPlayingAddToPlaylistTapPresentsCurrentTrackChooser() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let track = album.tracks[0]
    let item = PlaybackItem(
      track: track,
      artworkURL: album.artworkURL,
      albumID: album.id,
    )
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    state.search.applyLibraryStatus(.loaded(library))
    state.playback.session = .init(currentItem: item)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.nowPlayingAddToPlaylistTapped)
    await store.receive(.library(.addTrackToPlaylistTapped(
      trackID: track.id,
      albumID: album.id,
    ))) {
      $0.library.addToPlaylist = .init(source: .track(
        trackId: track.id.rawValue,
        albumId: album.id.rawValue,
      ))
    }
  }

  @Test
  func nowPlayingAddToPlaylistTapWithoutAlbumDoesNothing() async {
    let item = playbackItem("track-1")
    var state = AppFeature.State()
    state.playback.session = .init(currentItem: item)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.nowPlayingAddToPlaylistTapped)
  }

  @Test
  func queueEndingDismissesNowPlayingAndClearsPlaybackPresentation() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let item = playbackItems(album: album)[0]
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(.mock)
    state.library.albumDetail = .init(
      album: album,
      playStatus: .playing,
      currentTrackID: item.id,
    )
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.session = .init(currentItem: item)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.playback(.playbackEvent(.queueEnded))) {
      $0.isNowPlayingPresented = false
      $0.library.albumDetail?.currentTrackID = nil
      $0.library.albumDetail?.currentTrackPlayStatus = nil
      $0.library.albumDetail?.playStatus = nil
      $0.playback.hasAuthoritativeSnapshot = false
      $0.playback.session = nil
    }
  }

  @Test
  func losingMusicAccessRevokesCachedPlayback() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let item = playbackItems(album: album)[0]
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(.mock)
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.session = .init(currentItem: item)
    state.playback.approvedTrackIDs = [item.id] // was approved before the lapse
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.library(.approvedLibraryMusicAccessUnavailable)) {
      $0.library.status = .musicAccessUnavailable
      $0.search.applyLibraryStatus(.musicAccessUnavailable)
    }
    await store.receive(.library(.delegate(.approvedTrackIDsUpdated([]))))
    await store.receive(.playback(.approvedTrackIDsUpdated([]))) {
      $0.playback.approvedTrackIDs = []
    }
    await store.receive(.playback(.playbackEvent(.queueEnded))) {
      $0.isNowPlayingPresented = false
      $0.playback.hasAuthoritativeSnapshot = false
      $0.playback.session = nil // nothing left to keep listening to
    }
  }

  @Test
  func nowPlayingAlbumInfoTapDismissesNowPlayingAndPresentsCurrentAlbum() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let track = album.tracks[1]
    let item = PlaybackItem(
      track: track,
      artworkURL: album.artworkURL,
      albumID: album.id,
    )
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(library)
    state.playback.session = .init(playStatus: .playing, currentItem: item)
    state.selectedTab = .search
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.nowPlayingAlbumInfoTapped) {
      $0.isNowPlayingPresented = false
      $0.selectedTab = .library
      $0.library.albumDetail = .init(
        album: album,
        currentTrackID: track.id,
        currentTrackPlayStatus: .playing,
      )
    }
  }

  @Test
  func nowPlayingAlbumInfoTapPushesCurrentAlbumAgain() async {
    let loadedAlbum = ApprovedMusicLibrary.mock.albums[0]
    let track = loadedAlbum.tracks[1]
    var library = ApprovedMusicLibrary.mock
    library.albums[0].tracks = []
    let item = PlaybackItem(
      track: track,
      artworkURL: loadedAlbum.artworkURL,
      albumID: loadedAlbum.id,
    )
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(library)
    state.library.albumDetail = .init(
      album: loadedAlbum,
      transitionSourceID: loadedAlbum.id.rawValue,
    )
    state.playback.session = .init(playStatus: .playing, currentItem: item)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.nowPlayingAlbumInfoTapped) {
      $0.isNowPlayingPresented = false
      $0.library.path.append(.album(.init(
        album: library.albums[0],
      )))
    }

    #expect(store.state.library.path.count == 2)
    #expect(store.state.library.albumDetail?.album.tracks.isEmpty == true)
  }

  @Test
  func nowPlayingAlbumInfoTapPushesAfterAnotherAlbumDetail() async {
    let library = ApprovedMusicLibrary.mock
    let currentAlbum = library.albums[0]
    let visibleAlbum = library.albums[1]
    let track = currentAlbum.tracks[1]
    let item = PlaybackItem(
      track: track,
      artworkURL: currentAlbum.artworkURL,
      albumID: currentAlbum.id,
    )
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(library)
    state.library.albumDetail = .init(
      album: visibleAlbum,
      transitionSourceID: visibleAlbum.id.rawValue,
    )
    state.playback.session = .init(playStatus: .playing, currentItem: item)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.nowPlayingAlbumInfoTapped) {
      $0.isNowPlayingPresented = false
      $0.library.path.append(.album(.init(
        album: currentAlbum,
        currentTrackID: track.id,
        currentTrackPlayStatus: .playing,
      )))
    }

    #expect(store.state.library.path.count == 2)
  }

  @Test
  func nowPlayingAlbumInfoTapWithoutAlbumIDDoesNothing() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let item = PlaybackItem(
      id: album.tracks[0].id,
      title: album.tracks[0].title,
      artistName: album.tracks[0].artistName,
      artworkURL: album.artworkURL,
    )
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(.mock)
    state.playback.session = .init(currentItem: item)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.nowPlayingAlbumInfoTapped)
  }

  @Test
  func playbackSnapshotResolvesApprovedAlbumFromMetadata() async {
    let album = ApprovedAlbum(
      id: "album-1",
      title: "Known Album",
      artistName: "Known Artist",
    )
    let item = PlaybackItem(
      id: "track-1",
      title: "Track",
      artistName: "Known Artist",
      artworkURL: nil,
      albumTitle: "Known Album",
    )
    let snapshot = playbackSnapshot(items: [item])
    var state = AppFeature.State()
    state.library.status = .loaded(.init(albums: [album]))
    state.playback.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.lastCachedProgressBucket = 0
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.playback(.playbackEvent(.snapshotChanged(snapshot)))) {
      $0.playback.sourceAlbumIDs[item.id] = album.id
      $0.playback.session?.queue.entries[0] = PlaybackQueueEntry(
        id: "entry-0",
        item: item.withAlbumID(album.id),
      )
    }
    await store.receive(.playback(.saveCachedSession))
  }

  @Test
  func playbackSnapshotResolvesApprovedAlbumFromMusicKitRelationship() async {
    let album = ApprovedAlbum(
      id: "album-1",
      title: "Approved Album",
      artistName: "Artist",
    )
    let item = PlaybackItem(
      id: "track-1",
      title: "Track",
      artistName: "Artist",
      artworkURL: nil,
      albumTitle: "Different Album",
    )
    let snapshot = playbackSnapshot(items: [item])
    var state = AppFeature.State()
    state.library.status = .loaded(.init(albums: [album]))
    state.playback.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.lastCachedProgressBucket = 0
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.playback.loadAlbumIDs = { songID in
        #expect(songID == item.id)
        return [album.id]
      }
    }

    await store.send(.playback(.playbackEvent(.snapshotChanged(snapshot)))) {
      $0.playback.pendingAlbumResolutionSongID = item.id
    }
    await store.receive(.playbackAlbumIDsResolved(item.id, [album.id])) {
      $0.playback.pendingAlbumResolutionSongID = nil
      $0.playback.sourceAlbumIDs[item.id] = album.id
      $0.playback.session?.queue.entries[0] = PlaybackQueueEntry(
        id: "entry-0",
        item: item.withAlbumID(album.id),
      )
    }
    await store.receive(.playback(.saveCachedSession))
  }

  @Test
  func setupDelegateCompletedIsHandled() async {
    var state = AppFeature.State()
    state.setup.screen = .ready(childName: "Harriet")
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.setup(.delegate(.completed(childName: "Harriet"))))
  }

  @Test
  func debugResetOnboardingRotatesDeviceConnectionAndRestartsSetup() async {
    let item = playbackItem("track-1")
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(.mock)
    state.playback.session = .init(currentItem: item)
    state.selectedTab = .queue
    state.setup.screen = .ready(childName: "Harriet")
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.keychain._save = { _, _ in }
      $0.keychain.delete = { _ in }
      $0.playback.stop = {}
      $0.uuid = UUIDGenerator {
        UUID(3)
      }
    }

    await store.send(.library(.debugResetOnboardingButtonTapped)) {
      $0.isNowPlayingPresented = false
      $0.library = .init()
      $0.playback = .init()
      $0.setup = .init()
      $0.selectedTab = .library
    }
    #expect(store.state.setup.screen == .checking)
  }

  @Test
  func libraryPlayNowDelegateStartsRequestedSuffix() async {
    let items = [
      playbackItem("track-1"),
      playbackItem("track-2"),
      playbackItem("track-3"),
    ]
    let requestedItems = Array(items.dropFirst()).map { $0.withQueueRole(.context) }
    let context = PlaybackContext(
      identity: .init(kind: .album, id: "album"),
      title: "Album",
    )
    let snapshot = playbackSnapshot(items: requestedItems.map { $0.withQueueRole(nil) })
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .context,
    ]
    let store = TestStore(initialState: .init()) {
      AppFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.library(.delegate(.playNow(
      items: items,
      startIndex: 1,
      context: context,
    )))) {
      $0.pendingLibraryPlayNowOrigin = context.identity
    }
    await store.receive(.playback(.playNow(
      items: items,
      startIndex: 1,
      context: context,
    ))) {
      $0.playback.pendingMetadataPlan = requestedItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.playback.pendingPlayNowItems = requestedItems
      $0.playback.playbackContext = context
      $0.playback.session = .init(
        playStatus: .loading,
        queue: .init(items: requestedItems),
      )
    }
    await store.receive(.playback(.playNowFinished(snapshot))) {
      $0.pendingLibraryPlayNowOrigin = nil
      $0.playback.hasAuthoritativeSnapshot = true
      $0.playback.lastCachedProgressBucket = 0
      $0.playback.pendingMetadataPlan = nil
      $0.playback.pendingPlayNowItems = nil
      $0.playback.queueRoleHints = roleHints
      $0.playback.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }
    await store.receive(.library(.collectionPlayNowSucceeded(context.identity)))
  }

  @Test
  func artistPlaybackButtonPreservesQueuedItemsAndReplacesContext() async {
    let oldItems = [
      playbackItem("old-track").withQueueRole(.context),
      playbackItem("old-queued").withQueueRole(.queued),
      playbackItem("old-context").withQueueRole(.context),
    ]
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let composedItems = [
      items[0].withQueueRole(.context),
      oldItems[1],
      items[1].withQueueRole(.context),
    ]
    let context = PlaybackContext(
      identity: .init(kind: .artist, id: "artist"),
      title: "Artist",
    )
    let snapshot = playbackSnapshot(items: composedItems.map { $0.withQueueRole(nil) })
    let roleHints: [PlaybackQueueEntry.ID: PlaybackQueueRole] = [
      "entry-0": .context,
      "entry-1": .queued,
      "entry-2": .context,
    ]
    var state = AppFeature.State()
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.session = .init(queue: .init(items: oldItems))
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.library(.delegate(.artistPlaybackButtonTapped(
      items: items,
      context: context,
    )))) {
      $0.pendingLibraryPlayNowOrigin = context.identity
    }
    await store.receive(.playback(.playNow(
      items: items,
      startIndex: 0,
      context: context,
    ))) {
      $0.playback.hasAuthoritativeSnapshot = false
      $0.playback.pendingMetadataPlan = composedItems.map {
        PlaybackMetadataHintMatcher.Occurrence(item: $0)
      }
      $0.playback.pendingPlayNowItems = composedItems
      $0.playback.playbackContext = context
      $0.playback.session = .init(
        playStatus: .loading,
        queue: .init(items: composedItems),
      )
    }
    await store.receive(.playback(.playNowFinished(snapshot))) {
      $0.pendingLibraryPlayNowOrigin = nil
      $0.playback.hasAuthoritativeSnapshot = true
      $0.playback.lastCachedProgressBucket = 0
      $0.playback.pendingMetadataPlan = nil
      $0.playback.pendingPlayNowItems = nil
      $0.playback.queueRoleHints = roleHints
      $0.playback.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }
    await store.receive(.library(.collectionPlayNowSucceeded(context.identity)))
  }

  @Test
  func artistPlaybackButtonPausesWhenArtistContextIsPlaying() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let context = PlaybackContext(
      identity: .init(kind: .artist, id: "artist"),
      title: "Artist",
    )
    var state = AppFeature.State()
    state.playback.playbackContext = context
    state.playback.session = .init(
      playStatus: .playing,
      queue: .init(items: items.map { $0.withQueueRole(.context) }),
    )
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.library(.delegate(.artistPlaybackButtonTapped(
      items: items,
      context: context,
    ))))
    await store.receive(.playback(.togglePlayPause))
    await store.receive(.playback(.pause)) {
      $0.playback.session?.playStatus = .paused
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
  func libraryQueueDelegatesRouteToPlaybackClient() async {
    let currentItem = playbackItem("current").withQueueRole(.context)
    let addedItem = playbackItem("added")
    let nextItem = playbackItem("next")
    let recorder = AppPlaybackQueueRecorder()
    var state = AppFeature.State()
    state.playback.session = .init(currentItem: currentItem)
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.lastCachedProgressBucket = 0
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { items, target in
        await recorder.record(items: items, target: target)
        throw CancellationError()
      }
    }

    await store.send(.library(.delegate(.addToQueue(items: [addedItem]))))
    await store.receive(.playback(.addToQueue([addedItem]))) {
      $0.playback.pendingMetadataPlan = [
        .init(item: currentItem, retainedEntryID: "pending:0:current"),
        .init(item: addedItem.withQueueRole(.queued)),
      ]
      $0.playback.queueRoleHints = ["pending:0:current": .context]
    }
    await store.send(.library(.delegate(.playNext(items: [nextItem]))))
    await store.receive(.playback(.playNext([nextItem]))) {
      $0.playback.pendingMetadataPlan = [
        .init(item: currentItem, retainedEntryID: "pending:0:current"),
        .init(item: nextItem.withQueueRole(.queued)),
      ]
    }

    #expect(await recorder.targets == [.tail, .next])
  }

  @Test
  func libraryActionPropagatesExistingPlaybackFailureToAlbumDetail() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    state.search.applyLibraryStatus(.loaded(library))
    state.playback.failure = .musicAccessDenied
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.library(.albumTapped(album.id))) {
      $0.library.albumDetail = .init(
        album: album,
        transitionSourceID: album.id.rawValue,
        playbackFailure: .musicAccessDenied,
      )
    }
  }

  @Test
  func libraryActionPropagatesExistingPlaybackFailureToPlaylistDetail() async {
    var library = ApprovedMusicLibrary.mock
    let playlist = MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Favorites",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
      entries: [],
    )
    library.playlists = [playlist]
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    state.search.applyLibraryStatus(.loaded(library))
    state.playback.failure = .musicAccessDenied
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.library(.playlistTapped(playlist.id))) {
      $0.library.playlistDetail = .init(
        playlist: playlist,
        playbackFailure: .musicAccessDenied,
      )
    }
  }

  @Test
  func playbackStateUpdatesDirectAlbumDetailPlayingState() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let track = album.tracks[1]
    let item = PlaybackItem(
      track: track,
      artworkURL: album.artworkURL,
      albumID: album.id,
    )
    let contextItem = item.withQueueRole(.context)
    let context = PlaybackContext(
      identity: .album(album.id),
      title: album.title,
    )
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    state.library.albumDetail = .init(
      album: album,
      transitionSourceID: album.id.rawValue,
    )
    let snapshot = playbackSnapshot(items: [item])
    let roleHints = ["entry-0": PlaybackQueueRole.context]
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playback(.playNow(
      items: [item],
      startIndex: 0,
      context: context,
    ))) {
      $0.playback.pendingMetadataPlan = [
        PlaybackMetadataHintMatcher.Occurrence(item: contextItem),
      ]
      $0.playback.pendingPlayNowItems = [contextItem]
      $0.playback.playbackContext = context
      $0.playback.session = .init(playStatus: .loading, currentItem: contextItem)
      $0.playback.sourceAlbumIDs[track.id] = album.id
      guard var albumDetail = $0.library.albumDetail else { return }
      albumDetail.playStatus = .loading
      albumDetail.currentTrackID = track.id
      albumDetail.currentTrackPlayStatus = .loading
      $0.library.albumDetail = albumDetail
    }
    await store.receive(.playback(.playNowFinished(snapshot))) {
      $0.playback.hasAuthoritativeSnapshot = true
      $0.playback.lastCachedProgressBucket = 0
      $0.playback.pendingMetadataPlan = nil
      $0.playback.pendingPlayNowItems = nil
      $0.playback.queueRoleHints = roleHints
      $0.playback.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [track.id: album.id],
        queueRoleHints: roleHints,
      )
      guard var albumDetail = $0.library.albumDetail else { return }
      albumDetail.playStatus = .playing
      albumDetail.currentTrackPlayStatus = .playing
      $0.library.albumDetail = albumDetail
    }
  }

  @Test
  func cachedAndRemoteLibrariesUpdatePlaybackApprovals() async {
    let cached = cachedApprovedMusicLibrary
    let remote = ApprovedMusicLibrary.mock
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }
    store.exhaustivity = .off

    await store.send(.library(.cachedApprovedLibraryLoaded(cached)))
    await store.receive(.library(.delegate(.approvedTrackIDsUpdated(cached.approvedTrackIDs))))
    await store.receive(.playback(.approvedTrackIDsUpdated(cached.approvedTrackIDs)))
    expectNoDifference(store.state.playback.approvedTrackIDs, cached.approvedTrackIDs)

    await store.send(.library(.approvedLibraryLoaded(remote)))
    await store.receive(.library(.delegate(.approvedTrackIDsUpdated(remote.approvedTrackIDs))))
    await store.receive(.playback(.approvedTrackIDsUpdated(remote.approvedTrackIDs)))
    expectNoDifference(store.state.playback.approvedTrackIDs, remote.approvedTrackIDs)
  }

  @Test
  func selectingSearchSynchronizesTheAuthoritativeLibrary() async {
    let library = ApprovedMusicLibrary.mock
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    var expectedSearch = SearchFeature.State()
    expectedSearch.applyLibraryStatus(.loaded(library))
    await store.send(.tabSelected(.search)) {
      $0.selectedTab = .search
      $0.search = expectedSearch
    }
  }

  @Test
  func searchCurrentSongTapTogglesPlayback() async {
    let item = playbackItem("track-1")
    var state = AppFeature.State()
    state.playback.session = .init(playStatus: .playing, currentItem: item)
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.search(.delegate(.songTapped(item))))
    await store.receive(.playback(.togglePlayPause))
    await store.receive(.playback(.pause)) {
      $0.playback.session?.playStatus = .paused
    }
  }

  @Test
  func searchSongTapStartsOnlyThatSong() async {
    let item = playbackItem("track-1")
    let contextItem = item.withQueueRole(.context)
    let snapshot = playbackSnapshot(items: [item])
    let roleHints = ["entry-0": PlaybackQueueRole.context]
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.search(.delegate(.songTapped(item))))
    await store.receive(.playback(.playNow(
      items: [item],
      startIndex: 0,
      context: nil,
    ))) {
      $0.playback.pendingMetadataPlan = [
        PlaybackMetadataHintMatcher.Occurrence(item: contextItem),
      ]
      $0.playback.pendingPlayNowItems = [contextItem]
      $0.playback.session = .init(playStatus: .loading, currentItem: contextItem)
    }
    await store.receive(.playback(.playNowFinished(snapshot))) {
      $0.playback.hasAuthoritativeSnapshot = true
      $0.playback.lastCachedProgressBucket = 0
      $0.playback.pendingMetadataPlan = nil
      $0.playback.pendingPlayNowItems = nil
      $0.playback.queueRoleHints = roleHints
      $0.playback.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [:],
        queueRoleHints: roleHints,
      )
    }
  }

  @Test
  func searchBrowseLibrarySwitchesTabs() async {
    var state = AppFeature.State()
    state.selectedTab = .search
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.search(.delegate(.browseLibrary))) {
      $0.selectedTab = .library
    }
  }
}

private actor AppPlaybackQueueRecorder {
  var targets: [PlaybackQueueInsertionTarget] = []

  func record(
    items _: [PlaybackItem],
    target: PlaybackQueueInsertionTarget,
  ) {
    self.targets.append(target)
  }
}
