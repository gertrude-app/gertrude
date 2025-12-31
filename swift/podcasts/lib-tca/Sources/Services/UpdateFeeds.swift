import Dependencies
import Foundation
import SQLiteData

struct FeedUpdateInputData: Equatable {
  var feeds: [Feed] = []
  var shows: [Show] = []
  var episodes: [Episode] = []
  var nowPlaying: Episode.ID?
  var now: Date = .init()
}

struct FeedUpdates: Equatable {
  var showUpdates: [Show] = []
  var episodeUpdates: [Episode] = []
  var addEpisodes: [Episode.Draft] = []
  var deleteEpisodes: [Episode.ID] = []
  var actions: [Action] = []

  enum Action: Equatable, Hashable {
    case replaceShowArtwork(showId: Show.ID, artworkUrl: String)
    case invalidateEpisodeAudio(Episode.ID)
  }

  var isEmpty: Bool {
    self.showUpdates.isEmpty &&
      self.episodeUpdates.isEmpty &&
      self.addEpisodes.isEmpty &&
      self.deleteEpisodes.isEmpty &&
      self.actions.isEmpty
  }
}

func updateFeeds(showIds: [Show.ID]? = nil) async -> [Episode] {
  let database = dep(\.db)
  guard database.subscription().status != .unpaid else {
    return []
  }

  guard takeUpdateLock(database) else {
    return []
  }
  defer { releaseUpdateLock(database) }

  let input = await _prepareFeedUpdateInputData(showIds: showIds)
  let updates = _feedUpdates(input: input)
  return await _performFeedUpdates(updates)
}

// NB: internal for tests, but should not be used directly, skips subscription check
func _prepareFeedUpdateInputData(showIds: [Show.ID]? = nil) async -> FeedUpdateInputData {
  @Dependency(\.db) var db
  @Dependency(\.date) var date
  @Dependency(\.podcasts) var podcasts
  @Fetch(NowPlaying()) var nowPlaying: NowPlaying.Value = nil

  let allShows = db.tryRead {
    try Show
      .where { if let showIds { $0.id.in(showIds) } }
      .fetchAll($0)
  }
  let allEpisodes = db.tryRead {
    try Episode
      .where { if let showIds { $0.showId.in(showIds) } }
      .fetchAll($0)
  }

  let pairs = await withTaskGroup(of: (show: Show, feed: Feed)?.self) { group in
    for show in allShows {
      group.addTask { [podcasts] in
        if let feed = try? await podcasts.getFeed(show.feedUrl) {
          return (show, feed)
        } else {
          return nil
        }
      }
    }
    var results: [(show: Show, feed: Feed)] = []
    for await result in group {
      result.map { results.append($0) }
    }
    return results
  }

  // we only examine shows and episodes we were able to fetch feeds for
  let fetchedShowIds = pairs.map(\.show.id)
  let fetchedEpisodes = allEpisodes
    .filter { fetchedShowIds.contains($0.showId) }

  return .init(
    feeds: pairs.map(\.feed),
    shows: pairs.map(\.show),
    episodes: fetchedEpisodes,
    nowPlaying: nowPlaying?.episode.id,
    now: date.now,
  )
}

// NB: internal for tests, but should not be used directly, skips subscription check
func _feedUpdates(input: FeedUpdateInputData) -> FeedUpdates {
  var updates = FeedUpdates()
  let showMap = Dictionary(uniqueKeysWithValues: input.shows.map { ($0.feedUrl, $0) })

  for feed in input.feeds {
    guard let show = showMap[feed.show.sourceUrl] else {
      unexpected(id: "c5e409b9", assert: true)
      continue
    }
    let updated = show.updated(from: feed.show)
    if updated != show {
      updates.showUpdates.append(updated)
    }

    if feed.show.artworkUrl != show.artworkUrl, let newUrl = feed.show.artworkUrl {
      updates.actions.append(.replaceShowArtwork(showId: show.id, artworkUrl: newUrl))
    }

    let showEpisodes = input.episodes.filter { $0.showId == show.id }
    let feedEpisodeGuids = Set(feed.episodes.map(\.guid))
    let existingEpisodeGuids = Set(showEpisodes.map(\.guid))

    let newEpisodesGuids = feedEpisodeGuids.subtracting(existingEpisodeGuids)
    for newEpisodeGuid in newEpisodesGuids {
      guard let episodeFeedData = feed.episodes.first(where: { $0.guid == newEpisodeGuid }) else {
        unexpected(id: "fb3a7ce5", assert: true)
        continue
      }
      updates.addEpisodes.append(episodeFeedData.toEpisodeDraft(showId: show.id, now: input.now))
    }

    let deletedEpisodeGuids = existingEpisodeGuids.subtracting(feedEpisodeGuids)
    for deletedEpisodeGuid in deletedEpisodeGuids {
      guard let episode = showEpisodes.first(where: { $0.guid == deletedEpisodeGuid }) else {
        unexpected(id: "e1ebff9a", assert: true)
        continue
      }
      if episode.id != input.nowPlaying {
        updates.deleteEpisodes.append(episode.id)
      }
    }

    let commonEpisodeGuids = feedEpisodeGuids.intersection(existingEpisodeGuids)
    for commonEpisodeGuid in commonEpisodeGuids {
      guard let existingEpisode = showEpisodes.first(where: { $0.guid == commonEpisodeGuid }),
            let feedEpisodeData = feed.episodes.first(where: { $0.guid == commonEpisodeGuid })
      else {
        unexpected(id: "a8b1cc45", assert: true)
        continue
      }
      var updatedEpisode = existingEpisode.updated(from: feedEpisodeData)
      if updatedEpisode != existingEpisode {
        let isNowPlaying = existingEpisode.id == input.nowPlaying
        if existingEpisode.audioChanged(from: feedEpisodeData), !isNowPlaying {
          updatedEpisode.downloadedAt = nil
          updates.actions.append(.invalidateEpisodeAudio(existingEpisode.id))
        }
        updates.episodeUpdates.append(updatedEpisode)
      }
    }
  }

  return updates
}

// NB: internal for tests, but should not be used directly, skips subscription check
func _performFeedUpdates(_ updates: FeedUpdates) async -> [Episode] {
  guard !updates.isEmpty else { return [] }
  @Dependency(\.db) var database
  @Dependency(\.podcasts) var podcasts

  if !updates.deleteEpisodes.isEmpty {
    let deleted = database.tryRead { db in
      try Episode
        .where { $0.id.in(updates.deleteEpisodes) }
        .fetchAll(db)
    }
    for episode in deleted {
      episode.removeLocalAudioFile()
    }
  }

  for action in updates.actions {
    if case .invalidateEpisodeAudio(let episodeId) = action {
      database.tryRead { db in
        if let episode = try Episode.find(episodeId).fetchOne(db) {
          episode.removeLocalAudioFile()
        }
      }
    }
  }

  let addedEpisodes = database.tryWrite { db in
    if !updates.showUpdates.isEmpty {
      try Show.upsert { updates.showUpdates }.execute(db)
    }
    if !updates.episodeUpdates.isEmpty {
      try Episode.upsert { updates.episodeUpdates }.execute(db)
    }
    if !updates.deleteEpisodes.isEmpty {
      try Episode
        .where { $0.id.in(updates.deleteEpisodes) }
        .delete()
        .execute(db)
    }
    return try Episode
      .upsert { updates.addEpisodes }
      .returning { $0.self }
      .fetchAll(db)
  }

  for action in updates.actions {
    if case .replaceShowArtwork(let showId, let artworkUrl) = action {
      if var show = database.tryRead({ try Show.find(showId).fetchOne($0) }) {
        show.artworkUrl = artworkUrl
        await podcasts.downloadArtwork(for: show)
      }
    }
  }

  return addedEpisodes
}

// helpers

extension Show {
  func updated(from feedData: Show.FeedData) -> Show {
    Show(
      id: self.id,
      name: feedData.name,
      author: feedData.author,
      description: feedData.description,
      feedUrl: self.feedUrl,
      websiteUrl: feedData.websiteUrl,
      artworkUrl: feedData.artworkUrl,
      showArtwork: self.showArtwork,
      iTunesId: feedData.iTunesId,
      sort: self.sort,
      updatedAt: self.updatedAt,
      createdAt: self.createdAt,
    )
  }
}

extension Episode {
  func updated(from feedData: Episode.FeedData) -> Episode {
    Episode(
      id: self.id,
      showId: self.showId,
      episodeNumber: feedData.episodeNumber,
      title: feedData.title,
      description: feedData.description,
      websiteUrl: feedData.websiteUrl,
      audioUrl: feedData.audioUrl,
      artworkUrl: feedData.artworkUrl,
      duration: feedData.duration,
      sizeInBytes: feedData.sizeInBytes,
      audioType: feedData.audioType,
      guid: feedData.guid,
      isArchived: self.isArchived,
      pubDate: feedData.pubDate,
      progress: self.progress,
      downloadedAt: self.downloadedAt,
      lastPlayedAt: self.lastPlayedAt,
      completedAt: self.completedAt,
      updatedAt: self.updatedAt,
      createdAt: self.createdAt,
    )
  }

  func audioChanged(from feedData: Episode.FeedData) -> Bool {
    self.audioUrl != feedData.audioUrl ||
      self.duration != feedData.duration ||
      self.sizeInBytes != feedData.sizeInBytes ||
      self.audioType != feedData.audioType
  }
}

private func takeUpdateLock(_ database: any DatabaseWriter) -> Bool {
  do {
    try database.write { db in
      try Record
        .insert { Record(id: .feedUpdatesLock, value: "") }
        .execute(db)
    }
    return true
  } catch {
    return false
  }
}

private func releaseUpdateLock(_ database: any DatabaseWriter) {
  database.tryWrite { db in
    try Record
      .find(id: .feedUpdatesLock)
      .delete()
      .execute(db)
  }
}
