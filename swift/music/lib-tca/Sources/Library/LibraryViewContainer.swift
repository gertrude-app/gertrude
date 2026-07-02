import ComposableArchitecture
import LibViews
import SwiftUI

struct LibraryViewContainer: View {
  @Bindable var store: StoreOf<LibraryFeature>
  @Namespace private var zoomNamespace
  @State private var searchText = ""

  var body: some View {
    let albumDetailStore = self.albumDetailStore

    NavigationStack {
      LibraryView(
        state: self.store.viewState,
        searchText: self.$searchText,
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
    .albumSearchable(isEnabled: self.store.showsSearchField, text: self.$searchText)
  }

  private var albumDetailStore: StoreOf<AlbumDetailFeature>? {
    self.$store.scope(
      state: \.albumDetail,
      action: \.albumDetail,
    ).wrappedValue
  }
}

private extension LibraryFeature.State {
  var showsSearchField: Bool {
    if case .loaded = self.status {
      true
    } else {
      false
    }
  }

  var viewState: LibraryViewState {
    switch self.status {
    case .loading:
      .loading
    case .loaded(let library):
      .loaded(albums: library.albums.map(AlbumData.init))
    case .empty:
      .empty
    case .failed:
      .failed
    case .subscriptionRequired:
      .subscriptionRequired
    }
  }
}

private extension View {
  @ViewBuilder
  func albumSearchable(isEnabled: Bool, text: Binding<String>) -> some View {
    if isEnabled {
      #if os(iOS)
        self.searchable(
          text: text,
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: "Search albums",
        )
      #else
        self.searchable(text: text, prompt: "Search albums")
      #endif
    } else {
      self
    }
  }
}
