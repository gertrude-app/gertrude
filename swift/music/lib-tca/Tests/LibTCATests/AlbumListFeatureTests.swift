import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct AlbumListFeatureTests {
  @Test
  func albumTapNavigatesToAlbumScreen() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let store = TestStore(initialState: .init(albums: library.albums, tracks: library.tracks)) {
      AlbumListFeature()
    }

    await store.send(.albumTapped(album.id)) {
      $0.destination = .album(.init(
        album: album,
        tracks: library.tracks(for: album),
        transitionSourceID: album.id.rawValue,
      ))
    }
  }

  @Test
  func albumDetailPlayDelegateIsForwarded() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let store = TestStore(initialState: .init(
      albums: library.albums,
      tracks: library.tracks,
      destination: .album(.init(
        album: album,
        tracks: library.tracks(for: album),
      )),
    )) {
      AlbumListFeature()
    }

    await store.send(.destination(.presented(.album(.delegate(.playTrack(playbackItem("track-1")))))))
    await store.receive(.delegate(.playTrack(playbackItem("track-1"))))
  }

  @Test
  func albumDetailDismissedClearsDestination() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let store = TestStore(initialState: .init(
      albums: library.albums,
      tracks: library.tracks,
      destination: .album(.init(
        album: album,
        tracks: library.tracks(for: album),
        transitionSourceID: album.id.rawValue,
      )),
    )) {
      AlbumListFeature()
    }

    await store.send(.albumDetailDismissed(album.id.rawValue)) {
      $0.destination = nil
    }
  }

  @Test
  func staleAlbumDetailDismissalDoesNotClearNewDestination() async {
    let library = ApprovedMusicLibrary.mock
    let oldAlbum = library.albums[0]
    let newAlbum = library.albums[1]
    let store = TestStore(initialState: .init(
      albums: library.albums,
      tracks: library.tracks,
      destination: .album(.init(
        album: newAlbum,
        tracks: library.tracks(for: newAlbum),
        transitionSourceID: newAlbum.id.rawValue,
      )),
    )) {
      AlbumListFeature()
    }

    await store.send(.albumDetailDismissed(oldAlbum.id.rawValue))
  }
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
