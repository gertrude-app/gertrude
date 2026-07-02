import ComposableArchitecture
import Foundation
import Testing

@testable import LibTCA

@MainActor
struct AppFeatureTests {
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
  func nowPlayingAlbumInfoTapFromAnotherAlbumDetailQueuesReplacement() async {
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
      $0.library.pendingAlbumDetail = .init(
        album: currentAlbum,
        playStatus: .playing,
        currentTrackID: track.id,
      )
    }

    await store.send(.library(.albumDetailDismissed(visibleAlbum.id.rawValue))) {
      $0.library.albumDetail = .init(
        album: currentAlbum,
        playStatus: .playing,
        currentTrackID: track.id,
      )
      $0.library.pendingAlbumDetail = nil
    }
  }

  @Test
  func nowPlayingAlbumInfoTapWithoutAlbumIDDoesNothing() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let item = PlaybackItem(
      track: album.tracks[0],
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
  func setupDelegateCompletedIsHandled() async {
    var state = AppFeature.State()
    state.setup.screen = .ready(childName: "Harriet")
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.setup(.delegate(.completed(childName: "Harriet"))))
  }

  @Test
  func debugResetOnboardingRotatesDeviceConnectionAndShowsWelcome() async {
    let item = playbackItem("track-1")
    var state = AppFeature.State()
    state.isNowPlayingPresented = true
    state.library.status = .loaded(.mock)
    state.playback.session = .init(currentItem: item)
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
      $0.setup.screen = .welcome
    }
  }

  @Test
  func libraryPlayAlbumDelegateStartsAlbumQueuePlayback() async {
    let items = [
      playbackItem("track-1"),
      playbackItem("track-2"),
      playbackItem("track-3"),
    ]
    let store = TestStore(initialState: .init()) {
      AppFeature()
    }

    await store.send(.library(.delegate(.playAlbum(items: items, startIndex: 1))))
    await store.receive(.playback(.playAlbumQueue(items: items, startIndex: 1))) {
      $0.playback.session = .init(
        playStatus: .loading,
        albumQueue: .init(items: items, currentIndex: 1),
      )
    }
    await store.receive(.playback(.playbackStarted)) {
      $0.playback.session?.playStatus = .playing
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
    )
    var state = AppFeature.State()
    state.library.status = .loaded(library)
    state.library.albumDetail = .init(
      album: album,
      transitionSourceID: album.id.rawValue,
    )
    let store = TestStore(initialState: state) {
      AppFeature()
    }

    await store.send(.playback(.playTrack(item))) {
      $0.playback.session = .init(playStatus: .loading, currentItem: item)
      guard var albumDetail = $0.library.albumDetail else { return }
      albumDetail.playStatus = .loading
      albumDetail.currentTrackID = track.id
      $0.library.albumDetail = albumDetail
    }
    await store.receive(.playback(.playbackStarted)) {
      $0.playback.session?.playStatus = .playing
      guard var albumDetail = $0.library.albumDetail else { return }
      albumDetail.playStatus = .playing
      $0.library.albumDetail = albumDetail
    }
  }
}
