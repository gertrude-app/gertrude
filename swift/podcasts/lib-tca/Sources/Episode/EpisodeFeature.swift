import ComposableArchitecture
import LibViews
import SQLiteData

@Reducer
struct EpisodeFeature {
  @ObservableState
  struct State: Equatable {
    @Fetch(NowPlaying()) var nowPlaying: NowPlaying.Value = nil
    @FetchOne var episode: Episode
    @FetchOne var show: Show
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case episodePlayPauseTapped(Episode, Show)
    }

    case view(EpisodeDetailView.Event)
    case delegate(DelegateAction)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .view(.playPauseTapped):
        .send(.delegate(.episodePlayPauseTapped(state.episode, state.show)))
      case .delegate:
        .none
      }
    }
  }
}

extension EpisodeFeature.State {
  init(episode: Episode, show: Show) {
    self._show = FetchOne(
      wrappedValue: show,
      Show.where { $0.id == show.id },
    )
    self._episode = FetchOne(
      wrappedValue: episode,
      Episode.where { $0.id == episode.id },
    )
  }
}
