import Dependencies
import Foundation
import LibCore
import LibViews
import SQLiteData
import Tagged

@Table
struct Show: Equatable, Hashable {
  typealias ID = Tagged<Self, Int>
  let id: ID
  var name: String
  var author: String?
  var description: String?
  var feedUrl: String
  var websiteUrl: String?
  var artworkUrl: String?
  var showArtwork: Bool
  var iTunesId: Int?
  var sort: SortOrder
  var updatedAt: Date = .init()
  var createdAt: Date
}

extension Show {
  enum SortOrder: String, QueryBindable {
    case oldestToNewest
    case newestToOldest
  }

  var localFilesDir: URL {
    .localFilesDir(showId: self.id)
  }

  var localArtworkImage: UIImage? {
    showLocalArtworkImage(showId: self.id)
  }

  func removeLocalFilesDir() {
    removeShowLocalFilesDir(id: self.id)
  }
}

func removeShowLocalFilesDir(id: Show.ID) {
  try? dep(\.fileSystem).removeItem(at: .localFilesDir(showId: id))
}

func showLocalArtworkImage(showId: Show.ID) -> UIImage? {
  guard let data = try? Data(contentsOf: .localArtworkPath(showId: showId)) else {
    return nil
  }
  return UIImage(data: data)
}

extension Show.Draft: Equatable {}

extension URL {
  static func localFilesDir(showId: Show.ID) -> URL {
    URL.documentsDirectory
      .appending(component: "shows")
      .appending(component: "show-\(showId)")
  }

  static func localArtworkPath(showId: Show.ID) -> URL {
    self.localFilesDir(showId: showId)
      .appending(component: "artwork-show-\(showId).bin")
  }
}

extension Show {
  struct FeedData: Equatable, Hashable {
    var sourceUrl: String
    var name: String
    var author: String?
    var description: String?
    var websiteUrl: String?
    var artworkUrl: String?
    var iTunesId: Int?

    func toShowDraft(showArtwork: Bool) -> Show.Draft {
      @Dependency(\.date.now) var now
      return .init(
        name: self.name,
        author: self.author,
        description: self.description,
        feedUrl: self.sourceUrl,
        websiteUrl: self.websiteUrl,
        artworkUrl: self.artworkUrl,
        showArtwork: showArtwork,
        iTunesId: self.iTunesId,
        sort: .newestToOldest,
        createdAt: now,
      )
    }
  }

  static var col: TableColumns { Show.columns }
}

extension ShowData {
  init(from show: Show) {
    self.init(
      id: show.id.rawValue,
      name: show.name,
      author: show.author,
      description: show.description,
      showArtwork: show.showArtwork,
      artworkImage: show.showArtwork ? show.localArtworkImage : nil,
      artworkUrl: show.showArtwork ? show.artworkUrl : nil,
    )
  }
}

extension Show {
  static var mock: Self {
    .init(
      id: 1,
      name: "The Ancient Path",
      author: "Jason Henderson",
      description: "Discussions on theology, culture, and family.",
      feedUrl: "",
      artworkUrl: "https://is1-ssl.mzstatic.com/image/thumb/Podcasts116/v4/a2/94/d3/a294d3e7-bf02-377f-a531-7b0491a4cb81/mza_4607163774963783796.png/600x600bb.jpg",
      showArtwork: true,
      sort: .newestToOldest,
      createdAt: Date(),
    )
  }
}
