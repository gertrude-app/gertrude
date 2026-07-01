import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct AlbumDetailFeatureTests {
  @Test
  func playTappedRequestsAlbumQueuePlaybackFromFirstTrack() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
    await store.receive(.delegate(.playAlbum(
      items: playbackItems(album: album),
      startIndex: 0,
    )))
  }

  @Test
  func trackTappedRequestsAlbumQueuePlaybackFromTrackIndex() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let track = album.tracks[2]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.trackTapped(track.id))
    await store.receive(.delegate(.playAlbum(
      items: playbackItems(album: album),
      startIndex: 2,
    )))
  }

  @Test
  func playTappedWithCurrentSessionTogglesPlayPause() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let store = TestStore(initialState: .init(
      album: album,
      playStatus: .playing,
      currentTrackID: album.tracks[1].id,
    )) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
    await store.receive(.delegate(.togglePlayPause))
  }

  @Test
  func currentTrackTapTogglesPlayPause() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let track = album.tracks[2]
    let store = TestStore(initialState: .init(
      album: album,
      playStatus: .paused,
      currentTrackID: track.id,
    )) {
      AlbumDetailFeature()
    }

    await store.send(.trackTapped(track.id))
    await store.receive(.delegate(.togglePlayPause))
  }

  @Test
  func pausedSessionKeepsCurrentTrackWithoutPlaying() {
    let album = ApprovedMusicLibrary.mock.albums[0]
    var state = AlbumDetailFeature.State(album: album)

    state.setPlaybackSession(.init(
      playStatus: .paused,
      currentItem: PlaybackItem(
        track: album.tracks[0],
        artworkURL: album.artworkURL,
        albumID: album.id,
      ),
    ))

    #expect(state.isPlaying == false)
    #expect(state.currentTrackID == album.tracks[0].id)
  }

  @Test
  func invalidTrackTapDoesNothing() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.trackTapped("not-in-this-album"))
  }

  @Test
  func playTappedWithEmptyAlbumDoesNothing() async {
    let album = ApprovedAlbum(
      id: "empty-album",
      title: "Empty Album",
      artistName: "Nobody",
    )
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
  }
}

private func playbackItems(album: ApprovedAlbum) -> [PlaybackItem] {
  album.tracks.map { PlaybackItem(
    track: $0,
    artworkURL: album.artworkURL,
    albumID: album.id,
  ) }
}
