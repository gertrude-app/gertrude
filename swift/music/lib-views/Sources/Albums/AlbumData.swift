import Foundation

public struct AlbumData: Identifiable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let artworkUrl: URL?
  public let showsArtwork: Bool

  public init(
    id: String,
    title: String,
    artist: String,
    artworkUrl: URL? = nil,
    showsArtwork: Bool = true,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artworkUrl = artworkUrl
    self.showsArtwork = showsArtwork
  }
}
