import ComposableArchitecture
import Foundation
import LibViews
import SwiftUI

struct LibraryViewContainer: View {
  @Bindable var store: StoreOf<LibraryFeature>
  @Namespace private var zoomNamespace

  let currentTrackID: ApprovedTrack.ID?
  let isPlaybackLoading: Bool
  let isPlaybackPlaying: Bool

  var body: some View {
    NavigationStack(
      path: self.$store.scope(state: \.path, action: \.path),
    ) {
      LibraryView(
        state: self.store.viewState,
        isRefreshing: self.store.isRefreshingRemoteLibrary,
        isPlaylistMutationInFlight: self.store.isPlaylistMutationInFlight,
        transitionNamespace: self.zoomNamespace,
        onRetryTap: { self.store.send(.retryButtonTapped) },
        onRefresh: {
          self.store.send(.refreshPulled)
        },
        onAlbumAddToPlaylist: { self.store.send(.addAlbumToPlaylistTapped(.init($0))) },
        onAlbumAddToQueue: { self.store.send(.albumAddToQueueTapped(.init($0))) },
        onAlbumPlayNext: { self.store.send(.albumPlayNextTapped(.init($0))) },
        onAlbumTap: { self.store.send(.albumTapped(.init($0))) },
        onArtistTap: { self.store.send(.artistTapped(.init($0))) },
        onCreatePlaylist: { self.store.send(.createPlaylistSubmitted($0)) },
        onPlaylistAddToQueue: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.playlistAddToQueueTapped(.init(rawValue: id)))
        },
        onPlaylistPlayNext: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.playlistPlayNextTapped(.init(rawValue: id)))
        },
        onPlaylistTap: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.playlistTapped(.init(rawValue: id)))
        },
        onDebugResetTap: { self.store.send(.debugResetOnboardingButtonTapped) },
      )
      .onAppear {
        self.store.send(.onAppear)
      }
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
        if case .loaded(let library) = self.store.status {
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
          isPlaylistMutationInFlight: self.store.isPlaylistMutationInFlight,
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
}

private extension LibraryFeature.State {
  var viewState: LibraryViewState {
    switch self.status {
    case .loading:
      .loading
    case .loaded(let library):
      .loaded(items: library.collectionItems(recency: self.collectionRecency))
    case .empty:
      .empty
    case .failed:
      .failed
    case .subscriptionRequired:
      .subscriptionRequired
    }
  }
}

extension ApprovedMusicLibrary {
  func collectionItems(
    recency: LibraryCollectionRecency,
  ) -> [LibraryCollectionItemData] {
    let albums = self.albums.map {
      DatedLibraryItem(
        addedAt: $0.addedAt,
        identity: .album($0.id),
        item: .album(AlbumData(album: $0)),
      )
    }
    let artists = self.artists.map {
      DatedLibraryItem(
        addedAt: $0.addedAt,
        identity: .artist($0.id),
        item: .artist(ArtistData(artist: $0)),
      )
    }
    let playlists = self.playlists.map {
      DatedLibraryItem(
        addedAt: $0.createdAt,
        identity: .playlist($0.id),
        item: .playlist(PlaylistData(playlist: $0)),
      )
    }
    return (albums + artists + playlists)
      .map { datedItem in
        var datedItem = datedItem
        datedItem.lastPlayedAt = recency.lastPlayedAt(
          for: datedItem.identity,
          observedAddedAt: datedItem.addedAt,
        )
        return datedItem
      }
      .sorted {
        switch ($0.lastPlayedAt, $1.lastPlayedAt) {
        case (.some(let lhs), .some(let rhs)) where lhs != rhs:
          return lhs > rhs
        case (.some, .none):
          return true
        case (.none, .some):
          return false
        default:
          if $0.addedAt != $1.addedAt {
            return $0.addedAt > $1.addedAt
          }
          return $0.item.id < $1.item.id
        }
      }
      .map(\.item)
  }
}

private struct DatedLibraryItem {
  let addedAt: Date
  let identity: LibraryCollectionIdentity
  let item: LibraryCollectionItemData
  var lastPlayedAt: Date?
}
