import ComposableArchitecture
import LibViews
import SwiftUI

struct ArtistListViewContainer: View {
  @Bindable var store: StoreOf<ArtistListFeature>
  @Namespace private var zoomNamespace

  var body: some View {
    ArtistListView(
      artists: self.store.artists.map(ArtistData.init),
      transitionNamespace: self.zoomNamespace,
      onArtistTap: { self.store.send(.artistTapped(.init($0))) },
    )
    .navigationDestination(
      item: self.$store.scope(
        state: \.destination?.artist,
        action: \.destination.artist,
      ),
    ) { store in
      PlaceholderDestinationView(
        title: store.title,
        transitionSourceID: store.transitionSourceID,
        transitionNamespace: self.zoomNamespace,
      )
    }
  }
}
