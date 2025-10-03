import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct ShowFeature: Downloader {
  @ObservableState
  struct State: Equatable {
    var showId: Show.ID
    @FetchOne var show: Show
    @FetchAll var episodes: [Episode]
    @Presents var destination: Destination.State?
  }

  @Reducer(state: .equatable, action: .equatable)
  enum Destination {
    case episode(EpisodeFeature)
  }

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case episodePlayPauseTapped(Episode, Show)
    }

    case episodeView(Episode.ID, EpisodeView.Event)
    case delegate(DelegateAction)
    case destination(PresentationAction<Destination.Action>)
  }

  @Dependency(\.defaultDatabase) var database
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.date) var date

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .episodeView(let episodeId, let episodeAction):
        guard let episode = state.episodes.first(where: { $0.id == episodeId }) else {
          unexpected(id: "60324a0d", assert: true)
          return .none
        }
        switch episodeAction {
        case .downloadTapped:
          return .run { _ in
            await self.trackedDownload(episode: episode)
          }
        case .playPauseTapped:
          return .send(.delegate(.episodePlayPauseTapped(episode, state.show)))
        case .episodeTapped:
          state.destination = .episode(.init(episode: episode, show: state.show))
          return .none
        }
      case .destination:
        return .none
      case .delegate:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination)
  }
}

extension ShowFeature.State {
  init(show: Show) {
    self.showId = show.id
    self._show = FetchOne(
      wrappedValue: show,
      Show.where { $0.id == show.id }
    )
    self._episodes = FetchAll(
      Episode
        .where { $0.showId == show.id }
        .order { ($0.episodeNumber.desc(), $0.pubDate.desc()) }
    )
  }
}
