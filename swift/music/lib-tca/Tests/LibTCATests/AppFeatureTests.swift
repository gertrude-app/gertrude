import ComposableArchitecture
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
      $0.library.albumDetail?.playStatus = nil
      $0.playback.hasAuthoritativeSnapshot = false
      $0.playback.session = nil
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
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.nowPlayingAlbumInfoTapped) {
      $0.isNowPlayingPresented = false
      $0.library.albumDetail = .init(
        album: album,
        playStatus: .playing,
        currentTrackID: track.id,
      )
    }
  }

  @Test
  func nowPlayingAlbumInfoTapPreservesLoadedCurrentAlbumDetail() async {
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
      $0.library.albumDetail?.playStatus = .playing
      $0.library.albumDetail?.currentTrackID = track.id
    }

    #expect(store.state.library.albumDetail?.album.tracks == loadedAlbum.tracks)
  }

  @Test
  func nowPlayingAlbumInfoTapFromAnotherAlbumDetailReplacesDetail() async {
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
      $0.library.albumDetail = .init(
        album: currentAlbum,
        playStatus: .playing,
        currentTrackID: track.id,
      )
    }
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
    let requestedItems = Array(items.dropFirst())
    let snapshot = playbackSnapshot(items: requestedItems)
    let store = TestStore(initialState: .init()) {
      AppFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.library(.delegate(.playNow(items: items, startIndex: 1))))
    await store.receive(.playback(.playNow(items: items, startIndex: 1))) {
      $0.playback.pendingPlayNowItems = requestedItems
      $0.playback.session = .init(
        playStatus: .loading,
        queue: .init(items: requestedItems),
      )
    }
    await store.receive(.playback(.playNowFinished(snapshot))) {
      $0.playback.hasAuthoritativeSnapshot = true
      $0.playback.lastCachedProgressBucket = 0
      $0.playback.pendingPlayNowItems = nil
      $0.playback.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    }
  }

  @Test
  func artistPlaybackButtonStartsArtistQueueWhenAnotherQueueIsActive() async {
    let oldItems = [playbackItem("old-track"), playbackItem("old-next")]
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let composedItems = items + [oldItems[1]]
    let snapshot = playbackSnapshot(items: composedItems)
    var state = AppFeature.State()
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.session = .init(queue: .init(items: oldItems))
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.library(.delegate(.artistPlaybackButtonTapped(items: items))))
    await store.receive(.playback(.playNow(items: items, startIndex: 0))) {
      $0.playback.hasAuthoritativeSnapshot = false
      $0.playback.pendingPlayNowItems = composedItems
      $0.playback.session = .init(
        playStatus: .loading,
        queue: .init(items: composedItems),
      )
    }
    await store.receive(.playback(.playNowFinished(snapshot))) {
      $0.playback.hasAuthoritativeSnapshot = true
      $0.playback.lastCachedProgressBucket = 0
      $0.playback.pendingPlayNowItems = nil
      $0.playback.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    }
  }

  @Test
  func artistPlaybackButtonPausesWhenCurrentTrackBelongsToArtist() async {
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    var state = AppFeature.State()
    state.playback.session = .init(
      playStatus: .playing,
      queue: .init(items: [items[0], playbackItem("older-tail")]),
    )
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.library(.delegate(.artistPlaybackButtonTapped(items: items))))
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
    let items = [playbackItem("track-1"), playbackItem("track-2")]
    let snapshot = playbackSnapshot(items: items)
    let recorder = AppPlaybackQueueRecorder()
    var state = AppFeature.State()
    state.playback.session = PlaybackFeature.Session(snapshot: snapshot, sourceAlbumIDs: [:])
    state.playback.hasAuthoritativeSnapshot = true
    state.playback.lastCachedProgressBucket = 0
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.playback.insertIntoQueue = { items, position in
        await recorder.record(items: items, position: position)
        return snapshot
      }
    }

    await store.send(.library(.delegate(.addToQueue(items: items))))
    await store.receive(.playback(.addToQueue(items)))
    await store.receive(.playback(.playbackEvent(.snapshotChanged(snapshot))))
    await store.send(.library(.delegate(.playNext(items: items))))
    await store.receive(.playback(.playNext(items)))
    await store.receive(.playback(.playbackEvent(.snapshotChanged(snapshot))))

    #expect(await recorder.positions == [.tail, .next])
  }

  @Test
  func libraryActionPropagatesExistingPlaybackFailureToAlbumDetail() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    var state = AppFeature.State()
    state.library.status = .loaded(library)
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
  func playbackStateUpdatesDirectAlbumDetailPlayingState() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let track = album.tracks[1]
    let item = PlaybackItem(
      track: track,
      artworkURL: album.artworkURL,
      albumID: album.id,
    )
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    state.library.albumDetail = .init(
      album: album,
      transitionSourceID: album.id.rawValue,
    )
    let snapshot = playbackSnapshot(items: [item])
    let store = TestStore(initialState: state) {
      AppFeature()
    } withDependencies: {
      $0.playback.playNow = { _, _ in snapshot }
    }

    await store.send(.playback(.playNow(items: [item], startIndex: 0))) {
      $0.playback.pendingPlayNowItems = [item]
      $0.playback.session = .init(playStatus: .loading, currentItem: item)
      $0.playback.sourceAlbumIDs[track.id] = album.id
      guard var albumDetail = $0.library.albumDetail else { return }
      albumDetail.playStatus = .loading
      albumDetail.currentTrackID = track.id
      $0.library.albumDetail = albumDetail
    }
    await store.receive(.playback(.playNowFinished(snapshot))) {
      $0.playback.hasAuthoritativeSnapshot = true
      $0.playback.lastCachedProgressBucket = 0
      $0.playback.pendingPlayNowItems = nil
      $0.playback.session = PlaybackFeature.Session(
        snapshot: snapshot,
        sourceAlbumIDs: [track.id: album.id],
      )
      guard var albumDetail = $0.library.albumDetail else { return }
      albumDetail.playStatus = .playing
      $0.library.albumDetail = albumDetail
    }
  }
}

private actor AppPlaybackQueueRecorder {
  var positions: [PlaybackQueueInsertionPosition] = []

  func record(
    items _: [PlaybackItem],
    position: PlaybackQueueInsertionPosition,
  ) {
    self.positions.append(position)
  }
}
