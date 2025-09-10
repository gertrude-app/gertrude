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
  }
}
