import Foundation

public struct ArtistData: Identifiable, Equatable, Sendable {
  public let id: String
  public let name: String
  public let artworkUrl: URL?
  public let showsArtwork: Bool

  public init(
    id: String,
    name: String,
    artworkUrl: URL? = nil,
    showsArtwork: Bool = true,
  ) {
    self.id = id
    self.name = name
    self.artworkUrl = artworkUrl
    self.showsArtwork = showsArtwork
  }
}
