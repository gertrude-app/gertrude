import ComposableArchitecture
import LibViews
import SwiftUI

struct AlbumListViewContainer: View {
  @Bindable var store: StoreOf<AlbumListFeature>
  @Namespace private var zoomNamespace

  var body: some View {
    AlbumListView(
      albums: self.store.albums.map(AlbumData.init),
      transitionNamespace: self.zoomNamespace,
      onAlbumTap: { self.store.send(.albumTapped(.init($0))) },
    )
    .albumDetailZoomPush(
      store: self.store.scope(
        state: \.destination?.album,
        action: \.destination.album,
      ),
      onDismiss: { self.store.send(.albumDetailDismissed($0)) },
    )
  }
}
