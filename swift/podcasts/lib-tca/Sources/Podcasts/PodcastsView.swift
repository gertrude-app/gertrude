import ComposableArchitecture
import LibViews
import SwiftUI

struct PodcastsView: View {
  @Bindable var store: StoreOf<PodcastsFeature>

  var body: some View {
    PodcastsHomeView(shows: self.store.shows.map {
      .init(id: $0.id, title: $0.name, artworkURL: $0.artworkURL)
    }, onAddShowTap: {})
      .navigationBarBackButtonHidden(true)
  }
}
