import ComposableArchitecture

@Reducer
struct SearchFeature: Sendable {
  enum Availability: Equatable, Sendable {
    case emptyLibrary
    case failed
    case loading
    case ready
    case musicAccessUnavailable
  }

  @ObservableState
  struct State: Equatable {
    var availability = Availability.loading
    var librarySearch = MusicLibrarySearch()
    var path = StackState<LibraryPath.State>()
    var query = ""
    var results: [MusicSearchResult] = []

    var albumDetail: AlbumDetailFeature.State? {
      get {
        guard let id = self.path.ids.last else { return nil }
        return self.path[id: id, case: \.album]
      }
      set {
        if let id = self.path.ids.last,
           self.path[id: id, case: \.album] != nil {
          if let newValue {
            self.path[id: id] = .album(newValue)
          } else {
            self.path.pop(from: id)
          }
        } else if let newValue {
          self.path.append(.album(newValue))
        }
      }
    }

    var playlistDetail: PlaylistDetailFeature.State? {
      get {
        guard let id = self.path.ids.last else { return nil }
        return self.path[id: id, case: \.playlist]
      }
      set {
        if let id = self.path.ids.last,
           self.path[id: id, case: \.playlist] != nil {
          if let newValue {
            self.path[id: id] = .playlist(newValue)
          } else {
            self.path.pop(from: id)
          }
        } else if let newValue {
          self.path.append(.playlist(newValue))
        }
      }
    }
  }

  enum DelegateAction: Equatable {
    case browseLibrary
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
    case path(StackActionOf<LibraryPath>)
    case queryChanged(String)
    case resultAddToPlaylistTapped(MusicSearchResult.ID)
    case resultAddToQueueTapped(MusicSearchResult.ID)
    case resultPlayNextTapped(MusicSearchResult.ID)
    case resultTapped(MusicSearchResult.ID)
    case retryButtonTapped
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
          state.path.append(.album(.init(
            album: album,
            transitionSourceID: album.id.rawValue,
          )))
          return .none
        case .artist(let artist):
          state.path.append(.artist(.init(artistID: artist.id)))
          return .none
        case .playlist(let playlist):
          state.path.append(.playlist(.init(playlist: playlist)))
          return .none
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
        return self.queueResult(
          resultID,
          position: .tail,
          state: state,
        )

      case .resultPlayNextTapped(let resultID):
        return self.queueResult(
          resultID,
          position: .next,
          state: state,
        )

      case .retryButtonTapped:
        return .send(.delegate(.library(.retryButtonTapped)))

      case .path(.element(id: let id, action: .album(.delegate(let delegateAction)))):
        guard let album = state.path[id: id, case: \.album]?.album else { return .none }
        switch delegateAction {
        case .addAlbumToPlaylist(let albumID):
          return .send(.delegate(.library(.addAlbumToPlaylistTapped(albumID))))
        case .addToQueue(let items):
          return .send(.delegate(.playback(.addToQueue(items: items))))
        case .dismissPlaybackFailure:
          return .send(.delegate(.playback(.dismissPlaybackFailure)))
        case .playbackFailureActionTapped:
          return .send(.delegate(.playback(.playbackFailureActionTapped)))
        case .playNext(let items):
          return .send(.delegate(.playback(.playNext(items: items))))
        case .playNow(let items, let start):
          return .send(.delegate(.playback(.playNow(
            items: items,
            start: start,
            context: PlaybackContext(
              identity: .album(album.id),
              title: album.title,
            ),
          ))))
        case .togglePlayPause:
          return .send(.delegate(.playback(.togglePlayPause)))
        case .addTrackToPlaylist(let trackID, let albumID):
          return .send(.delegate(.library(.addTrackToPlaylistTapped(
            trackID: trackID,
            albumID: albumID,
          ))))
        }

      case .path(.element(id: let id, action: .artist(.addToPlaylistTapped))):
        guard let artistID = state.path[id: id, case: \.artist]?.artistID
        else { return .none }
        return .send(.delegate(.library(.addArtistToPlaylistTapped(artistID))))

      case .path(.element(id: let id, action: .artist(.addToQueueTapped))):
        guard let items = self.artistDiscographyPlaybackItems(pathID: id, state: state)
        else { return .none }
        return .send(.delegate(.playback(.addToQueue(items: items))))

      case .path(.element(id: let id, action: .artist(.playButtonTapped))):
        guard let items = self.artistDiscographyPlaybackItems(pathID: id, state: state),
              let context = self.artistPlaybackContext(
                pathID: id,
                source: .discography,
                state: state,
              )
        else { return .none }
        return .send(.delegate(.playback(.artistPlaybackButtonTapped(
          items: items,
          context: context,
        ))))

      case .path(.element(id: let id, action: .artist(.playNextTapped))):
        guard let items = self.artistDiscographyPlaybackItems(pathID: id, state: state)
        else { return .none }
        return .send(.delegate(.playback(.playNext(items: items))))

      case .path(.element(
        id: let id,
        action: .artist(.releaseAddToPlaylistTapped(let albumID)),
      )):
        guard state.path[id: id, case: \.artist] != nil else { return .none }
        return .send(.delegate(.library(.addAlbumToPlaylistTapped(albumID))))

      case .path(.element(
        id: let id,
        action: .artist(.releaseAddToQueueTapped(let albumID)),
      )):
        guard state.path[id: id, case: \.artist] != nil,
              let result = state.librarySearch.result(id: .album(albumID)),
              !result.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.playback(.addToQueue(items: result.playbackItems))))

      case .path(.element(
        id: let id,
        action: .artist(.releasePlayNextTapped(let albumID)),
      )):
        guard state.path[id: id, case: \.artist] != nil,
              let result = state.librarySearch.result(id: .album(albumID)),
              !result.playbackItems.isEmpty else { return .none }
        return .send(.delegate(.playback(.playNext(items: result.playbackItems))))

      case .path(.element(
        id: let id,
        action: .artist(.releaseTapped(let albumID)),
      )):
        guard state.path[id: id, case: \.artist] != nil,
              let result = state.librarySearch.result(id: .album(albumID)),
              case .album(let album) = result.source else { return .none }
        state.path.append(.album(.init(
          album: album,
          transitionSourceID: albumID.rawValue,
        )))
        return .none

      case .path(.element(
        id: let id,
        action: .artist(.topSongAddToPlaylistTapped(let trackID)),
      )):
        guard let track = self.artistTrack(pathID: id, trackID: trackID, state: state),
              let albumID = track.albumID else { return .none }
        return .send(.delegate(.library(.addTrackToPlaylistTapped(
          trackID: trackID,
          albumID: albumID,
        ))))

      case .path(.element(
        id: let id,
        action: .artist(.topSongAddToQueueTapped(let trackID)),
      )):
        guard let item = self.artistTopSongsPlaybackItems(pathID: id, state: state)?
          .first(where: { $0.id == trackID }) else { return .none }
        return .send(.delegate(.playback(.addToQueue(items: [item]))))

      case .path(.element(
        id: let id,
        action: .artist(.topSongPlayNextTapped(let trackID)),
      )):
        guard let item = self.artistTopSongsPlaybackItems(pathID: id, state: state)?
          .first(where: { $0.id == trackID }) else { return .none }
        return .send(.delegate(.playback(.playNext(items: [item]))))

      case .path(.element(
        id: let id,
        action: .artist(.topSongTapped(let trackID)),
      )):
        guard let items = self.artistTopSongsPlaybackItems(pathID: id, state: state),
              let startIndex = items.firstIndex(where: { $0.id == trackID }),
              let context = self.artistPlaybackContext(
                pathID: id,
                source: .topSongs,
                state: state,
              )
        else { return .none }
        return .send(.delegate(.playback(.playNow(
          items: items,
          start: .selectedEntry(index: startIndex),
          context: context,
        ))))

      case .path(.element(id: let id, action: .playlist(.delegate(let delegateAction)))):
        guard let detail = state.path[id: id, case: \.playlist] else { return .none }
        switch delegateAction {
        case .addToPlaylist:
          return .send(.delegate(.library(.addPlaylistToPlaylistTapped(
            detail.playlist.id,
          ))))

        case .addEntryToPlaylist(let entryID):
          guard let track = detail.playlist.entries.first(where: {
            $0.id == entryID
          })?.track,
            let albumID = track.albumID else { return .none }
          return .send(.delegate(.library(.addTrackToPlaylistTapped(
            trackID: track.id,
            albumID: albumID,
          ))))

        case .addMusic:
          return .send(.delegate(.library(.playlistMusicPickerRequested(
            detail.playlist.id,
          ))))

        case .addToQueue(let items):
          return .send(.delegate(.playback(.addToQueue(items: items))))

        case .delete:
          return .send(.delegate(.library(.playlistDeleteConfirmed(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
          ))))

        case .dismissPlaybackFailure:
          return .send(.delegate(.playback(.dismissPlaybackFailure)))

        case .playbackFailureActionTapped:
          return .send(.delegate(.playback(.playbackFailureActionTapped)))

        case .playNext(let items):
          return .send(.delegate(.playback(.playNext(items: items))))

        case .playNow(let items, let start):
          return .send(.delegate(.playback(.playNow(
            items: items,
            start: start,
            context: PlaybackContext(
              identity: .playlist(detail.playlist.id),
              title: detail.playlist.name,
            ),
          ))))

        case .removeEntry(let entryID):
          return .send(.delegate(.library(.playlistEntryRemoveTapped(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
            entryID: entryID,
          ))))

        case .rename(let name):
          return .send(.delegate(.library(.playlistRenameSubmitted(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
            name: name,
          ))))

        case .reorder(let entryIDs):
          return .send(.delegate(.library(.playlistReorderSubmitted(
            playlistID: detail.playlist.id,
            expectedRevision: detail.playlist.revision,
            entryIDs: entryIDs,
          ))))

        case .togglePlayPause:
          return .send(.delegate(.playback(.togglePlayPause)))
        }

      case .delegate, .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      LibraryPath.body
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

  private func artistDiscographyPlaybackItems(
    pathID: StackElementID,
    state: State,
  ) -> [PlaybackItem]? {
    guard let artistID = state.path[id: pathID, case: \.artist]?.artistID else { return nil }
    let items = state.librarySearch.artistDiscographyPlaybackItems(for: artistID)
    return items.isEmpty ? nil : items
  }

  private func artistTopSongsPlaybackItems(
    pathID: StackElementID,
    state: State,
  ) -> [PlaybackItem]? {
    guard let artistID = state.path[id: pathID, case: \.artist]?.artistID else { return nil }
    let items = state.librarySearch.artistTopSongsPlaybackItems(for: artistID)
    return items.isEmpty ? nil : items
  }

  private func artistPlaybackContext(
    pathID: StackElementID,
    source: PlaybackContext.ArtistSource,
    state: State,
  ) -> PlaybackContext? {
    guard let artistID = state.path[id: pathID, case: \.artist]?.artistID,
          let result = state.librarySearch.result(id: .artist(artistID)),
          case .artist(let artist) = result.source else { return nil }
    return PlaybackContext(
      identity: .artist(artist.id),
      title: artist.name,
      artistSource: source,
    )
  }

  private func artistTrack(
    pathID: StackElementID,
    trackID: ApprovedTrack.ID,
    state: State,
  ) -> ApprovedTrack? {
    guard let artistID = state.path[id: pathID, case: \.artist]?.artistID,
          let result = state.librarySearch.result(id: .artist(artistID)),
          case .artist(let artist) = result.source else { return nil }
    return artist.topSongs?.first(where: { $0.id == trackID })
  }
}

extension SearchFeature.State {
  mutating func applyLibraryStatus(_ status: LibraryFeature.Status) {
    switch status {
    case .loading:
      self.availability = .loading
      self.librarySearch = MusicLibrarySearch()
      self.results = []
      self.path.removeAll()

    case .loaded(let library):
      self.availability = .ready
      self.librarySearch = MusicLibrarySearch(library: library)
      self.results = self.librarySearch.results(query: self.query)
      self.path.reconcile(with: library)

    case .empty:
      self.availability = .emptyLibrary
      self.librarySearch = MusicLibrarySearch()
      self.results = []
      self.path.removeAll()

    case .failed:
      self.availability = .failed
      self.librarySearch = MusicLibrarySearch()
      self.results = []
      self.path.removeAll()

    case .musicAccessUnavailable:
      self.availability = .musicAccessUnavailable
      self.librarySearch = MusicLibrarySearch()
      self.results = []
      self.path.removeAll()
    }
  }

  mutating func setAlbumDetailPlaybackFailure(_ failure: PlaybackFailure?) {
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackFailure(failure)
    self.albumDetail = albumDetail
  }

  mutating func setAlbumDetailPlaybackSession(
    _ session: PlaybackFeature.Session?,
    activeContext: PlaybackContext?,
  ) {
    guard var albumDetail = self.albumDetail else { return }
    albumDetail.setPlaybackSession(session, activeContext: activeContext)
    self.albumDetail = albumDetail
  }

  mutating func setPlaylistDetailPlaybackFailure(_ failure: PlaybackFailure?) {
    guard var playlistDetail = self.playlistDetail else { return }
    playlistDetail.setPlaybackFailure(failure)
    self.playlistDetail = playlistDetail
  }

  mutating func setPlaylistDetailPlaybackSession(
    _ session: PlaybackFeature.Session?,
    activeContext: PlaybackContext?,
  ) {
    guard var playlistDetail = self.playlistDetail else { return }
    playlistDetail.setPlaybackSession(session, activeContext: activeContext)
    self.playlistDetail = playlistDetail
  }
}
