import Dependencies

struct FeedUpdates: Equatable {
  var showUpdates: [Show] = []
  var addEpisodes: [Episode.Draft] = []
  var actions: [Action] = []

  enum Action: Equatable {
    case replaceShowArtwork(showId: Show.ID, artworkUrl: String)
  }
}

func feedUpdates(
  feeds: [Feed] = [],
  shows: [Show] = [],
  episodes: [Episode] = [],
  nowPlaying: Episode.ID? = nil
) -> FeedUpdates {
  var updates = FeedUpdates()
  let showMap = Dictionary(uniqueKeysWithValues: shows.map { ($0.feedUrl, $0) })

  for feed in feeds {
    guard let show = showMap[feed.show.sourceUrl] else {
      unexpected(id: "c5e409b9")
      continue // unexpected
    }
    let updated = show.updated(from: feed.show)
    if updated != show {
      updates.showUpdates.append(updated)
    }

    if feed.show.artworkUrl != show.artworkUrl, let newUrl = feed.show.artworkUrl {
      updates.actions.append(.replaceShowArtwork(showId: show.id, artworkUrl: newUrl))
    }

    let feedEpisodeGuids = Set(feed.episodes.map(\.guid))
    let existingEpisodeGuids = Set(episodes.filter { $0.showId == show.id }.map(\.guid))

    let newEpisodesGuids = feedEpisodeGuids.subtracting(existingEpisodeGuids)
    for newEpisodeGuid in newEpisodesGuids {
      guard let episodeFeedData = feed.episodes.first(where: { $0.guid == newEpisodeGuid }) else {
        unexpected(id: "fb3a7ce5")
        continue
      }
      updates.addEpisodes.append(episodeFeedData.toEpisodeDraft(showId: show.id))
    }
  }

  return updates
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
      updatedAt: self.updatedAt,
      createdAt: self.createdAt,
    )
  }
}
