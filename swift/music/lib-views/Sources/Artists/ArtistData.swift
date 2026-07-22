import Foundation

public struct ArtistData: Identifiable, Equatable, Hashable, Sendable {
  public let id: String
  public let name: String
  public let artworkUrl: URL?
  public let artworkPalette: ArtworkPalette?
  public let subtitle: String?
  public let editorialNotes: String?
  public let releaseAlbumIds: [String]
  public let topSongs: [ArtistTopSongData]

  public init(
    id: String,
    name: String,
    artworkUrl: URL? = nil,
    artworkPalette: ArtworkPalette? = nil,
    subtitle: String? = nil,
    editorialNotes: String? = nil,
    releaseAlbumIds: [String] = [],
    topSongs: [ArtistTopSongData] = [],
  ) {
    self.id = id
    self.name = name
    self.artworkUrl = artworkUrl
    self.artworkPalette = artworkPalette
    self.subtitle = subtitle
    self.editorialNotes = editorialNotes
    self.releaseAlbumIds = releaseAlbumIds
    self.topSongs = topSongs
  }
}
