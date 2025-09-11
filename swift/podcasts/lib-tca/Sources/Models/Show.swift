import Dependencies
import Foundation
import LibViews
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
  var localAudioDir: URL {
    .localShowAudiosDir(showId: self.id)
  }
}

extension URL {
  static func localShowAudiosDir(showId: Int) -> URL {
    URL.documentsDirectory
      .appending(component: "audio")
      .appending(component: "show-\(showId)")
  }
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

extension ShowData {
  init(from show: Show) {
    self.init(
      id: show.id,
      title: show.name,
      author: show.author,
      description: show.description,
      artworkUrl: show.showArtwork ? show.artworkUrl : nil
    )
  }
}
