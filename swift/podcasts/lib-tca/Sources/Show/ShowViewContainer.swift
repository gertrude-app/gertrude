import ComposableArchitecture
import LibViews
import SQLiteData
import SwiftUI

struct ShowViewContainer: View {
  @Bindable var store: StoreOf<ShowFeature>
  @Fetch(NowPlaying()) var nowPlaying: NowPlaying.Value = nil

  var body: some View {
    ShowView(
      show: .init(from: self.store.show),
      episodes: self.store.episodes.map { .init(
        from: $0,
        isPlaying: self.nowPlaying.isPlaying(episodeId: $0.id),
        bufferedProgress: self.nowPlaying.bufferedProgress(episodeId: $0.id),
      ) },
      showArchivedEpisodes: self.store.showArchivedEpisodes,
      sortNewestToOldest: self.store.show.sort == .newestToOldest,
      headerPlayButtonState: self.store.headerPlayButtonState.viewState,
      onEpisodeEvent: { episodeId, event in
        self.store.send(.episodeView(.init(episodeId), event))
      },
      onEvent: { event in
        self.store.send(.showView(event))
      }
    )
    .navigationDestination(
      item: self.$store.scope(
        state: \.destination?.episode,
        action: \.destination.episode
      ),
      destination: { store in
        EpisodeViewContainer(store: store)
      }
    )
  }
}

extension ShowFeature.State.HeaderPlayButtonState {
  var viewState: ShowView.HeaderPlayButtonState {
    switch self {
    case .resume(let episode, let isPlaying):
      .resume(episodeTitle: episode.title, isPlaying: isPlaying)
    case .playLatest(_, let isPlaying):
      .playLatest(isPlaying: isPlaying)
    case .none:
      .none
    }
  }
}
