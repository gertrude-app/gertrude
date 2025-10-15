import CustomDump
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@testable import LibTCA

@Test func simpleFeedUpdate() {
  let updates = _feedUpdates(input: .init(
    feeds: [
      Feed(show: .mock(1), episodes: []),
      Feed(show: .mock(2) { $0.name = "After" }, episodes: []),
    ],
    shows: [.mock(2) { $0.name = "Before" }, .mock(1)],
  ))
  expectNoDifference(updates, .init(showUpdates: [.mock(2) { $0.name = "After" }]))
}

@Test func artworkUrlChanged() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(show: .mock(1) { $0.artworkUrl = "https://a.com/new.jpg" }, episodes: [])],
    shows: [.mock(1) { $0.artworkUrl = "https://a.com/old.jpg" }],
  ))

  expectNoDifference(updates, .init(
    showUpdates: [Show.mock(1) { $0.artworkUrl = "https://a.com/new.jpg" }],
    actions: [.replaceShowArtwork(showId: Show.ID(1), artworkUrl: "https://a.com/new.jpg")]
  ))
}

@Test func newEpisodeAdded() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(show: .mock(1), episodes: [.mock(1, showId: 1), .mock(2, showId: 1)])],
    shows: [.mock(1)],
    episodes: [.mock(1, showId: 1)],
    now: .reference
  ))

  expectNoDifference(updates, .init(
    addEpisodes: [.mock(2, showId: 1)]
  ))
}

@Test func episodeDeleted() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(show: .mock(1), episodes: [.mock(1, showId: 1)])],
    shows: [.mock(1)],
    episodes: [.mock(1, showId: 1), .mock(2, showId: 1)],
  ))

  expectNoDifference(updates, .init(deleteEpisodes: [.init(2)]))
}

@Test func episodeTitleChanged() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(
      show: .mock(1),
      episodes: [.mock(1, showId: 1) { $0.title = "Updated Title" }]
    )],
    shows: [.mock(1)],
    episodes: [.mock(1, showId: 1) { $0.title = "Original Title" }],
    now: .reference
  ))

  expectNoDifference(updates, .init(
    episodeUpdates: [.mock(1, showId: 1) { $0.title = "Updated Title"
      $0.updatedAt = .reference
    }]
  ))
}

@Test func episodeAudioPropertiesChanged() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(
      show: .mock(1),
      episodes: [
        .mock(1, showId: 1) { $0.audioUrl = "https://new.com/episode1.mp3" },
        .mock(2, showId: 1) { $0.duration = 7200 },
        .mock(3, showId: 1) { $0.sizeInBytes = 100_000_000 },
        .mock(4, showId: 1) { $0.audioType = .m4a },
        .mock(5, showId: 1) { $0.title = "Only title changed" },
      ]
    )],
    shows: [.mock(1)],
    episodes: [
      .mock(1, showId: 1),
      .mock(2, showId: 1),
      .mock(3, showId: 1),
      .mock(4, showId: 1),
      .mock(5, showId: 1),
    ],
    now: .reference,
  ))

  #expect(updates.episodeUpdates.count == 5)
  #expect(updates.actions.count == 4)

  #expect(Set(updates.actions) == Set([
    .invalidateEpisodeAudio(1),
    .invalidateEpisodeAudio(2),
    .invalidateEpisodeAudio(3),
    .invalidateEpisodeAudio(4),
  ]))
}

@Test func integration() async throws {
  let fetchedFeed1 = Feed(
    show: .mock(1) { $0.name = "Feed One (new name)" }, // updated
    episodes: [
      .mock(1, showId: 1),
      .mock(2, showId: 1) { $0.title = "Episode Two Updated" },
    ]
  )
  let fetchedFeed2 = Feed(
    show: .mock(2) { $0.artworkUrl = "https://new.com/artwork2.jpg" },
    episodes: [
      .mock(3, showId: 2),
      .mock(4, showId: 2), // new episode
    ]
  )
  try await withDependencies {
    $0.defaultDatabase = try! appDatabase()
    $0.date = .constant(.reference)
    $0.podcasts.getFeed = { url in
      switch url {
      case "https://mock1.com/feed.rss":
        return fetchedFeed1
      case "https://mock2.com/feed.rss":
        return fetchedFeed2
      default:
        throw NSError(domain: "network error", code: 1)
      }
    }
  } operation: {
    @Dependency(\.db) var database
    try await database.write { db in
      try Show
        .insert { [
          Show.mock(1) { $0.name = "Feed One (old name)" },
          Show.mock(2),
          Show.mock(3), // will fail to fetch feed
        ] }
        .execute(db)

      try Episode
        .insert { [
          Episode.mock(1, showId: 1),
          Episode.mock(2, showId: 1),
          Episode.mock(3, showId: 2),
        ] }
        .execute(db)
    }

    let inputData = await _prepareFeedUpdateInputData()
    expectNoDifference(Set(inputData.feeds), Set([fetchedFeed1, fetchedFeed2]))
    expectNoDifference(Set(inputData.shows), Set([
      Show.mock(1) { $0.name = "Feed One (old name)" },
      Show.mock(2),
    ]))
    expectNoDifference(Set(inputData.episodes), Set([
      Episode.mock(1, showId: 1),
      Episode.mock(2, showId: 1),
      Episode.mock(3, showId: 2),
    ]))
    expectNoDifference(inputData.nowPlaying, nil)
    expectNoDifference(inputData.now, .reference)

    let updates = _feedUpdates(input: inputData)
    expectNoDifference(Set(updates.showUpdates), Set([
      Show.mock(1) { $0.name = "Feed One (new name)" },
      Show.mock(2) { $0.artworkUrl = "https://new.com/artwork2.jpg" },
    ]))
    expectNoDifference(updates.episodeUpdates, [
      Episode.mock(2, showId: 1) { $0.title = "Episode Two Updated" },
    ])
    expectNoDifference(updates.addEpisodes, [
      Episode.Draft.mock(4, showId: 2),
    ])
    expectNoDifference(updates.deleteEpisodes, [])
    expectNoDifference(Set(updates.actions), Set([
      .replaceShowArtwork(showId: 2, artworkUrl: "https://new.com/artwork2.jpg"),
    ]))
  }
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
      sort: .newestToOldest,
      updatedAt: .reference,
      createdAt: .reference,
    )
    update(&mock)
    return mock
  }
}

extension Episode {
  static let mock: Self = .mock(1, showId: 1)

  static func mock(_ id: Int, showId: Int, _ update: (inout Self) -> Void = { _ in }) -> Self {
    var mock = Self(
      id: .init(id),
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
      isArchived: false,
      pubDate: .reference,
      progress: 0,
      updatedAt: .reference,
      createdAt: .reference,
    )
    update(&mock)
    return mock
  }
}

extension Episode.FeedData {
  static let mock: Self = .mock(1, showId: 1)

  static func mock(_ id: Int, showId: Int, _ update: (inout Self) -> Void = { _ in }) -> Self {
    var mock = Self(
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
      episodeNumber: id
    )
    update(&mock)
    return mock
  }
}

extension Episode.Draft {
  static let mock: Self = .mock(1, showId: 1)

  static func mock(_ id: Int, showId: Int, _ update: (inout Self) -> Void = { _ in }) -> Self {
    let episode = Episode.mock(id, showId: showId)
    var mock = Episode.Draft(
      showId: episode.showId,
      episodeNumber: episode.episodeNumber,
      title: episode.title,
      description: episode.description,
      websiteUrl: episode.websiteUrl,
      audioUrl: episode.audioUrl,
      artworkUrl: episode.artworkUrl,
      duration: episode.duration,
      sizeInBytes: episode.sizeInBytes,
      audioType: episode.audioType,
      guid: episode.guid,
      isArchived: episode.isArchived,
      pubDate: episode.pubDate,
      progress: episode.progress,
      downloadedAt: episode.downloadedAt,
      lastPlayedAt: episode.lastPlayedAt,
      completedAt: episode.completedAt,
      updatedAt: .reference,
      createdAt: .reference
    )
    update(&mock)
    return mock
  }
}

public extension Date {
  static let epoch = Date(timeIntervalSince1970: 0)
  static let reference = Date(timeIntervalSinceReferenceDate: 0)
}
