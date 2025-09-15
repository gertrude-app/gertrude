import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

@Reducer
struct NowPlayingFeature {
  @ObservableState
  struct State: Equatable {
    @Fetch(NowPlaying()) var data: NowPlaying.Value = nil
  }

  enum Action: Equatable {
    case view(NowPlayingView.Event)
    case episodePlayPauseTapped(Episode, Show)
  }

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(.miniPlayerTapped), .view(.dismissed):
        return .run { [state] _ in
          try state.data?.updateState { $0.minimized.toggle() }
        }
      case .view(.playPauseTapped):
        return .run { [state] _ in
          try state.data?.updateState { $0.isPlaying.toggle() }
        }
      case .episodePlayPauseTapped(let episode, let show):
        if state.data?.episode.id == episode.id {
          return .run { [state] _ in
            try state.data?.updateState { $0.isPlaying.toggle() }
          }
        }
        return .run { _ in
          try NowPlaying.set(
            episode: episode,
            show: show,
            state: .init(isPlaying: true, minimized: true)
          )
        }
      default:
        return .none
      }
    }
  }
}
