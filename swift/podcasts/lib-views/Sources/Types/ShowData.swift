import Foundation

#if canImport(UIKit)
  import UIKit
#else
  import LibCore
#endif

public struct ShowData: Identifiable {
  public let id: Int
  public let title: String
  public let author: String?
  public let description: String?
  public let showArtwork: Bool
  public let artworkImage: UIImage?
  public let artworkUrl: String?

  public init(
    id: Int,
    title: String,
    author: String? = nil,
    description: String? = nil,
    showArtwork: Bool,
    artworkImage: UIImage? = nil,
    artworkUrl: String? = nil
  ) {
    self.id = id
    self.title = title
    self.author = author
    self.description = description
    self.showArtwork = showArtwork
    self.artworkImage = artworkImage
    self.artworkUrl = artworkUrl
  }
}
