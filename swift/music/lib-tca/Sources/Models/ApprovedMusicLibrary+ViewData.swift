import Foundation
import LibViews

extension AlbumData {
  init(album: ApprovedAlbum) {
    self.init(
      id: album.id.rawValue,
      title: album.title,
      artist: album.artistName,
      artworkUrl: album.artworkURL,
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
      subtitle: metadata?.artistSubtitle,
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
}

private extension ApprovedMusicArtwork {
  var artistCardURL: URL? {
    guard var url = self.url else { return nil }
    url = url.replacingOccurrences(of: "{w}", with: "600")
    url = url.replacingOccurrences(of: "{h}", with: "600")
    return URL(string: url)
  }
}

private extension String {
  var nonEmpty: String? {
    self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self
  }
}
