import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct AlbumDetailFeatureTests {
  @Test
  func playTappedRequestsAlbumQueuePlaybackFromFirstTrack() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    let store = TestStore(initialState: .init(album: album, tracks: tracks)) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
    await store.receive(.delegate(.playAlbum(
      items: playbackItems(album: album, tracks: tracks),
      startIndex: 0,
    )))
  }

  @Test
  func trackTappedRequestsAlbumQueuePlaybackFromTrackIndex() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    let track = tracks[2]
    let store = TestStore(initialState: .init(album: album, tracks: tracks)) {
      AlbumDetailFeature()
    }

    await store.send(.trackTapped(track.id))
    await store.receive(.delegate(.playAlbum(
      items: playbackItems(album: album, tracks: tracks),
      startIndex: 2,
    )))
  }

  @Test
  func playTappedWithCurrentSessionTogglesPlayPause() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    let store = TestStore(initialState: .init(
      album: album,
      tracks: tracks,
      playStatus: .playing,
      currentTrackID: tracks[1].id,
    )) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
    await store.receive(.delegate(.togglePlayPause))
  }

  @Test
  func currentTrackTapTogglesPlayPause() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    let track = tracks[2]
    let store = TestStore(initialState: .init(
      album: album,
      tracks: tracks,
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
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    var state = AlbumDetailFeature.State(album: album, tracks: tracks)

    state.setPlaybackSession(.init(
      playStatus: .paused,
      currentItem: PlaybackItem(
        track: tracks[0],
        artworkURL: album.artworkURL,
        allowsArtwork: album.showsArtwork,
      ),
    ))

    #expect(state.isPlaying == false)
    #expect(state.currentTrackID == tracks[0].id)
  }

  @Test
  func invalidTrackTapDoesNothing() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    let store = TestStore(initialState: .init(album: album, tracks: tracks)) {
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
      trackIDs: [],
    )
    let store = TestStore(initialState: .init(album: album, tracks: [])) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
  }
}

private func playbackItems(
  album: ApprovedAlbum,
  tracks: [ApprovedTrack],
) -> [PlaybackItem] {
  tracks.map { PlaybackItem(
    track: $0,
    artworkURL: album.artworkURL,
    allowsArtwork: album.showsArtwork,
  ) }
}
