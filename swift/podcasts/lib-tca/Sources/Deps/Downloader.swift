import AVFoundation
import Dependencies
import SQLiteData

func trackedDownload(episode: Episode) async -> Result<Void, AppError> {
  @Dependency(\.db) var database
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.date) var date

  await testAssertCheckpoint("trackedDownload: enter")

  database.tryWrite { db in
    try Episode
      .update { $0.downloadedAt = .distantFuture }
      .where { $0.id == episode.id }
      .execute(db)
  }

  await testAssertCheckpoint("trackedDownload: did set ep.downloadedAt = .distantFuture")

  let success = await podcasts.downloadAudio(for: episode)

  await testAssertCheckpoint("trackedDownload: did downloadAudio")

  if success {
    database.tryWrite { db in
      try Episode
        .update { $0.downloadedAt = date.now }
        .where { $0.id == episode.id }
        .execute(db)
    }

    await testAssertCheckpoint("trackedDownload: success, did set ep.downloadedAt = date.now")

    if let duration = try? await determineMissingDuration(for: episode) {
      database.tryWrite { db in
        try Episode
          .update { $0.duration = duration }
          .where { $0.id == episode.id }
          .execute(db)
      }
    }
    return .success(())
  } else {
    database.tryWrite { db in
      try Episode
        .update { $0.downloadedAt = nil }
        .where { $0.id == episode.id }
        .execute(db)
    }

    await testAssertCheckpoint("trackedDownload: failure, did set ep.downloadedAt = nil")

    return .failure(.init(message: lstr(.episodeDownloadFailed)))
  }
}

func ensureDownloaded(episode: Episode) async -> Result<Void, AppError> {
  if episode.downloaded {
    .success(())
  } else if dep(\.network).isConnected() == false {
    .failure(.init(message: lstr(.episodeDownloadNoInternet)))
  } else {
    await trackedDownload(episode: episode)
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

func testAssertCheckpoint(_ label: String) async {
  #if DEBUG
    if dep(\.context) == .test {
      if false { eprint("⏰ -> start  ASSERT CHECKPOINT `\(label)`") }
      try? await dep(\.continuousClock).sleep(for: .seconds(1))
      if false { eprint("⏰ <- finish ASSERT CHECKPOINT `\(label)`") }
    }
  #endif
}
