import ComposableArchitecture
import MusicRoute

@Reducer
struct PlaylistMusicPickerFeature {
  enum DuplicatePrompt: Equatable {
    case batch(duplicateCount: Int)
    case track(title: String)
  }

  @ObservableState
  struct State: Equatable {
    let playlistID: MusicPlaylist.ID
    var playlistName: String

    var duplicateConfirmation: MusicPlaylistBatchDuplicateConfirmation?
    var librarySearch: MusicLibrarySearch
    var query = ""
    var results: [MusicSearchResult] = []
    var selectedResultIDs: [MusicSearchResult.ID] = []

    init(playlist: MusicPlaylist, library: ApprovedMusicLibrary) {
      self.playlistID = playlist.id
      self.playlistName = playlist.name
      self.librarySearch = .init(library: library)
    }

    var duplicatePrompt: DuplicatePrompt? {
      guard let duplicateConfirmation = self.duplicateConfirmation else { return nil }
      if self.selectedResultIDs.count == 1,
         case .song(let trackID) = self.selectedResultIDs[0],
         duplicateConfirmation.duplicates.count == 1,
         let duplicate = duplicateConfirmation.duplicates.first,
         duplicate.trackId == trackID.rawValue {
        return .track(title: duplicate.title)
      }
      return .batch(duplicateCount: duplicateConfirmation.duplicates.count)
    }

    var selectedSources: [MusicPlaylistSourceSelection] {
      self.selectedResultIDs.compactMap { id in
        self.librarySearch.result(id: id)?.playlistSource
      }
    }

    mutating func applyLibrary(_ library: ApprovedMusicLibrary) {
      guard let playlist = library.playlist(id: self.playlistID) else { return }
      self.playlistName = playlist.name
      self.duplicateConfirmation = nil
      self.librarySearch = .init(library: library)
      self.results = self.addableResults(query: self.query)
      self.selectedResultIDs = self.selectedResultIDs.filter { id in
        self.librarySearch.result(id: id)?.playlistSource != nil
      }
    }

    func addableResults(query: String) -> [MusicSearchResult] {
      Array(self.librarySearch.results(query: query, limit: .max)
        .lazy
        .filter(\.isPlaylistAddable)
        .prefix(30))
    }
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case addRequested(
        sources: [MusicPlaylistSourceSelection],
        duplicateResolution: MusicPlaylistBatchDuplicateResolution,
      )
    }

    case addButtonTapped
    case delegate(DelegateAction)
    case dismissButtonTapped
    case duplicateConfirmationCancelled
    case duplicateConfirmationReceived(MusicPlaylistBatchDuplicateConfirmation)
    case duplicateResolutionSelected(MusicPlaylistBatchDuplicateResolution)
    case queryChanged(String)
    case resultTapped(MusicSearchResult.ID)
  }

  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addButtonTapped:
        let sources = state.selectedSources
        guard !sources.isEmpty else { return .none }
        return .send(.delegate(.addRequested(
          sources: sources,
          duplicateResolution: .requestConfirmation,
        )))

      case .dismissButtonTapped:
        return .run { _ in
          await self.dismiss()
        }

      case .duplicateConfirmationCancelled:
        state.duplicateConfirmation = nil
        return .none

      case .duplicateConfirmationReceived(let confirmation):
        guard confirmation.playlistId == state.playlistID.rawValue else { return .none }
        state.duplicateConfirmation = confirmation
        return .none

      case .duplicateResolutionSelected(let resolution):
        guard state.duplicateConfirmation != nil else { return .none }
        let sources = state.selectedSources
        guard !sources.isEmpty else { return .none }
        state.duplicateConfirmation = nil
        return .send(.delegate(.addRequested(
          sources: sources,
          duplicateResolution: resolution,
        )))

      case .queryChanged(let query):
        state.query = query
        state.results = state.addableResults(query: query)
        return .none

      case .resultTapped(let id):
        guard state.results.contains(where: { $0.id == id }),
              state.librarySearch.result(id: id)?.playlistSource != nil
        else { return .none }
        if let index = state.selectedResultIDs.firstIndex(of: id) {
          state.selectedResultIDs.remove(at: index)
        } else {
          state.selectedResultIDs.append(id)
        }
        return .none

      case .delegate:
        return .none
      }
    }
  }
}

private extension MusicSearchResult {
  var isPlaylistAddable: Bool {
    self.playlistSource != nil
  }

  var playlistSource: MusicPlaylistSourceSelection? {
    switch self.source {
    case .album(let album):
      .album(albumId: album.id.rawValue)
    case .song(let track, let albumID, _, _):
      .track(trackId: track.id.rawValue, albumId: albumID.rawValue)
    case .artist, .playlist:
      nil
    }
  }
}
