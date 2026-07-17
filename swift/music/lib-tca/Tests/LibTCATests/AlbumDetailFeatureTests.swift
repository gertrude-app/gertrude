import ComposableArchitecture
import Testing

@testable import LibTCA

@MainActor
struct AlbumDetailFeatureTests {
  @Test
  func loadsTracksOnAppearWhenAlbumHasNoTracks() async {
    let album = ApprovedAlbum(
      id: "album-1",
      title: "Album",
      artistName: "Artist",
    )
    let tracks = [
      ApprovedTrack(
        id: "track-1",
        title: "Track 1",
        artistName: "Artist",
      ),
    ]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    } withDependencies: {
      $0.approvedMusic.loadAlbumTracks = { albumID in
        #expect(albumID == album.id)
        return tracks
      }
    }

    await store.send(.onAppear) {
      $0.isLoadingTracks = true
    }
    await store.receive(.albumTracksLoaded(album.id, tracks)) {
      $0.album.tracks = tracks
      $0.isLoadingTracks = false
    }
  }

  @Test
  func doesNotLoadTracksOnAppearWhenAlbumAlreadyHasTracks() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.onAppear)
  }

  @Test
  func clearsTrackLoadingStateWhenTrackLoadFails() async {
    let album = ApprovedAlbum(
      id: "album-1",
      title: "Album",
      artistName: "Artist",
    )
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    } withDependencies: {
      $0.approvedMusic.loadAlbumTracks = { _ in throw TestError() }
    }

    await store.send(.onAppear) {
      $0.isLoadingTracks = true
    }
    await store.receive(.albumTracksLoadFailed(album.id)) {
      $0.isLoadingTracks = false
    }
  }

  @Test
  func playTappedLoadsTracksWhenAlbumHasNoTracks() async {
    let album = ApprovedAlbum(
      id: "album-1",
      title: "Album",
      artistName: "Artist",
    )
    let tracks = [
      ApprovedTrack(
        id: "track-1",
        title: "Track 1",
        artistName: "Artist",
      ),
    ]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    } withDependencies: {
      $0.approvedMusic.loadAlbumTracks = { _ in tracks }
    }

    await store.send(.playTapped) {
      $0.isLoadingTracks = true
    }
    await store.receive(.albumTracksLoaded(album.id, tracks)) {
      $0.album.tracks = tracks
      $0.isLoadingTracks = false
    }
  }

  @Test
  func playTappedRequestsAlbumQueuePlaybackFromFirstTrack() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
    await store.receive(.delegate(.playNow(
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
    await store.receive(.delegate(.playNow(
      items: playbackItems(album: album),
      startIndex: 2,
    )))
  }

  @Test
  func albumQueueActionsDelegateAllTracks() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let items = playbackItems(album: album)
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.playNextTapped)
    await store.receive(.delegate(.playNext(items: items)))
    await store.send(.addToQueueTapped)
    await store.receive(.delegate(.addToQueue(items: items)))
  }

  @Test
  func trackQueueActionsDelegateOnlySelectedTrack() async {
    let album = ApprovedMusicLibrary.mock.albums[0]
    let track = album.tracks[1]
    let item = playbackItems(album: album)[1]
    let store = TestStore(initialState: .init(album: album)) {
      AlbumDetailFeature()
    }

    await store.send(.trackPlayNextTapped(track.id))
    await store.receive(.delegate(.playNext(items: [item])))
    await store.send(.trackAddToQueueTapped(track.id))
    await store.receive(.delegate(.addToQueue(items: [item])))
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
  func playTappedDoesNothingWhileTracksAreLoading() async {
    let album = ApprovedAlbum(
      id: "empty-album",
      title: "Empty Album",
      artistName: "Nobody",
    )
    let store = TestStore(initialState: .init(
      album: album,
      isLoadingTracks: true,
    )) {
      AlbumDetailFeature()
    }

    await store.send(.playTapped)
  }
}
