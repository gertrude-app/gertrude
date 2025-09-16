import ComposableArchitecture
import LibViews
import SharingGRDB
import SwiftUI

struct PodcastsView: View {
  @Bindable var store: StoreOf<PodcastsFeature>
  @Fetch(AnyNowPlaying()) var nowPlayingShowing: Bool = false

  var body: some View {
    PodcastsHomeView(
      shows: self.store.shows.map {
        .init(id: $0.id.rawValue, title: $0.name, artworkUrl: $0.artworkUrl)
      },
      nowPlayingShowing: self.nowPlayingShowing,
      onAddShowTap: { self.store.send(.addShowTapped) },
      onShowTap: { self.store.send(.showTapped(.init($0))) }
    )
    .navigationBarBackButtonHidden(true)
    .navigationDestination(
      item: self.$store.scope(
        state: \.destination?.addShow,
        action: \.destination.addShow
      ),
      destination: { store in
        AddShowView(store: store)
      }
    )
    .navigationDestination(
      item: self.$store.scope(
        state: \.destination?.show,
        action: \.destination.show
      ),
      destination: { store in
        ShowViewContainer(store: store)
      }
    )
  }
}
