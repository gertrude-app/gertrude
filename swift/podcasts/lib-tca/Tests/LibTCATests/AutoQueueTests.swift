import CustomDump
import Dependencies
import DependenciesTestSupport
import Foundation
import SQLiteData
import Testing

@testable import LibTCA

@Suite(.dependencies {
  $0.audio = .testValue // for inserting now playing trigger
  $0.defaultDatabase = try! appDatabase()
  $0.defaultDatabase.tryWrite {
    try Show.insert { [.mock(1), .mock(2), .mock(3)] }.execute($0)
  }
})
struct AutoQueueTests {
  @Test func `episode queue gives episodes in reverse order`() async throws {
    @Dependency(\.db) var database
    let current = Episode.mock(3, showId: 1) { $0.pubDate += .days(2) }
    try await database.write { db in
      try Episode
        .insert { [
          .mock(6, showId: 1) {
            $0.pubDate += .days(5)
            $0.progress = 10.2
          },
          .mock(5, showId: 1) { $0.pubDate += .days(4) },
          .mock(4, showId: 1) { $0.pubDate += .days(3) },
          current,
          .mock(2, showId: 1) { $0.pubDate += .days(1) },
          .mock(1, showId: 1) { $0.pubDate = .reference },
        ] }
        .execute(db)
      try NowPlayingModel.insert {
        NowPlayingModel(episodeId: 3, isPlaying: true)
      }.execute(db)
    }

    let queue = AutoQueue.episodeQueue(within: 1, after: current)

    expectNoDifference([4, 5, 2, 1], queue.map(\.episodeNumber))
  }

  @Test func `episode queue respects oldest first sort order`() async throws {
    @Dependency(\.db) var database
    let show = Show.mock(1) { $0.sort = .oldestToNewest }
    let current = Episode.mock(3, showId: 1) { $0.pubDate += .days(2) }
    try await database.write { db in
      try Show.update { $0.sort = #bind(.oldestToNewest) }
        .where { $0.id.eq(show.id) }
        .execute(db)
      try Episode
        .insert { [
          .mock(6, showId: 1) {
            $0.pubDate += .days(5)
            $0.progress = 10.2
          },
          .mock(5, showId: 1) { $0.pubDate += .days(4) },
          .mock(4, showId: 1) { $0.pubDate += .days(3) },
          current,
          .mock(2, showId: 1) { $0.pubDate += .days(1) },
          .mock(1, showId: 1) { $0.pubDate = .reference },
        ] }
        .execute(db)
      try NowPlayingModel.insert {
        NowPlayingModel(episodeId: 3, isPlaying: true)
      }.execute(db)
    }

    let nowPlaying = try await database.read { try NowPlaying().fetch($0)! }

    let queue = AutoQueue.episodeQueue(after: nowPlaying)

    expectNoDifference([4, 5, 2, 1], queue.map(\.episodeNumber))
  }

  @Test func `episode queue outside gives most recently played per show`() async throws {
    @Dependency(\.db) var database
    try await database.write { db in
      try Episode
        .insert { [
          Episode.mock(1, showId: 2) { $0.lastPlayedAt = .reference + .days(1) },
          .mock(2, showId: 2) { $0.lastPlayedAt = .reference + .days(3) },
          .mock(3, showId: 2) { $0.lastPlayedAt = nil },
          .mock(4, showId: 3) { $0.lastPlayedAt = .reference + .days(2) },
          .mock(5, showId: 3) { $0.lastPlayedAt = .reference + .days(5) },
          .mock(6, showId: 1) { $0.lastPlayedAt = .reference + .days(10) },
        ] }
        .execute(db)
    }

    let queue = AutoQueue.mostRecentlyListenedEpisodePerShow(excluding: Show.mock(1))

    expectNoDifference(queue.map(\.episodeNumber), [5, 2])
  }
}
