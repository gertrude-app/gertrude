import CustomDump
import Foundation
import Testing

@testable import LibTCA

@Test func simpleFeedUpdate() {
  let updates = feedUpdates(
    feeds: [
      Feed(show: .mock(1), episodes: []),
      Feed(show: .mock(2) { $0.name = "After" }, episodes: []),
    ],
    shows: [.mock(2) { $0.name = "Before" }, .mock(1)],
  )
  expectNoDifference(updates, .init(showUpdates: [.mock(2) { $0.name = "After" }]))
}

@Test func artworkUrlChanged() {
  let updates = feedUpdates(
    feeds: [Feed(show: .mock(1) { $0.artworkUrl = "https://a.com/new.jpg" }, episodes: [])],
    shows: [.mock(1) { $0.artworkUrl = "https://a.com/old.jpg" }],
  )

  expectNoDifference(updates, .init(
    showUpdates: [Show.mock(1) { $0.artworkUrl = "https://a.com/new.jpg" }],
    actions: [.replaceShowArtwork(showId: Show.ID(1), artworkUrl: "https://a.com/new.jpg")]
  ))
}

@Test func newEpisodeAdded() {
  let updates = feedUpdates(
    feeds: [Feed(show: .mock(1), episodes: [.mock(1)])],
    shows: [.mock(1)],
    episodes: []
  )

  expectNoDifference(updates, .init(
    addEpisodes: [.mock(1, showId: 1)]
  ))
}

// mocks

extension Show.FeedData {
  static let empty = Self(sourceUrl: "", name: "", author: "")
  static let mock: Self = mock(1)
  static func mock(_ id: Int, _ update: (inout Self) -> Void = { _ in }) -> Self {
    var mock = Self(
      sourceUrl: "https://mock\(id).com/feed.rss",
      name: "Mock Show \(id)",
      author: "Mock Author \(id)",
      description: "Mock Description \(id)",
      websiteUrl: "https://mock\(id).com",
      artworkUrl: "https://mock\(id).com/artwork.jpg",
      iTunesId: 123_456_789
    )
    update(&mock)
    return mock
  }
}

extension Show {
  static let mock: Self = .mock(1)

  static func mock(_ id: Int, update: (inout Self) -> Void = { _ in }) -> Self {
    var mock = Self(
      id: .init(id),
      name: "Mock Show \(id)",
      author: "Mock Author \(id)",
      description: "Mock Description \(id)",
      feedUrl: "https://mock\(id).com/feed.rss",
      websiteUrl: "https://mock\(id).com",
      artworkUrl: "https://mock\(id).com/artwork.jpg",
      showArtwork: true,
      iTunesId: 123_456_789,
      updatedAt: .reference,
      createdAt: .reference,
    )
    update(&mock)
    return mock
  }
}

extension Episode.FeedData {
  static let mock: Self = .mock(1)

  static func mock(_ id: Int, _ update: (inout Self) -> Void = { _ in }) -> Self {
    var mock = Self(
      title: "Mock Episode \(id)",
      description: "Mock Description \(id)",
      websiteUrl: "https://mock\(id).com",
      audioUrl: "https://mock\(id).com/episode.mp3",
      artworkUrl: "https://mock\(id).com/artwork.jpg",
      duration: 3600,
      sizeInBytes: 50_000_000,
      audioType: .mp3,
      guid: "mock-episode-\(id)",
      pubDate: .reference,
      episodeNumber: id
    )
    update(&mock)
    return mock
  }
}

extension Episode.Draft {
  static let mock: Self = .mock(1, showId: 1)

  static func mock(_ id: Int, showId: Int, _ update: (inout Self) -> Void = { _ in }) -> Self {
    var mock = Self(
      showId: .init(showId),
      episodeNumber: id,
      title: "Mock Episode \(id)",
      description: "Mock Description \(id)",
      websiteUrl: "https://mock\(showId).com/episode\(id)",
      audioUrl: "https://mock\(showId).com/episode\(id).mp3",
      artworkUrl: "https://mock\(showId).com/artwork\(id).jpg",
      duration: 3600,
      sizeInBytes: 50_000_000,
      audioType: .mp3,
      guid: "e\(id)-s\(showId)",
      pubDate: .reference,
      updatedAt: .reference,
      createdAt: .reference,
    )
    update(&mock)
    return mock
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
