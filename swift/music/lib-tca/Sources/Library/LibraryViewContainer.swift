import ComposableArchitecture
import LibViews
import SwiftUI

struct LibraryViewContainer: View {
  @Bindable var store: StoreOf<LibraryFeature>
  @Namespace private var zoomNamespace

  let currentTrackID: ApprovedTrack.ID?
  let playbackQueueTrackIDs: [ApprovedTrack.ID]
  let isPlaybackLoading: Bool
  let isPlaybackPlaying: Bool

  var body: some View {
    let albumDetailStore = self.albumDetailStore

    NavigationStack {
      LibraryView(
        state: self.store.viewState,
        isRefreshing: self.store.isRefreshingRemoteLibrary,
        transitionNamespace: self.zoomNamespace,
        currentTrackID: self.currentTrackID?.rawValue,
        playbackQueueTrackIDs: self.playbackQueueTrackIDs.map(\.rawValue),
        isPlaybackLoading: self.isPlaybackLoading,
        isPlaybackPlaying: self.isPlaybackPlaying,
        onRetryTap: { self.store.send(.retryButtonTapped) },
        onRefresh: {
          self.store.send(.refreshPulled)
        },
        onAlbumTap: { self.store.send(.albumTapped(.init($0))) },
        onArtistPlayTap: { self.store.send(.artistPlayTapped(.init($0))) },
        onArtistSongTap: { artistID, trackID in
          self.store.send(.artistTopSongTapped(
            artistID: .init(artistID),
            trackID: .init(trackID),
          ))
        },
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
