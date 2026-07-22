import ComposableArchitecture
import LibViews
import SwiftUI

struct ArtistDetailViewContainer: View {
  let store: StoreOf<ArtistDetailFeature>
  let library: ApprovedMusicLibrary
  let currentTrackID: ApprovedTrack.ID?
  let isPlaybackLoading: Bool
  let isPlaybackPlaying: Bool
  let transitionNamespace: Namespace.ID?

  var body: some View {
    if let artist = self.library.artist(id: self.store.artistID) {
      let artistData = ArtistData(artist: artist)
      let isCurrentArtist = self.currentTrackID.map { currentTrackID in
        artistData.topSongs.contains(where: { $0.id == currentTrackID.rawValue })
      } ?? false

      ArtistDetailView(
        artist: ArtistDetailData(artist: artistData),
        topSongs: artistData.topSongs,
        releases: self.releases(for: artist),
        transitionNamespace: self.transitionNamespace,
        currentTrackID: isCurrentArtist ? self.currentTrackID?.rawValue : nil,
        isPlaying: isCurrentArtist && self.isPlaybackPlaying,
        isLoading: isCurrentArtist && self.isPlaybackLoading,
        onAddToQueue: { self.store.send(.addToQueueTapped) },
        onPlayNext: { self.store.send(.playNextTapped) },
        onPlayTap: { self.store.send(.playButtonTapped) },
        onSongAddToPlaylist: { self.store.send(.topSongAddToPlaylistTapped(.init($0))) },
        onSongAddToQueue: { self.store.send(.topSongAddToQueueTapped(.init($0))) },
        onSongPlayNext: { self.store.send(.topSongPlayNextTapped(.init($0))) },
        onSongTap: { self.store.send(.topSongTapped(.init($0))) },
        onReleaseAddToPlaylist: { self.store.send(.releaseAddToPlaylistTapped(.init($0))) },
        onReleaseAddToQueue: { self.store.send(.releaseAddToQueueTapped(.init($0))) },
        onReleasePlayNext: { self.store.send(.releasePlayNextTapped(.init($0))) },
        onReleaseTap: { self.store.send(.releaseTapped(.init($0))) },
      )
      .navigationZoomTransitionIfAvailable(
        sourceID: artistArtworkZoomTransitionID(for: artistData.id),
        in: self.transitionNamespace,
      )
    }
  }

  private func releases(for artist: ApprovedArtist) -> [ArtistReleaseData] {
    let releaseAlbumIDs = Set(artist.releaseAlbumIds ?? [])
    return self.library.albums.compactMap { album in
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
