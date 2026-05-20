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

  @Test func `most recently listened per show skips completed and archived candidates`() async throws {
    @Dependency(\.db) var database
    try await database.write { db in
      try Show.insert { .mock(4) }.execute(db)
      try Episode
        .insert { [
          .mock(50, showId: 1) { $0.lastPlayedAt = .reference + .days(20) },
          .mock(51, showId: 2) {
            $0.lastPlayedAt = .reference + .days(10)
            $0.completedAt = .reference + .days(10) // <- newest, completed
          },
          .mock(52, showId: 2) { $0.lastPlayedAt = .reference + .days(4) },
          .mock(61, showId: 3) {
            $0.lastPlayedAt = .reference + .days(9)
            $0.isArchived = true // <- newest, archived
          },
          .mock(62, showId: 3) { $0.lastPlayedAt = .reference + .days(6) },
          .mock(71, showId: 4) {
            $0.lastPlayedAt = .reference + .days(8)
            $0.completedAt = .reference + .days(8)
          },
          .mock(72, showId: 4) {
            $0.lastPlayedAt = .reference + .days(7)
            $0.isArchived = true
          },
        ] }
        .execute(db)
    }

    let queue = AutoQueue.mostRecentlyListenedEpisodePerShow(excluding: Show.mock(1))

    expectNoDifference(queue.map(\.episodeNumber), [62, 52]) // <- latest valid per show
  }

  @Test func `rolling to another show resumes its in-progress episode first`() async throws {
    @Dependency(\.db) var database
    try await database.write { db in
      try Episode
        .insert { [
          .mock(1, showId: 1),
          .mock(9, showId: 2) { $0.pubDate += .days(1) },
          .mock(10, showId: 2) {
            $0.pubDate += .days(2)
            $0.lastPlayedAt = .reference + .days(5)
            $0.progress = 120 // <- resumed anchor
          },
          .mock(11, showId: 2) { $0.pubDate += .days(3) },
        ] }
        .execute(db)
      try NowPlayingModel.insert {
        NowPlayingModel(episodeId: 1, isPlaying: true)
      }.execute(db)
    }

    let nowPlaying = try await database.read { try NowPlaying().fetch($0)! }

    let queue = AutoQueue.episodeQueue(after: nowPlaying)

    expectNoDifference([10, 11, 9], queue.map(\.episodeNumber)) // <- includes anchor
    expectNoDifference(120, queue.first?.progress)
  }

  @Test func `rolling to another show skips its completed most-recent episode`() async throws {
    @Dependency(\.db) var database
    try await database.write { db in
      try Episode
        .insert { [
          .mock(1, showId: 1),
          .mock(20, showId: 2) {
            $0.pubDate += .days(1)
            $0.lastPlayedAt = .reference + .days(10)
            $0.completedAt = .reference + .days(10) // <- newest, completed
          },
          .mock(21, showId: 2) {
            $0.pubDate += .days(2)
            $0.lastPlayedAt = .reference + .days(5)
            $0.progress = 0.3
          },
          .mock(22, showId: 2) { $0.pubDate += .days(3) },
        ] }
        .execute(db)
      try NowPlayingModel.insert {
        NowPlayingModel(episodeId: 1, isPlaying: true)
      }.execute(db)
    }

    let nowPlaying = try await database.read { try NowPlaying().fetch($0)! }

    let queue = AutoQueue.episodeQueue(after: nowPlaying)

    expectNoDifference([21, 22], queue.map(\.episodeNumber)) // <- resumes older
  }

  @Test func `rolling to another show excludes archived episodes`() async throws {
    @Dependency(\.db) var database
    try await database.write { db in
      try Episode
        .insert { [
          .mock(1, showId: 1),
          .mock(30, showId: 2) {
            $0.pubDate += .days(1)
            $0.lastPlayedAt = .reference + .days(10)
            $0.isArchived = true // <- newest, archived
          },
          .mock(31, showId: 2) {
            $0.pubDate += .days(2)
            $0.lastPlayedAt = .reference + .days(5)
            $0.progress = 0.2
          },
          .mock(32, showId: 2) {
            $0.pubDate += .days(3)
            $0.isArchived = true
          },
          .mock(33, showId: 2) { $0.pubDate += .days(4) },
        ] }
        .execute(db)
      try NowPlayingModel.insert {
        NowPlayingModel(episodeId: 1, isPlaying: true)
      }.execute(db)
    }

    let nowPlaying = try await database.read { try NowPlaying().fetch($0)! }

    let queue = AutoQueue.episodeQueue(after: nowPlaying)

    expectNoDifference([31, 33], queue.map(\.episodeNumber)) // <- skips archived
  }

  @Test func `fallback unplayed queue excludes completed and archived episodes`() async throws {
    @Dependency(\.db) var database
    try await database.write { db in
      try Episode
        .insert { [
          .mock(1, showId: 1) {
            $0.lastPlayedAt = .reference
          },
          .mock(41, showId: 2) { $0.pubDate += .days(1) },
          .mock(42, showId: 2) {
            $0.pubDate += .days(2)
            $0.completedAt = .reference + .days(1) // <- unplayed, completed
          },
          .mock(43, showId: 3) {
            $0.pubDate += .days(3)
            $0.isArchived = true // <- unplayed, archived
          },
        ] }
        .execute(db)
      try NowPlayingModel.insert {
        NowPlayingModel(episodeId: 1, isPlaying: true)
      }.execute(db)
    }

    let nowPlaying = try await database.read { try NowPlaying().fetch($0)! }

    let queue = AutoQueue.episodeQueue(after: nowPlaying)

    expectNoDifference([41], queue.map(\.episodeNumber)) // <- only valid fallback
  }

  @Test func `continuing within the same show excludes the just-completed episode`() async throws {
    @Dependency(\.db) var database
    let current = Episode.mock(1, showId: 1) {
      $0.pubDate += .days(1)
      $0.completedAt = .reference + .days(1) // <- completed anchor
    }
    try await database.write { db in
      try Episode
        .insert { [
          current,
          .mock(2, showId: 1) { $0.pubDate += .days(2) },
          .mock(3, showId: 1) { $0.pubDate += .days(3) },
        ] }
        .execute(db)
      try NowPlayingModel.insert {
        NowPlayingModel(episodeId: 1, isPlaying: true)
      }.execute(db)
    }

    let queue = AutoQueue.episodeQueue(within: 1, after: current)

    expectNoDifference([2, 3], queue.map(\.episodeNumber))
  }
}
