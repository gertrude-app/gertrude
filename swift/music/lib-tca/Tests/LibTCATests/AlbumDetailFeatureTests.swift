import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct AlbumDetailFeatureTests {
  @Test
  func playTappedRequestsAlbumPlaybackInTrackOrder() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    let store = TestStore(initialState: .init(album: album, tracks: tracks)) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
    await store.receive(.delegate(.playAlbum(tracks.map { PlaybackItem(
      track: $0,
      artworkURL: album.artworkURL,
      allowsArtwork: album.showsArtwork,
    ) })))
  }

  @Test
  func trackTappedRequestsSingleTrackPlayback() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let tracks = library.tracks(for: album)
    let track = tracks[2]
    let store = TestStore(initialState: .init(album: album, tracks: tracks)) {
      AlbumDetailFeature()
    }

    await store.send(.trackTapped(track.id))
    await store.receive(.delegate(.playTrack(PlaybackItem(
      track: track,
      artworkURL: album.artworkURL,
      allowsArtwork: album.showsArtwork,
    ))))
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
