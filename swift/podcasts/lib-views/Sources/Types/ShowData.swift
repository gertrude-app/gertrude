import Foundation

public struct ShowData: Identifiable, Sendable, Equatable {
  public let id: Int
  public let title: String
  public let author: String?
  public let description: String?
  public let artworkUrl: String?

  public init(
    id: Int,
    title: String,
    author: String? = nil,
    description: String? = nil,
    artworkUrl: String? = nil
  ) {
    self.id = id
    self.title = title
    self.author = author
    self.description = description
    self.artworkUrl = artworkUrl
  }
}
