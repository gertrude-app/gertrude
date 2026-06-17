import ComposableArchitecture
import Foundation
import MusicRoute
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
  func onAppearShowsClaimCodeWhenUnclaimed() async {
    let expiresAt = Date(timeIntervalSince1970: 123)
    let store = TestStore(initialState: .init()) {
      AppFeature()
    } withDependencies: {
      $0.api.getMusicAppStatus = { .unclaimed(code: 123_456, expiresAt: expiresAt) }
      $0.keychain._load = { _ in nil }
      $0.keychain._save = { _, _ in }
      $0.keychain.delete = { _ in }
    }

    await store.send(.onAppear)
    await store.receive(.musicAppStatusLoaded(.unclaimed(code: 123_456, expiresAt: expiresAt))) {
      $0.connection = .unclaimed(code: 123_456, expiresAt: expiresAt)
    }
  }

  @Test
  func onAppearUsesStoredConnectionWhenStatusCheckFails() async throws {
    let connection = MusicAppConnection(
      token: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
      childId: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
      childName: "Harriet",
    )
    let connectionData = try JSONEncoder().encode(connection)
    let store = TestStore(initialState: .init()) {
      AppFeature()
    } withDependencies: {
      $0.api.getMusicAppStatus = { throw TestError.offline }
      $0.keychain._load = { key in key == .connection ? connectionData : nil }
      $0.keychain._save = { _, _ in }
      $0.keychain.delete = { _ in }
    }

    await store.send(.onAppear) {
      $0.connection = .claimed(childName: "Harriet")
    }
    await store.receive(.musicAppStatusFailed(hasStoredConnection: true))
  }

  @Test
  func onAppearStoresClaimedConnection() async {
    let token = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
    let childId = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!
    let store = TestStore(initialState: .init()) {
      AppFeature()
    } withDependencies: {
      $0.api.getMusicAppStatus = {
        .claimed(
          token: token,
          childId: childId,
          childName: "Harriet",
        )
      }
      $0.keychain._load = { _ in nil }
      $0.keychain._save = { _, _ in }
      $0.keychain.delete = { _ in }
    }

    await store.send(.onAppear)
    await store.receive(.musicAppStatusLoaded(.claimed(
      token: token,
      childId: childId,
      childName: "Harriet",
    ))) {
      $0.connection = .claimed(childName: "Harriet")
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
      allowsArtwork: album.showsArtwork,
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

private enum TestError: Error {
  case offline
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
