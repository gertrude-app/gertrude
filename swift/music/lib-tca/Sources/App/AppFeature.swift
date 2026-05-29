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

      case .library(.delegate(.playAlbum(let items, let startIndex))):
        return .send(.playback(.playAlbumQueue(items: items, startIndex: startIndex)))

      case .library(.delegate(.togglePlayPause)):
        return .send(.playback(.togglePlayPause))

      case .library:
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        return .none

      case .playback:
        state.library.setAlbumDetailPlaybackSession(state.playback.session)
        return .none
      }
    }
  }
}
