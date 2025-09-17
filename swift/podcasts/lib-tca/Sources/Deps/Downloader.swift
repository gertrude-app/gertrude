import AVFoundation
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
    let success = await self.podcasts.downloadAudio(for: episode)
    if success {
      self.db.tryWrite { db in
        try Episode
          .update { $0.downloadedAt = self.date.now }
          .where { $0.id == episode.id }
          .execute(db)
      }
      if let duration = try? await self.determineMissingDuration(for: episode) {
        self.db.tryWrite { db in
          try Episode
            .update { $0.duration = duration }
            .where { $0.id == episode.id }
            .execute(db)
        }
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

  @discardableResult
  func ensureDownloaded(episode: Episode) async -> Bool {
    if episode.downloaded {
      true
    } else {
      await self.trackedDownload(episode: episode)
    }
  }

  private func determineMissingDuration(for episode: Episode) async throws -> Int? {
    guard episode.duration == nil else {
      return nil
    }
    let asset = AVURLAsset(url: episode.localAudioUrl)
    let duration = try await CMTimeGetSeconds(asset.load(.duration))
    if duration.isNaN || duration.isInfinite || duration <= 0 {
      return nil
    }
    return Int(duration)
  }
}

//
// let url = URL(fileURLWithPath: "path/to/file.mp3")
// let asset = AVURLAsset(url: url)
// let duration = CMTimeGetSeconds(asset.duration)
// print(duration)
