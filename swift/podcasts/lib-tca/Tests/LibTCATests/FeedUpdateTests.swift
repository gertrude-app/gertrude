import ComposableArchitecture
import CustomDump
import Dependencies
import DependenciesTestSupport
import Foundation
import Testing

@testable import LibTCA

@Test func `simple feed update`() {
  let updates = _feedUpdates(input: .init(
    feeds: [
      Feed(show: .mock(1), episodes: []),
      Feed(show: .mock(2) { $0.name = "After" }, episodes: []),
    ],
    shows: [.mock(2) { $0.name = "Before" }, .mock(1)],
  ))
  expectNoDifference(updates, .init(showUpdates: [.mock(2) { $0.name = "After" }]))
}

@Test func `artwork url changed`() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(show: .mock(1) { $0.artworkUrl = "https://a.com/new.jpg" }, episodes: [])],
    shows: [.mock(1) { $0.artworkUrl = "https://a.com/old.jpg" }],
  ))

  expectNoDifference(updates, .init(
    showUpdates: [Show.mock(1) { $0.artworkUrl = "https://a.com/new.jpg" }],
    actions: [.replaceShowArtwork(showId: Show.ID(1), artworkUrl: "https://a.com/new.jpg")],
  ))
}

@Test func `new episode added`() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(show: .mock(1), episodes: [.mock(1, showId: 1), .mock(2, showId: 1)])],
    shows: [.mock(1)],
    episodes: [.mock(1, showId: 1)],
    now: .reference,
  ))

  expectNoDifference(updates, .init(
    addEpisodes: [.mock(2, showId: 1)],
  ))
}

@Test func `episode deleted`() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(show: .mock(1), episodes: [.mock(1, showId: 1)])],
    shows: [.mock(1)],
    episodes: [.mock(1, showId: 1), .mock(2, showId: 1)],
  ))

  expectNoDifference(updates, .init(deleteEpisodes: [.init(2)]))
}

@Test func `episode title changed`() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(
      show: .mock(1),
      episodes: [.mock(1, showId: 1) { $0.title = "Updated Title" }],
    )],
    shows: [.mock(1)],
    episodes: [.mock(1, showId: 1) { $0.title = "Original Title" }],
    now: .reference,
  ))

  expectNoDifference(updates, .init(
    episodeUpdates: [.mock(1, showId: 1) { $0.title = "Updated Title"
      $0.updatedAt = .reference
    }],
  ))
}

@Test func `episode audio properties changed`() {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(
      show: .mock(1),
      episodes: [
        .mock(1, showId: 1) { $0.audioUrl = "https://new.com/episode1.mp3" },
        .mock(2, showId: 1) { $0.duration = 7200 },
        .mock(3, showId: 1) { $0.sizeInBytes = 100_000_000 },
        .mock(4, showId: 1) { $0.audioType = .m4a },
        .mock(5, showId: 1) { $0.title = "Only title changed" },
      ],
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
    ],
  )
  let fetchedFeed2 = Feed(
    show: .mock(2) { $0.artworkUrl = "https://new.com/artwork2.jpg" },
    episodes: [
      .mock(3, showId: 2),
      .mock(4, showId: 2), // new episode
    ],
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

@Test func `audio invalidation removes file with old audioType`() async throws {
  let fetchedFeed = Feed(
    show: .mock(1),
    episodes: [.mock(1, showId: 1) { $0.audioType = .m4a }],
  )

  let removedUrls = LockIsolated<[URL]>([])
  try await withDependencies {
    $0.defaultDatabase = try! appDatabase()
    $0.date = .constant(.reference)
    $0.podcasts.getFeed = { _ in fetchedFeed }
    $0.podcasts.downloadArtwork = { _ in }
    $0.fileSystem.removeItem = { url in removedUrls.withValue { $0.append(url) } }
  } operation: {
    @Dependency(\.db) var database

    try await database.write { db in
      try Show.insert { [Show.mock(1)] }.execute(db)
      try Episode
        .insert { [Episode.mock(1, showId: 1) {
          $0.audioType = .mp3 // <-- old audio type
          $0.downloadedAt = .reference
        }] }
        .execute(db)
    }

    _ = await _performFeedUpdates(_feedUpdates(input: _prepareFeedUpdateInputData()))

    #expect(removedUrls.value.count == 1)
    #expect(removedUrls.value[0].lastPathComponent == "show-1-ep-1.mp3")

    let retrieved = database.tryRead { try Episode.find(Episode.ID(1)).fetchOne($0) }
    #expect(retrieved?.audioType == .m4a)
    #expect(retrieved!.downloadedAt == nil)
    #expect(retrieved?.localAudioUrl.lastPathComponent == "show-1-ep-1.m4a")
  }
}

@Test func `audio invalidation skips now playing episode`() throws {
  let updates = _feedUpdates(input: .init(
    feeds: [Feed(
      show: .mock(1),
      episodes: [
        .mock(1, showId: 1) { $0.audioUrl = "https://new.com/episode1.mp3" },
        .mock(2, showId: 1) { $0.audioUrl = "https://new.com/episode2.mp3" },
      ],
    )],
    shows: [.mock(1)],
    episodes: [
      .mock(1, showId: 1) { $0.downloadedAt = .reference },
      .mock(2, showId: 1) { $0.downloadedAt = .reference },
    ],
    nowPlaying: Episode.ID(1),
    now: .reference,
  ))

  #expect(updates.episodeUpdates.count == 2)
  #expect(updates.actions == [.invalidateEpisodeAudio(2)])
  #expect(updates.episodeUpdates.first(where: { $0.id == 1 })?.downloadedAt == .reference)
  #expect(updates.episodeUpdates.first(where: { $0.id == 2 })?.downloadedAt == nil)
}

@Test func `audio invalidation should clear downloadedAt`() async throws {
  let fetchedFeed = Feed(
    show: .mock(1),
    episodes: [
      .mock(1, showId: 1) { $0.duration = 7200 },
    ],
  )

  let removedUrls = LockIsolated<[URL]>([])

  try await withDependencies {
    $0.defaultDatabase = try! appDatabase()
    $0.date = .constant(.reference)
    $0.podcasts.getFeed = { _ in fetchedFeed }
    $0.podcasts.downloadArtwork = { _ in }
    $0.fileSystem.removeItem = { url in removedUrls.withValue { $0.append(url) } }
  } operation: {
    @Dependency(\.db) var database

    try await database.write { db in
      try Show.insert { [Show.mock(1)] }.execute(db)
      try Episode
        .insert { [Episode.mock(1, showId: 1) {
          $0.duration = 7301 // <- different from updated feed
          $0.downloadedAt = .reference
        }] }
        .execute(db)
    }

    let episodeBefore = database.tryRead { db in
      try Episode.find(Episode.ID(1)).fetchOne(db)
    }
    #expect(episodeBefore?.downloadedAt == .reference)

    let updates = await _feedUpdates(input: _prepareFeedUpdateInputData())
    #expect(updates.actions == [.invalidateEpisodeAudio(1)])

    _ = await _performFeedUpdates(updates)

    let episodeAfter = database.tryRead { db in
      try Episode.find(Episode.ID(1)).fetchOne(db)
    }

    #expect(episodeAfter?.downloadedAt == nil)
    #expect(episodeAfter?.duration == 7200)
    #expect(removedUrls.value.count == 1)
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
      iTunesId: 123_456_789,
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
      episodeNumber: id,
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
