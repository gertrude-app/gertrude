import ComposableArchitecture
import Dependencies
import LibViews
import SQLiteData
import SwiftUI

struct EpisodeViewContainer: View {
  @Bindable var store: StoreOf<EpisodeFeature>

  var body: some View {
    EpisodeDetailView(
      episode: .init(
        episode: .init(
          from: self.store.episode,
          isPlaying: self.store.nowPlaying.isPlaying(episodeId: self.store.episode.id),
          bufferedProgress: nil
        ),
        websiteUrl: self.store.show.websiteUrl.flatMap(URL.init(string:)),
        sizeInBytes: self.store.episode.sizeInBytes,
      ),
      show: .init(from: self.store.show),
    ) { action in
      self.store.send(.view(action))
    }
  }
}
