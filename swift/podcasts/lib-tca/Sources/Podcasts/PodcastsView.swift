import ComposableArchitecture
import LibViews
import SwiftUI

struct PodcastsView: View {
  @Bindable var store: StoreOf<PodcastsFeature>

  var body: some View {
    PodcastsHomeView(shows: self.store.shows.map {
      .init(id: $0.id, title: $0.name, artworkUrl: $0.artworkUrl)
    }) {
      self.store.send(.addShowTapped)
    }
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
  }
}
