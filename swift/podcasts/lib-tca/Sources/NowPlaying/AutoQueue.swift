import Dependencies
import SQLiteData

enum AutoQueue {
  static func nextDownloadedEpisode(
    after nowPlaying: NowPlaying.Data
  ) -> (episode: Episode, show: Show)? {
    guard let episode = self.episodeQueue(after: nowPlaying)
      .first(where: { $0.downloaded }) else {
      return nil
    }

    @Dependency(\.db) var database
    return database.episodeWithShow(episode.id)
  }

  static func downloadNextEpisode(after nowPlaying: NowPlaying.Data) async {
    @Dependency(\.network) var network
    if !network.isConnected() {
      return
    }

    guard let next = self.episodeQueue(after: nowPlaying).first,
          next.downloaded == false else {
      return
    }

    _ = await trackedDownload(episode: next)
  }

  static func episodeQueue(after nowPlaying: NowPlaying.Data) -> [Episode] {
    // first, try to continue listening within the same show
    let showQueue = self.episodeQueue(within: nowPlaying.show.id, after: nowPlaying.episode)
    if !showQueue.isEmpty {
      return showQueue
    }

    // otherwise, work through most recently listened other shows, continuing
    let recent = self.mostRecentlyListenedEpisodePerShow(excluding: nowPlaying.show)
    for episode in recent {
      let queue = self.episodeQueue(within: episode.showId, after: episode)
      if !queue.isEmpty {
        return queue
      }
    }

    // finally, just queue up unplayed episodes from any show
    @Dependency(\.db) var database
    return database.tryRead { db in
      try Episode
        .where { $0.lastPlayedAt.is(nil) }
        .order { $0.pubDate.desc() }
        .fetchAll(db)
    }
  }

  static func episodeQueue(within show: Show.ID, after episode: Episode) -> [Episode] {
    @Dependency(\.db) var database
    let episodes: [Episode] = database.tryRead { db in
      let newerEpisodes = try Episode
        .where { $0.showId.eq(show) }
        .where { $0.id.neq(episode.id) }
        .where { $0.pubDate.gt(episode.pubDate) }
        .where { $0.progress.lt(2.0) }
        .order { $0.pubDate.asc() }
        .fetchAll(db)
      let olderEpisodes = try Episode
        .where { $0.showId.eq(show) }
        .where { $0.id.neq(episode.id) }
        .where { $0.pubDate.lt(episode.pubDate) }
        .where { $0.progress.lt(2.0) }
        .order { $0.pubDate.desc() }
        .fetchAll(db)
      return newerEpisodes + olderEpisodes
    }
    return episodes
  }

  static func mostRecentlyListenedEpisodePerShow(excluding show: Show) -> [Episode] {
    @Dependency(\.db) var database
    let episodes: [Episode] = database.tryRead { db in
      try #sql(
        """
        SELECT *
        FROM \(Episode.self)
        INNER JOIN (
          SELECT 
            \(Episode.col.showId),
            MAX(\(Episode.col.lastPlayedAt)) as mostRecentPlay
          FROM \(Episode.self)
          WHERE
            \(Episode.col.lastPlayedAt) IS NOT NULL
              AND
            \(Episode.col.showId) != \(raw: show.id)
          GROUP BY \(Episode.col.showId)
        ) recent ON
          \(Episode.col.showId) = recent.\(raw: Episode.col.showId.name)
            AND
          \(Episode.col.lastPlayedAt) = recent.mostRecentPlay
        ORDER BY \(Episode.col.lastPlayedAt) DESC
        """,
        as: Episode.self
      )
      .fetchAll(db)
    }
    return episodes
  }
}
