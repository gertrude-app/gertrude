import Foundation

public struct TrackData: Identifiable, Equatable, Sendable {
  public let id: String
  public let title: String
  public let artist: String
  public let artworkUrl: URL?

  public init(
    id: String,
    title: String,
    artist: String,
    artworkUrl: URL? = nil,
  ) {
    self.id = id
    self.title = title
    self.artist = artist
    self.artworkUrl = artworkUrl
  }
}
