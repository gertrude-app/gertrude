import ComposableArchitecture
import SharingGRDB
import SwiftUI

@Reducer
struct ShowFeature {
  @ObservableState
  struct State: Equatable {
    var showId: Int
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
    case episodeTapped(Int)
  }

  @Dependency(\.audioPlayer) var audioPlayer

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .episodeTapped(let episodeId):
        guard let episode = state.episodes.first(where: { $0.id == episodeId }) else {
          return .none
        }
        return .run { _ in
          try await self.audioPlayer.playEpisodeAudio(episode: episode)
        }
      }
    }
  }
}
