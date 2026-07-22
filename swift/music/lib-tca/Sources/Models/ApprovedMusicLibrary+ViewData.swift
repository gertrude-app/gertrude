import Foundation
import LibViews

extension AlbumData {
  init(album: ApprovedAlbum) {
    self.init(
      id: album.id.rawValue,
      title: album.title,
      artist: album.artistName,
      artworkUrl: album.artwork?.artworkURL ?? album.artworkURL,
      artworkPalette: album.artwork?.palette,
      trackCount: album.trackCount,
      releaseDate: album.releaseDate,
      releaseType: album.releaseType,
    )
  }
}

extension ArtistData {
  init(artist: ApprovedArtist) {
    let metadata = artist.catalogMetadata
    self.init(
      id: artist.id.rawValue,
      name: artist.name,
      artworkUrl: metadata?.artwork?.artistCardURL,
      artworkPalette: metadata?.artwork?.palette,
      subtitle: metadata?.artistSubtitle,
      editorialNotes: metadata?.artistEditorialNotes,
      releaseAlbumIds: artist.releaseAlbumIds?.map(\.rawValue) ?? [],
      topSongs: artist.topSongs?.map(ArtistTopSongData.init) ?? [],
    )
  }
}

extension ArtistTopSongData {
  init(song: ApprovedTrack) {
    self.init(
      id: song.id.rawValue,
      title: song.title,
      artist: song.artistName,
      albumTitle: song.albumTitle,
      artworkUrl: song.artworkURL,
      duration: song.durationInMillis?.musicDuration,
    )
  }
}

extension PlaylistData {
  init(playlist: MusicPlaylist) {
    self.init(
      id: playlist.id.rawValue.uuidString,
      name: playlist.name,
      entries: playlist.entries.map(PlaylistEntryData.init),
    )
  }
}

extension PlaylistEntryData {
  init(entry: MusicPlaylistEntry) {
    self.init(
      id: entry.id.rawValue.uuidString,
      track: TrackData(track: entry.track),
    )
  }
}

extension TrackData {
  init(track: ApprovedTrack) {
    self.init(
      id: track.id.rawValue,
      title: track.title,
      artist: track.artistName,
      artworkUrl: track.artworkURL,
    )
  }
}

private extension ApprovedMusicCatalogMetadata {
  var artistSubtitle: String? {
    self.editorialNotes?.tagline?.nonEmpty ?? self.genreNames.first?.nonEmpty
  }

  var artistEditorialNotes: String? {
    self.editorialNotes?.standard?.nonEmpty ?? self.editorialNotes?.short?.nonEmpty
  }
}

private extension ApprovedMusicArtwork {
  var artistCardURL: URL? {
    self.artworkURL
  }

  var artworkURL: URL? {
    guard var url = self.url else { return nil }
    url = url.replacingOccurrences(of: "{w}", with: "600")
    url = url.replacingOccurrences(of: "{h}", with: "600")
    return URL(string: url)
  }

  var palette: ArtworkPalette? {
    let palette = ArtworkPalette(
      bgColor: self.bgColor,
      textColor1: self.textColor1,
      textColor2: self.textColor2,
      textColor3: self.textColor3,
      textColor4: self.textColor4,
    )
    return palette.isEmpty ? nil : palette
  }
}

private extension ArtworkPalette {
  var isEmpty: Bool {
    [self.bgColor, self.textColor1, self.textColor2, self.textColor3, self.textColor4]
      .allSatisfy { $0?.nonEmpty == nil }
  }
}

private extension Int {
  var musicDuration: String {
    let totalSeconds = self / 1000
    let hours = totalSeconds / 3600
    let minutes = totalSeconds % 3600 / 60
    let seconds = totalSeconds % 60
    if hours > 0 {
      return "\(hours):\(String(format: "%02d", minutes)):\(String(format: "%02d", seconds))"
    }
    return "\(minutes):\(String(format: "%02d", seconds))"
  }
}

private extension String {
  var nonEmpty: String? {
    self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
  }
}
