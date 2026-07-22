import ComposableArchitecture
import LibViews
import SwiftUI

struct SearchViewContainer: View {
  @Bindable var store: StoreOf<SearchFeature>
  @Namespace private var zoomNamespace

  let library: ApprovedMusicLibrary?
  let currentTrackID: ApprovedTrack.ID?
  let isPlaybackLoading: Bool
  let isPlaybackPlaying: Bool
  let isPlaylistMutationInFlight: Bool

  var body: some View {
    NavigationStack(
      path: self.$store.scope(state: \.path, action: \.path),
    ) {
      MusicSearchView(
        state: self.store.viewState,
        query: self.$store.query.sending(\.queryChanged),
        currentTrackID: self.currentTrackID?.rawValue,
        isPlaybackPlaying: self.isPlaybackPlaying,
        transitionNamespace: self.zoomNamespace,
        onAddToPlaylist: { self.sendResultAction(
          $0,
          action: SearchFeature.Action.resultAddToPlaylistTapped,
        ) },
        onAddToQueue: { self.sendResultAction(
          $0,
          action: SearchFeature.Action.resultAddToQueueTapped,
        ) },
        onPlayNext: { self.sendResultAction(
          $0,
          action: SearchFeature.Action.resultPlayNextTapped,
        ) },
        onResultTap: { self.sendResultAction(
          $0,
          action: SearchFeature.Action.resultTapped,
        ) },
        onRetryTap: { self.store.send(.retryButtonTapped) },
      )
    } destination: { pathStore in
      switch pathStore.case {
      case .album(let albumStore):
        AlbumDetailViewContainer(store: albumStore)
          .navigationZoomTransitionIfAvailable(
            sourceID: albumStore.transitionSourceID.map {
              albumArtworkZoomTransitionID(for: $0)
            },
            in: self.zoomNamespace,
          )

      case .artist(let artistStore):
        if let library = self.library {
          ArtistDetailViewContainer(
            store: artistStore,
            library: library,
            currentTrackID: self.currentTrackID,
            isPlaybackLoading: self.isPlaybackLoading,
            isPlaybackPlaying: self.isPlaybackPlaying,
            transitionNamespace: self.zoomNamespace,
          )
        }

      case .playlist(let playlistStore):
        PlaylistDetailViewContainer(
          store: playlistStore,
          isPlaylistMutationInFlight: self.isPlaylistMutationInFlight,
        )
        .navigationZoomTransitionIfAvailable(
          sourceID: playlistArtworkZoomTransitionID(
            for: playlistStore.playlist.id.rawValue.uuidString,
          ),
          in: self.zoomNamespace,
        )
      }
    }
  }

  private func sendResultAction(
    _ rawID: String,
    action: (MusicSearchResult.ID) -> SearchFeature.Action,
  ) {
    guard let id = MusicSearchResult.ID(rawValue: rawID) else { return }
    self.store.send(action(id))
  }
}

private extension SearchFeature.State {
  var viewState: MusicSearchViewState {
    switch self.availability {
    case .emptyLibrary:
      .emptyLibrary
    case .failed:
      .failed
    case .loading:
      .loading
    case .ready:
      .ready(self.results.map(\.viewData))
    case .subscriptionRequired:
      .subscriptionRequired
    }
  }
}
