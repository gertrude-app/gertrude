import SharingGRDB

protocol Downloader {
  var db: any DatabaseWriter { get }
  var podcasts: PodcastClient { get }
  var date: DateGenerator { get }
}

extension Downloader {
  @discardableResult
  func trackedDownload(episode: Episode) async -> Bool {
    self.db.tryWrite { db in
      try Episode
        .update { $0.downloadedAt = .distantFuture }
        .where { $0.id == episode.id }
        .execute(db)
    }
    // TODO: handle errors
    let success = await self.podcasts.download(episode: episode)
    if success {
      self.db.tryWrite { db in
        try Episode
          .update { $0.downloadedAt = self.date.now }
          .where { $0.id == episode.id }
          .execute(db)
      }
    } else {
      self.db.tryWrite { db in
        try Episode
          .update { $0.downloadedAt = nil }
          .where { $0.id == episode.id }
          .execute(db)
      }
    }
    return success
  }
}
