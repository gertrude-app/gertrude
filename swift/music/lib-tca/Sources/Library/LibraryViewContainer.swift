import ComposableArchitecture
import LibViews
import SwiftUI

struct LibraryViewContainer: View {
  @Bindable var store: StoreOf<LibraryFeature>
  @Namespace private var zoomNamespace

  var body: some View {
    let albumDetailStore = self.albumDetailStore

    NavigationStack {
      LibraryView(
        state: self.store.viewState,
        isRefreshing: self.store.isRefreshingRemoteLibrary,
        transitionNamespace: self.zoomNamespace,
        onRetryTap: { self.store.send(.retryButtonTapped) },
        onRefresh: {
          self.store.send(.refreshPulled)
        },
        onAlbumTap: { self.store.send(.albumTapped(.init($0))) },
        onDebugResetTap: { self.store.send(.debugResetOnboardingButtonTapped) },
      )
      .albumDetailZoomPush(
        store: albumDetailStore,
        queuedReplacementPushID: self.store.pendingAlbumDetail?.pushID,
        onDismiss: { self.store.send(.albumDetailDismissed($0)) },
      )
      .onAppear {
        self.store.send(.onAppear)
      }
    }
  }

  private var albumDetailStore: StoreOf<AlbumDetailFeature>? {
    self.$store.scope(
      state: \.albumDetail,
      action: \.albumDetail,
    ).wrappedValue
  }
}

private extension LibraryFeature.State {
  var viewState: LibraryViewState {
    switch self.status {
    case .loading:
      .loading
    case .loaded(let library):
      .loaded(
        albums: library.albums.map(AlbumData.init),
        artists: library.artists.map(ArtistData.init),
      )
    case .empty:
      .empty
    case .failed:
      .failed
    case .subscriptionRequired:
      .subscriptionRequired
    }
  }
}
