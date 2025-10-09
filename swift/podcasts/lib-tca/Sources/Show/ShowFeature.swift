import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

@Reducer
struct ShowFeature {
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
      case error(String)
    }

    case episodeView(Episode.ID, EpisodeView.Event)
    case delegate(DelegateAction)
    case destination(PresentationAction<Destination.Action>)
  }

  @Dependency(\.db) var database
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
          return .run { send in
            if let error = await ensureDownloaded(episode: episode).error {
              await send(.delegate(.error(error.message)))
            }
          }
        case .playPauseTapped:
          return .send(.delegate(.episodePlayPauseTapped(episode, state.show)))
        case .episodeTapped:
          state.destination = .episode(.init(episode: episode, show: state.show))
          return .none
        case .removeDownloadTapped:
          return .run { _ in
            episode.removeLocalAudioFile()
            self.database.tryWrite { db in
              try Episode
                .update { $0.downloadedAt = nil }
                .where { $0.id == episode.id }
                .execute(db)
            }
          }
        case .toggleCompletedTapped:
          return .run { _ in
            self.database.tryWrite { db in
              try Episode
                .update { $0.completedAt = episode.completedAt == nil ? self.date.now : nil }
                .where { $0.id == episode.id }
                .execute(db)
            }
          }
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
