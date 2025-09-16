import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

struct ShowViewContainer: View {
  @Bindable var store: StoreOf<ShowFeature>
  @Fetch(NowPlaying()) var nowPlaying: NowPlaying.Value = nil

  var body: some View {
    ShowView(
      show: .init(from: self.store.show),
      episodes: self.store.episodes.map { .init(
        from: $0,
        isPlaying: self.nowPlaying?.isPlaying(episodeId: $0.id) ?? false,
      ) }
    ) { episodeId, event in
      self.store.send(.episodeView(.init(episodeId), event))
    }
  }
}
