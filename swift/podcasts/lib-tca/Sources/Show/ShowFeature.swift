import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

@Reducer
struct ShowFeature: Downloader {
  @ObservableState
  struct State: Equatable {
    var showId: Show.ID
    @FetchOne var show: Show
    @FetchAll var episodes: [Episode]

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

  enum Action: Equatable {
    enum DelegateAction: Equatable {
      case episodePlayPauseTapped(Episode, Show)
    }

    case episodeView(Episode.ID, EpisodeView.Event)
    case delegate(DelegateAction)
  }

  @Dependency(\.defaultDatabase) var db
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.date) var date

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .episodeView(let episodeId, let episodeAction):
        guard let episode = state.episodes.first(where: { $0.id == episodeId }) else {
          reportIssue("Episode with id \(episodeId) not found")
          return .none
        }
        switch episodeAction {
        case .downloadTapped:
          return .run { _ in
            await self.trackedDownload(episode: episode)
          }
        case .playPauseTapped:
          return .send(.delegate(.episodePlayPauseTapped(episode, state.show)))
        default:
          return .none
        }
      case .delegate:
        return .none
      }
    }
  }
}
