import ComposableArchitecture
import CustomDump
import Foundation
import Testing

@testable import LibTCA

@MainActor
struct SearchFeatureTests {
  @Test
  func queryUpdatesRankedResultsInState() async {
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(.mock))
    let expectedResults = state.librarySearch.results(query: "brewed")
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.queryChanged("brewed")) {
      $0.query = "brewed"
      $0.results = expectedResults
    }

    expectNoDifference(
      store.state.results.map(\.id),
      [
        .song("1641851259"),
        .album("1641851258"),
        .song("1641851262"),
      ],
    )
  }

  @Test
  func songTapDelegatesApprovedAlbumPlaybackFromSelectedTrack() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[2]
    let track = album.tracks[1]
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(library))
    state.query = track.title
    state.results = state.librarySearch.results(query: state.query)
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.resultTapped(.song(track.id)))
    await store.receive(.delegate(.songTapped(
      items: playbackItems(album: album),
      start: .selectedEntry(index: 1),
      context: PlaybackContext(
        identity: .album(album.id),
        title: album.title,
      ),
    )))
  }

  @Test
  func collectionTapsOpenExistingDetailDomains() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[0]
    let artist = library.artists[0]
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(library))
    state.query = "stories"
    state.results = state.librarySearch.results(query: state.query)
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.resultTapped(.album(album.id))) {
      $0.path.append(.album(.init(
        album: album,
        transitionSourceID: album.id.rawValue,
      )))
    }
    await store.send(.path(.popFrom(id: 0))) {
      $0.path.removeAll()
    }
    await store.send(.queryChanged("vasen")) {
      $0.query = "vasen"
      $0.results = $0.librarySearch.results(query: "vasen")
    }
    await store.send(.resultAddToPlaylistTapped(.artist(artist.id)))
    await store.receive(.delegate(.library(.addArtistToPlaylistTapped(artist.id))))
    await store.send(.resultTapped(.artist(artist.id))) {
      $0.path.append(.artist(.init(artistID: artist.id)))
    }
  }

  @Test
  func artistDetailKeepsDiscographyAndTopSongsPlaybackSourcesDistinct() async {
    let album = ApprovedAlbum(
      id: "album",
      title: "Album",
      artistName: "Artist",
      releaseDate: "2025-06-01",
      tracks: [
        ApprovedTrack(id: "song-1", title: "First", artistName: "Artist"),
        ApprovedTrack(id: "song-2", title: "Second", artistName: "Artist"),
      ],
    )
    let topSongs = [album.tracks[1]]
    let artist = ApprovedArtist(
      id: "artist",
      name: "Artist",
      releaseAlbumIds: [album.id],
      topSongs: topSongs,
    )
    let library = ApprovedMusicLibrary(albums: [album], artists: [artist])
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(library))
    state.path.append(.artist(.init(artistID: artist.id)))
    let pathID = state.path.ids.last!
    let discographyItems = playbackItems(album: album)
    let topSongItems = topSongs.map {
      PlaybackItem(track: $0, artworkURL: $0.artworkURL)
    }
    let discographyContext = PlaybackContext(
      identity: .artist(artist.id),
      title: artist.name,
      artistSource: .discography,
    )
    let topSongsContext = PlaybackContext(
      identity: .artist(artist.id),
      title: artist.name,
      artistSource: .topSongs,
    )
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.path(.element(id: pathID, action: .artist(.addToPlaylistTapped))))
    await store.receive(.delegate(.library(.addArtistToPlaylistTapped(artist.id))))

    await store.send(.path(.element(id: pathID, action: .artist(.playButtonTapped))))
    await store.receive(.delegate(.playback(.artistPlaybackButtonTapped(
      items: discographyItems,
      context: discographyContext,
    ))))

    await store.send(.path(.element(
      id: pathID,
      action: .artist(.topSongTapped(topSongs[0].id)),
    )))
    await store.receive(.delegate(.playback(.playNow(
      items: topSongItems,
      start: .selectedEntry(index: 0),
      context: topSongsContext,
    ))))
  }

  @Test
  func resultContextActionsReuseLibraryAndPlaybackIntents() async {
    let library = ApprovedMusicLibrary.mock
    let album = library.albums[2]
    let track = album.tracks[0]
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(library))
    state.query = "brewed"
    state.results = state.librarySearch.results(query: state.query)
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.resultAddToPlaylistTapped(.song(track.id)))
    await store.receive(.delegate(.library(.addTrackToPlaylistTapped(
      trackID: track.id,
      albumID: album.id,
    ))))

    let item = PlaybackItem(
      track: track,
      artworkURL: track.artworkURL ?? album.artworkURL,
      albumID: album.id,
    )
    await store.send(.resultPlayNextTapped(.song(track.id)))
    await store.receive(.delegate(.playback(.playNext(items: [item]))))
    await store.send(.resultAddToQueueTapped(.song(track.id)))
    await store.receive(.delegate(.playback(.addToQueue(items: [item]))))
  }

  @Test
  func playlistResultPreservesExactOccurrenceProvenance() async {
    let track = ApprovedTrack(
      id: "duplicate",
      title: "Duplicate",
      artistName: "Artist",
      albumID: "album",
    )
    let playlist = MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Favorites",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
      entries: [
        .init(id: .init(rawValue: UUID(2)), track: track),
        .init(id: .init(rawValue: UUID(3)), track: track),
      ],
    )
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(.init(playlists: [playlist])))
    state.query = "favorites"
    state.results = state.librarySearch.results(query: state.query)
    let expectedItems = PlaylistDetailFeature.State(playlist: playlist).playbackItems
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.resultAddToPlaylistTapped(.playlist(playlist.id)))
    await store.receive(.delegate(.library(.addPlaylistToPlaylistTapped(playlist.id))))
    await store.send(.resultAddToQueueTapped(.playlist(playlist.id)))
    await store.receive(.delegate(.playback(.addToQueue(items: expectedItems))))

    expectNoDifference(expectedItems.map(\.playlistSource), [
      PlaylistPlaybackSource(
        playlistID: playlist.id.rawValue,
        entryID: playlist.entries[0].id.rawValue,
      ),
      PlaylistPlaybackSource(
        playlistID: playlist.id.rawValue,
        entryID: playlist.entries[1].id.rawValue,
      ),
    ])
  }

  @Test
  func playlistDetailActionsUseAuthoritativeMutationPipeline() async {
    let playlist = self.playlist()
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(.init(playlists: [playlist])))
    state.path.append(.playlist(.init(playlist: playlist)))
    let pathID = state.path.ids.last!
    let store = TestStore(initialState: state) {
      SearchFeature()
    }

    await store.send(.path(.element(
      id: pathID,
      action: .playlist(.delegate(.addToPlaylist)),
    )))
    await store.receive(.delegate(.library(.addPlaylistToPlaylistTapped(playlist.id))))

    await store.send(.path(.element(
      id: pathID,
      action: .playlist(.delegate(.rename("Renamed"))),
    )))
    await store.receive(.delegate(.library(.playlistRenameSubmitted(
      playlistID: playlist.id,
      expectedRevision: playlist.revision,
      name: "Renamed",
    ))))

    await store.send(.path(.element(
      id: pathID,
      action: .playlist(.delegate(.addMusic)),
    )))
    await store.receive(.delegate(.library(.playlistMusicPickerRequested(
      playlist.id,
    ))))
  }

  @Test
  func libraryReplacementReranksAndReconcilesDetail() {
    let playlist = self.playlist()
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(.init(playlists: [playlist])))
    state.query = "favorites"
    state.results = state.librarySearch.results(query: state.query)
    state.path.append(.playlist(.init(playlist: playlist)))

    var renamed = playlist
    renamed.name = "Road Trip"
    renamed.revision = 2
    state.applyLibraryStatus(.loaded(.init(playlists: [renamed])))

    #expect(state.results.isEmpty)
    #expect(state.playlistDetail?.playlist == renamed)

    state.applyLibraryStatus(.loaded(.init()))

    #expect(state.path.isEmpty)
    #expect(state.availability == .ready)
  }

  private func playlist() -> MusicPlaylist {
    MusicPlaylist(
      id: .init(rawValue: UUID(1)),
      name: "Favorites",
      revision: 1,
      createdAt: Date(timeIntervalSince1970: 1),
      updatedAt: Date(timeIntervalSince1970: 1),
    )
  }
}
