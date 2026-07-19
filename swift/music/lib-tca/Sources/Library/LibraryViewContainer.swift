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
        playlistMutationErrorMessage: self.store.addToPlaylist == nil
          ? self.store.playlistMutationFailure?.message
          : nil,
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
        onPlaylistMutationErrorDismissed: {
          self.store.send(.playlistMutationFailureDismissed)
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
        self.artistDetail(store: artistStore)

      case .playlist(let playlistStore):
        self.playlistDetail(store: playlistStore)
          .navigationZoomTransitionIfAvailable(
            sourceID: playlistArtworkZoomTransitionID(
              for: playlistStore.playlist.id.rawValue.uuidString,
            ),
            in: self.zoomNamespace,
          )
      }
    }
    .sheet(isPresented: self.addToPlaylistBinding) {
      AddToPlaylistSheet(
        playlists: self.addToPlaylistPlaylists,
        duplicatePrompt: self.addToPlaylistDuplicatePrompt,
        errorMessage: self.store.playlistMutationFailure?.message,
        isMutating: self.store.isPlaylistMutationInFlight,
        onCancel: { self.store.send(.addToPlaylistCancelled) },
        onCreatePlaylist: { self.store.send(.addToPlaylistCreateSubmitted($0)) },
        onDuplicateCancel: { self.store.send(.addToPlaylistDuplicateCancelled) },
        onDuplicateChoice: { choice in
          switch choice {
          case .addAgain:
            self.store.send(.addToPlaylistDuplicateResolutionSelected(.addAgain))
          case .addAll:
            self.store.send(.addToPlaylistDuplicateResolutionSelected(.addAll))
          case .addOnlyNew:
            self.store.send(.addToPlaylistDuplicateResolutionSelected(.addOnlyNew))
          }
        },
        onSelectPlaylist: {
          guard let id = UUID(uuidString: $0) else { return }
          self.store.send(.addToPlaylistDestinationSelected(.init(rawValue: id)))
        },
      )
    }
  }

  private var addToPlaylistBinding: Binding<Bool> {
    Binding(
      get: { self.store.addToPlaylist != nil },
      set: { isPresented in
        if !isPresented {
          self.store.send(.addToPlaylistCancelled)
        }
      },
    )
  }

  private var addToPlaylistPlaylists: [PlaylistData] {
    guard case .loaded(let library) = self.store.status else { return [] }
    return library.playlists.map(PlaylistData.init)
  }

  private var addToPlaylistDuplicatePrompt: PlaylistDuplicatePrompt? {
    guard case .loaded(let library) = self.store.status,
          let confirmation = self.store.addToPlaylist?.confirmation else { return nil }
    switch confirmation {
    case .track(let playlistID, let duplicate):
      guard let playlist = library.playlist(id: .init(rawValue: playlistID)) else { return nil }
      return .track(trackTitle: duplicate.title, playlistName: playlist.name)
    case .album(let playlistID, _, let duplicates):
      guard let playlist = library.playlist(id: .init(rawValue: playlistID)) else { return nil }
      return .album(playlistName: playlist.name, duplicateCount: duplicates.count)
    }
  }

  private func playlistDetail(
    store: StoreOf<PlaylistDetailFeature>,
  ) -> some View {
    ZStack(alignment: .top) {
      PlaylistDetailView(
        playlist: PlaylistData(playlist: store.playlist),
        isPlaying: store.isPlaying,
        isLoading: store.isLoading,
        currentEntryID: store.currentEntryID?.rawValue.uuidString,
        isMutating: self.store.isPlaylistMutationInFlight,
        onAddMusicTap: { store.send(.addMusicTapped) },
        onAddToQueue: { store.send(.addToQueueTapped) },
        onDelete: { store.send(.deleteTapped) },
        onPlayNext: { store.send(.playNextTapped) },
        onPlayTap: { store.send(.playTapped) },
        onRemoveEntry: {
          guard let id = UUID(uuidString: $0) else { return }
          store.send(.removeEntryTapped(.init(rawValue: id)))
        },
        onRename: { store.send(.renameSubmitted($0)) },
        onReorder: { rawIDs in
          let ids = rawIDs.compactMap(UUID.init(uuidString:))
            .map(MusicPlaylistEntry.ID.init(rawValue:))
          guard ids.count == rawIDs.count else { return }
          store.send(.reorderSubmitted(ids))
        },
        onTrackAddToPlaylist: {
          guard let id = UUID(uuidString: $0) else { return }
          store.send(.trackAddToPlaylistTapped(.init(rawValue: id)))
        },
        onTrackAddToQueue: {
          guard let id = UUID(uuidString: $0) else { return }
          store.send(.trackAddToQueueTapped(.init(rawValue: id)))
        },
        onTrackPlayNext: {
          guard let id = UUID(uuidString: $0) else { return }
          store.send(.trackPlayNextTapped(.init(rawValue: id)))
        },
        onTrackTap: {
          guard let id = UUID(uuidString: $0) else { return }
          store.send(.trackTapped(.init(rawValue: id)))
        },
      )

      if let failure = store.playbackFailure {
        PlaybackErrorBanner(
          title: failure.title,
          message: failure.message,
          systemImage: failure.systemImage,
          actionTitle: failure.actionTitle,
          onActionTap: { store.send(.playbackFailureActionTapped) },
          onDismissTap: { store.send(.playbackFailureDismissed) },
        )
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .transition(.move(edge: .top).combined(with: .opacity))
      }
    }
    .animation(.snappy(duration: 0.22), value: store.playbackFailure)
  }

  @ViewBuilder
  private func artistDetail(store: StoreOf<ArtistDetailFeature>) -> some View {
    if case .loaded(let library) = self.store.status,
       let artist = library.artist(id: store.artistID) {
      let artistData = ArtistData(artist: artist)
      let isCurrentArtist = self.currentTrackID.map { currentTrackID in
        artistData.topSongs.contains(where: { $0.id == currentTrackID.rawValue })
      } ?? false

      ArtistDetailView(
        artist: ArtistDetailData(artist: artistData),
        topSongs: artistData.topSongs,
        releases: self.releases(for: artist, in: library),
        transitionNamespace: self.zoomNamespace,
        currentTrackID: isCurrentArtist ? self.currentTrackID?.rawValue : nil,
        isPlaying: isCurrentArtist && self.isPlaybackPlaying,
        isLoading: isCurrentArtist && self.isPlaybackLoading,
        onAddToQueue: { store.send(.addToQueueTapped) },
        onPlayNext: { store.send(.playNextTapped) },
        onPlayTap: { store.send(.playButtonTapped) },
        onSongAddToPlaylist: { store.send(.topSongAddToPlaylistTapped(.init($0))) },
        onSongAddToQueue: { store.send(.topSongAddToQueueTapped(.init($0))) },
        onSongPlayNext: { store.send(.topSongPlayNextTapped(.init($0))) },
        onSongTap: { store.send(.topSongTapped(.init($0))) },
        onReleaseAddToPlaylist: { store.send(.releaseAddToPlaylistTapped(.init($0))) },
        onReleaseAddToQueue: { store.send(.releaseAddToQueueTapped(.init($0))) },
        onReleasePlayNext: { store.send(.releasePlayNextTapped(.init($0))) },
        onReleaseTap: { store.send(.releaseTapped(.init($0))) },
      )
      .navigationZoomTransitionIfAvailable(
        sourceID: artistArtworkZoomTransitionID(for: artistData.id),
        in: self.zoomNamespace,
      )
    }
  }

  private func releases(
    for artist: ApprovedArtist,
    in library: ApprovedMusicLibrary,
  ) -> [ArtistReleaseData] {
    let releaseAlbumIDs = Set(artist.releaseAlbumIds ?? [])
    return library.albums.compactMap { album in
      let belongsToArtist = releaseAlbumIDs.isEmpty
        ? album.artistName.localizedCaseInsensitiveContains(artist.name)
        : releaseAlbumIDs.contains(album.id)
      guard belongsToArtist else { return nil }
      let albumData = AlbumData(album: album)
      return ArtistReleaseData(
        id: albumData.id,
        title: albumData.title,
        artist: albumData.artist,
        artworkUrl: albumData.artworkUrl,
        artworkPalette: albumData.artworkPalette,
        releaseDate: albumData.releaseDate,
        trackCount: albumData.trackCount,
        releaseType: albumData.releaseType,
      )
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

private extension LibraryFeature.PlaylistMutationFailure {
  var message: String {
    switch self {
    case .conflict:
      "This playlist changed on another device. The latest version is now shown."
    case .failed:
      "Your change wasn’t saved. Please try again."
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
