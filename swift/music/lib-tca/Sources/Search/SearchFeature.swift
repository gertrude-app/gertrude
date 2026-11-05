import ComposableArchitecture

@Reducer
struct SearchFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var librarySearch = MusicLibrarySearch()
    var query = ""
    var results: [MusicSearchResult] = []
  }

  enum DelegateAction: Equatable {
    case collectionSelected(LibraryCollectionIdentity)
    case library(LibraryFeature.Action)
    case playback(LibraryFeature.DelegateAction)
    case songTapped(
      items: [PlaybackItem],
      start: PlaybackStartIntent,
      context: PlaybackContext?,
    )
  }

  enum Action: Equatable {
    case delegate(DelegateAction)
    case queryChanged(String)
    case resultAddToPlaylistTapped(MusicSearchResult.ID)
    case resultAddToQueueTapped(MusicSearchResult.ID)
    case resultPlayNextTapped(MusicSearchResult.ID)
    case resultTapped(MusicSearchResult.ID)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .queryChanged(let query):
        state.query = query
        state.results = state.librarySearch.results(query: query)
        return .none

      case .resultTapped(let resultID):
        guard state.results.contains(where: { $0.id == resultID }),
              let result = state.librarySearch.result(id: resultID) else { return .none }
        switch result.source {
        case .album(let album):
          return .send(.delegate(.collectionSelected(.album(album.id))))
        case .artist(let artist):
          return .send(.delegate(.collectionSelected(.artist(artist.id))))
        case .playlist(let playlist):
          return .send(.delegate(.collectionSelected(.playlist(playlist.id))))
        case .song(let track, let albumID, _, _):
          guard let item = result.playbackItems.first else { return .none }
          guard let albumResult = state.librarySearch.result(id: .album(albumID)),
                case .album(let album) = albumResult.source,
                let startIndex = album.tracks.firstIndex(where: { $0.id == track.id })
          else {
            return .send(.delegate(.songTapped(
              items: [item],
              start: .selectedEntry(index: 0),
              context: nil,
            )))
          }
          return .send(.delegate(.songTapped(
            items: albumResult.playbackItems,
            start: .selectedEntry(index: startIndex),
            context: PlaybackContext(
              identity: .album(album.id),
              title: album.title,
            ),
          )))
        }

      case .resultAddToPlaylistTapped(let resultID):
        guard state.results.contains(where: { $0.id == resultID }),
              let result = state.librarySearch.result(id: resultID) else { return .none }
        switch result.source {
        case .album(let album):
          guard !album.tracks.isEmpty else { return .none }
          return .send(.delegate(.library(.addAlbumToPlaylistTapped(album.id))))
        case .artist(let artist):
          return .send(.delegate(.library(.addArtistToPlaylistTapped(artist.id))))
        case .song(let track, let albumID, _, _):
          return .send(.delegate(.library(.addTrackToPlaylistTapped(
            trackID: track.id,
            albumID: albumID,
          ))))
        case .playlist(let playlist):
          return .send(.delegate(.library(.addPlaylistToPlaylistTapped(playlist.id))))
        }

      case .resultAddToQueueTapped(let resultID):
        return self.queueResult(resultID, position: .tail, state: state)

      case .resultPlayNextTapped(let resultID):
        return self.queueResult(resultID, position: .next, state: state)

      case .delegate:
        return .none
      }
    }
  }

  private func queueResult(
    _ resultID: MusicSearchResult.ID,
    position: PlaybackQueueInsertionPosition,
    state: State,
  ) -> EffectOf<Self> {
    guard state.results.contains(where: { $0.id == resultID }),
          let result = state.librarySearch.result(id: resultID) else { return .none }
    let items = switch result.source {
    case .artist(let artist):
      state.librarySearch.artistDiscographyPlaybackItems(for: artist.id)
    case .album, .playlist, .song:
      result.playbackItems
    }
    guard !items.isEmpty else { return .none }
    switch position {
    case .next:
      return .send(.delegate(.playback(.playNext(items: items))))
    case .tail:
      return .send(.delegate(.playback(.addToQueue(items: items))))
    }
  }
}

extension SearchFeature.State {
  mutating func applyLibraryStatus(_ status: LibraryFeature.Status) {
    switch status {
    case .loaded(let library):
      guard !self.librarySearch.isBuilt(from: library) else { return }
      self.librarySearch = MusicLibrarySearch(library: library)
      self.results = self.librarySearch.results(query: self.query)
    case .loading, .empty, .failed, .musicAccessUnavailable:
      guard !self.librarySearch.isBuilt(from: nil) else { return }
      self.librarySearch = MusicLibrarySearch()
      self.results = []
    }
  }
}
