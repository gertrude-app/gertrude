import Foundation

public struct AlbumData: Identifiable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let artworkUrl: URL?
  public let artworkPalette: ArtworkPalette?
  public let trackCount: Int?
  public let releaseDate: String?
  public let releaseType: String?

  public init(
    id: String,
    title: String,
    artist: String,
    artworkUrl: URL? = nil,
    artworkPalette: ArtworkPalette? = nil,
    trackCount: Int? = nil,
    releaseDate: String? = nil,
    releaseType: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artworkUrl = artworkUrl
    self.artworkPalette = artworkPalette
    self.trackCount = trackCount
    self.releaseDate = releaseDate
    self.releaseType = releaseType
  }
}
