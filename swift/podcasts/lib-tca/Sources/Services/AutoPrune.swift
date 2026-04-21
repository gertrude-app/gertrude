import Dependencies
import Foundation
import SQLiteData

func autoPruneDownloads() {
  @Dependency(\.db) var database
  @Dependency(\.date) var date

  let nowPlaying = database.nowPlaying()?.episode.id
  let episodes = database.tryRead { db in
    try Episode
      .whereDownloadCanBeDeleted(nowPlaying: nowPlaying, now: date.now)
      .fetchAll(db)
  }
  if episodes.isEmpty { return }
  safelyDiscardEpisodeDownloads(episodes.map(\.id), source: .autoPrune)
}
