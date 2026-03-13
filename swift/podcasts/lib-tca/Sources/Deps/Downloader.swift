import AVFoundation
import Dependencies
import SQLiteData

enum DownloadOutcome {
  case success
  case cancelled
  case failure(AppError)

  var error: AppError? {
    if case .failure(let error) = self {
      error
    } else {
      nil
    }
  }
}

func trackedDownload(episode: Episode) async -> DownloadOutcome {
  @Dependency(\.db) var database
  @Dependency(\.podcasts) var podcasts
  @Dependency(\.date) var date
  @Dependency(\.fileSystem) var fileSystem

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
    let downloadState = database.tryRead { db in
      try Episode.find(episode.id).fetchOne(db)
    }

    let canRecordSuccess = downloadState.map {
      $0.downloading && localAudioLooksDownloaded($0, fileSystem: fileSystem)
    } ?? false

    guard canRecordSuccess else {
      let wasInvalidated = downloadState.map { !$0.downloading } ?? false
      if wasInvalidated {
        log(
          .info("8c975d36"),
          "download success invalidated before commit",
          detail: downloadStateDetail(episode, fileSystem: fileSystem),
        )
      }
      try? fileSystem.removeItem(at: episode.localAudioUrl)
      database.tryWrite { db in
        try Episode
          .update { $0.downloadedAt = nil }
          .where { $0.id == episode.id }
          .execute(db)
      }

      return wasInvalidated
        ? .cancelled
        : .failure(.init(message: lstr(.episodeDownloadFailed)))
    }

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
    return .success
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

func ensureDownloaded(episode: Episode) async -> DownloadOutcome {
  let fileSystem = dep(\.fileSystem)
  if episode.downloaded {
    if localAudioLooksDownloaded(episode, fileSystem: fileSystem) {
      return .success
    }
    try? fileSystem.removeItem(at: episode.localAudioUrl)
    dep(\.db).tryWrite { db in
      try Episode
        .update { $0.downloadedAt = nil }
        .where { $0.id == episode.id }
        .execute(db)
    }
    unexpected(
      id: "459454b4",
      downloadStateDetail(episode, fileSystem: fileSystem),
    )
  }
  if dep(\.network).isConnected() == false {
    return .failure(.init(message: lstr(.episodeDownloadNoInternet)))
  }
  return await trackedDownload(episode: episode)
}

private func localAudioLooksDownloaded(
  _ episode: Episode,
  fileSystem: FileSystemClient,
) -> Bool {
  guard fileSystem.fileExists(at: episode.localAudioUrl),
        let size = fileSystem.fileSize(at: episode.localAudioUrl) else {
    return false
  }
  return size > 0
}

private func downloadStateDetail(
  _ episode: Episode,
  fileSystem: FileSystemClient,
) -> String {
  let fileExists = fileSystem.fileExists(at: episode.localAudioUrl)
  let fileSize = fileSystem.fileSize(at: episode.localAudioUrl)

  let fileState = if fileExists {
    if let fileSize {
      "exists:\(fileSize)b"
    } else {
      "exists:unknown"
    }
  } else {
    "missing"
  }

  let downloadedAt = episode.downloadedAt.map { "\($0)" } ?? "nil"
  let domain = URL(string: episode.audioUrl)?.host ?? "unknown"

  return "ep:\(episode.id) show:\(episode.showId) file:\(fileState) expected:\(episode.sizeInBytes)b downloadedAt:\(downloadedAt) domain:\(domain)"
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
