import ComposableArchitecture

@Reducer
struct AppFeature: Sendable {
  @ObservableState
  struct State: Equatable {
    var library = LibraryFeature.State()
    var playback = PlaybackFeature.State()
    var searchText = ""
    var isNowPlayingPresented = false
  }

  enum Action: Equatable {
    case library(LibraryFeature.Action)
    case playback(PlaybackFeature.Action)
    case searchTextChanged(String)
    case nowPlayingPresentationChanged(Bool)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.library, action: \.library) {
      LibraryFeature()
    }

    Scope(state: \.playback, action: \.playback) {
      PlaybackFeature()
    }

    Reduce { state, action in
      switch action {
      case .searchTextChanged(let searchText):
        state.searchText = searchText
        return .none

      case .nowPlayingPresentationChanged(let isPresented):
        state.isNowPlayingPresented = isPresented
        return .none

      case .library(.delegate(.playAlbum(let items))):
        return .send(.playback(.playTracksInOrder(items)))

      case .library(.delegate(.playTrack(let item))):
        return .send(.playback(.playTrack(item)))

      case .library:
        state.library.setAlbumDetailPlaybackStatus(state.playback.status)
        return .none

      case .playback:
        state.library.setAlbumDetailPlaybackStatus(state.playback.status)
        return .none
      }
    }
  }
}
