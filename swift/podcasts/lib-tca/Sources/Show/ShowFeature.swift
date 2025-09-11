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
}
