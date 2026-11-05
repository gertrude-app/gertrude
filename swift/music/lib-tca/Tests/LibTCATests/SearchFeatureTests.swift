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
  func collectionTapsDelegateToLibrarySelection() async {
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

    await store.send(.resultTapped(.album(album.id)))
    await store.receive(.delegate(.collectionSelected(.album(album.id))))
    await store.send(.queryChanged("vasen")) {
      $0.query = "vasen"
      $0.results = $0.librarySearch.results(query: "vasen")
    }
    await store.send(.resultAddToPlaylistTapped(.artist(artist.id)))
    await store.receive(.delegate(.library(.addArtistToPlaylistTapped(artist.id))))
    await store.send(.resultTapped(.artist(artist.id)))
    await store.receive(.delegate(.collectionSelected(.artist(artist.id))))
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
  func libraryReplacementReranksSearchResults() {
    let playlist = favoriteMusicPlaylist
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(.init(playlists: [playlist])))
    state.query = "favorites"
    state.results = state.librarySearch.results(query: state.query)

    var renamed = playlist
    renamed.name = "Road Trip"
    renamed.revision = 2
    state.applyLibraryStatus(.loaded(.init(playlists: [renamed])))

    #expect(state.results.isEmpty)
    #expect(state.librarySearch.result(id: .playlist(playlist.id))?.source == .playlist(renamed))

    state.applyLibraryStatus(.loaded(.init()))

    #expect(state.results.isEmpty)
    #expect(state.librarySearch.result(id: .playlist(playlist.id)) == nil)
  }

  @Test
  func unavailableLibraryClearsTheSearchIndex() {
    var state = SearchFeature.State()
    state.applyLibraryStatus(.loaded(.mock))
    state.query = "brewed"
    state.results = state.librarySearch.results(query: state.query)

    state.applyLibraryStatus(.loading)

    #expect(state.query == "brewed")
    #expect(state.results.isEmpty)
    #expect(state.librarySearch.results(query: "brewed").isEmpty)
  }
}
