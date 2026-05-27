import ComposableArchitecture
import LibViews
import SwiftUI

struct LibraryViewContainer: View {
  @Bindable var store: StoreOf<LibraryFeature>
  @Namespace private var zoomNamespace

  var body: some View {
    NavigationStack {
      LibraryView(
        state: self.store.viewState,
        transitionNamespace: self.zoomNamespace,
        onRetryTap: { self.store.send(.onAppear) },
        onAlbumsTitleTap: { self.store.send(.albumsTitleTapped) },
        onAlbumTap: { self.store.send(.albumTapped(.init($0))) },
        onArtistsTitleTap: { self.store.send(.artistsTitleTapped) },
        onArtistTap: { self.store.send(.artistTapped(.init($0))) },
        onTracksTitleTap: { self.store.send(.tracksTitleTapped) },
        onTrackTap: { self.store.send(.trackTapped(.init($0))) },
      )
      .albumDetailZoomPush(
        store: self.store.scope(
          state: \.destination?.album,
          action: \.destination.album,
        ),
        onDismiss: { self.store.send(.albumDetailDismissed($0)) },
      )
      .navigationDestination(
        item: self.$store.scope(
          state: \.destination?.albums,
          action: \.destination.albums,
        ),
      ) { store in
        AlbumListViewContainer(store: store)
      }
      .navigationDestination(
        item: self.$store.scope(
          state: \.destination?.artists,
          action: \.destination.artists,
        ),
      ) { store in
        ArtistListViewContainer(store: store)
      }
      .navigationDestination(
        item: self.$store.scope(
          state: \.destination?.artist,
          action: \.destination.artist,
        ),
      ) { store in
        self.placeholderDestination(store)
      }
      .navigationDestination(
        item: self.$store.scope(
          state: \.destination?.tracks,
          action: \.destination.tracks,
        ),
      ) { store in
        self.placeholderDestination(store)
      }
      .navigationDestination(
        item: self.$store.scope(
          state: \.destination?.track,
          action: \.destination.track,
        ),
      ) { store in
        self.placeholderDestination(store)
      }
      .onAppear {
        self.store.send(.onAppear)
      }
    }
  }

  private func placeholderDestination(
    _ store: StoreOf<PlaceholderScreenFeature>,
  ) -> some View {
    PlaceholderDestinationView(
      title: store.title,
      transitionSourceID: store.transitionSourceID,
      transitionNamespace: self.zoomNamespace,
    )
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
        tracks: library.tracks.map(TrackData.init),
      )
    case .empty:
      .empty
    case .failed:
      .failed
    }
  }
}
