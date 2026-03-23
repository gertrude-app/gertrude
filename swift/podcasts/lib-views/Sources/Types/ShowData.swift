import Foundation

#if canImport(UIKit)
  import UIKit
#else
  import LibCore
#endif

public struct ShowData: Identifiable {
  public let id: Int
  public var name: String
  public var author: String?
  public var description: String?
  public var showArtwork: Bool
  public var artworkImage: UIImage?
  public var artworkUrl: String?
  public var playbackRate: Double

  public init(
    id: Int,
    name: String,
    author: String? = nil,
    description: String? = nil,
    showArtwork: Bool,
    artworkImage: UIImage? = nil,
    artworkUrl: String? = nil,
    playbackRate: Double = 1.0,
  ) {
    self.id = id
    self.name = name
    self.author = author
    self.description = description
    self.showArtwork = showArtwork
    self.artworkImage = artworkImage
    self.artworkUrl = artworkUrl
    self.playbackRate = playbackRate
  }
}
