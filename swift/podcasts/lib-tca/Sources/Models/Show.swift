import Dependencies
import Foundation
import SharingGRDB

@Table
struct Show: Equatable {
  let id: Int
  var name: String
  var author: String?
  var description: String?
  var feedUrl: String
  var websiteUrl: String?
  var artworkUrl: String?
  var showArtwork: Bool
  var iTunesId: Int?
  var createdAt: Date
}

extension Show {
  struct FeedData: Equatable {
    var name: String
    var author: String?
    var description: String?
    var websiteUrl: String?
    var artworkUrl: String?
    var iTunesId: Int?

    func toShowDraft(feedUrl: String, showArtwork: Bool) -> Show.Draft {
      @Dependency(\.date.now) var now
      return .init(
        name: self.name,
        author: self.author,
        description: self.description,
        feedUrl: feedUrl,
        websiteUrl: self.websiteUrl,
        artworkUrl: self.artworkUrl,
        showArtwork: showArtwork,
        iTunesId: self.iTunesId,
        createdAt: now
      )
    }
  }
}
