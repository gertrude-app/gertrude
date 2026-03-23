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
  @Dependency(\.downloadCoordinator) var downloadCoordinator
  return await downloadCoordinator.run(episodeId: episode.id) {
    await _trackedDownload(episode: episode)
  }
}

private func _trackedDownload(episode: Episode) async -> DownloadOutcome {
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
  let currentEpisode = dep(\.db).tryRead { db in
    try Episode.find(episode.id).fetchOne(db)
  } ?? episode
  let fileSystem = dep(\.fileSystem)
  if currentEpisode.downloaded {
    if localAudioLooksDownloaded(currentEpisode, fileSystem: fileSystem) {
      return .success
    }
    try? fileSystem.removeItem(at: currentEpisode.localAudioUrl)
    dep(\.db).tryWrite { db in
      try Episode
        .update { $0.downloadedAt = nil }
        .where { $0.id == currentEpisode.id }
        .execute(db)
    }
    unexpected(
      id: "459454b4",
      downloadStateDetail(currentEpisode, fileSystem: fileSystem),
    )
  }
  if currentEpisode.downloading {
    return await trackedDownload(episode: currentEpisode)
  }
  if dep(\.network).isConnected() == false {
    return .failure(.init(message: lstr(.episodeDownloadNoInternet)))
  }
  return await trackedDownload(episode: currentEpisode)
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

actor EpisodeDownloadCoordinator {
  private var inFlight: [Episode.ID: Task<DownloadOutcome, Never>] = [:]

  func run(
    episodeId: Episode.ID,
    operation: @escaping @Sendable () async -> DownloadOutcome,
  ) async -> DownloadOutcome {
    if let existing = self.inFlight[episodeId] {
      return await existing.value
    }

    let task = Task {
      await operation()
    }
    self.inFlight[episodeId] = task
    defer { self.inFlight[episodeId] = nil }

    let outcome = await task.value
    return outcome
  }
}

extension EpisodeDownloadCoordinator: DependencyKey {
  static var liveValue: EpisodeDownloadCoordinator {
    EpisodeDownloadCoordinator()
  }

  static var testValue: EpisodeDownloadCoordinator {
    EpisodeDownloadCoordinator()
  }
}

extension DependencyValues {
  // dependency-scoped so tests don't share a process-global in-flight download registry.
  var downloadCoordinator: EpisodeDownloadCoordinator {
    get { self[EpisodeDownloadCoordinator.self] }
    set { self[EpisodeDownloadCoordinator.self] = newValue }
  }
}
