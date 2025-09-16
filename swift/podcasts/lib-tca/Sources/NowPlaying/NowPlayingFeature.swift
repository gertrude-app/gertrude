import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

@Reducer
struct NowPlayingFeature: Downloader {
  @ObservableState
  struct State: Equatable {
    @Fetch(NowPlaying()) var data: NowPlaying.Value = nil
  }

  enum Action: Equatable {
    case view(NowPlayingView.Event)
    case episodePlayPauseTapped(Episode, Show)
  }

  @Dependency(\.defaultDatabase) var db
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.date) var date

  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .view(let viewAction):
        guard let nowPlaying = state.data else {
          return .none
        }
        switch viewAction {
        case .miniPlayerTapped, .dismissed:
          return .run { _ in
            try nowPlaying.updateState { $0.minimized.toggle() }
          }
        case .playPauseTapped:
          return .run { _ in
            try nowPlaying.updateState { $0.isPlaying.toggle() }
          }
        default:
          return .none
        }
      case .episodePlayPauseTapped(let episode, let show):
        return .run { [state] _ in
          await self.ensureDownloaded(episode: episode)
          if state.data?.episode.id == episode.id {
            try state.data?.updateState { $0.isPlaying.toggle() }
          } else {
            try NowPlaying.set(
              episode: episode,
              show: show,
              state: .init(isPlaying: true, minimized: true)
            )
          }
        }
      }
    }
  }
}
