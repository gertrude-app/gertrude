import Foundation

public struct SearchResult: Identifiable, Sendable, Equatable {
  public let id: Int
  public let title: String
  public let artistName: String
  public let artworkUrl: String?
  public let feedUrl: String
  public let episodeCount: Int
  public let isExplicit: Bool

  public init(
    id: Int,
    title: String,
    artistName: String,
    artworkURL: String? = nil,
    feedUrl: String,
    episodeCount: Int,
    isExplicit: Bool = false
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkUrl = artworkURL
    self.feedUrl = feedUrl
    self.episodeCount = episodeCount
    self.isExplicit = isExplicit
  }
}
