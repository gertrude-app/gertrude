import ComposableArchitecture
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
        transitionNamespace: self.zoomNamespace,
        onRetryTap: { self.store.send(.retryButtonTapped) },
        onRefresh: {
          self.store.send(.refreshPulled)
        },
        onAlbumAddToQueue: { self.store.send(.albumAddToQueueTapped(.init($0))) },
        onAlbumPlayNext: { self.store.send(.albumPlayNextTapped(.init($0))) },
        onAlbumTap: { self.store.send(.albumTapped(.init($0))) },
        onArtistTap: { self.store.send(.artistTapped(.init($0))) },
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
      }
    }
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
        onSongAddToQueue: { store.send(.topSongAddToQueueTapped(.init($0))) },
        onSongPlayNext: { store.send(.topSongPlayNextTapped(.init($0))) },
        onSongTap: { store.send(.topSongTapped(.init($0))) },
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
