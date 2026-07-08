import Dependencies
import Foundation
import SQLiteData

enum DownloadInvalidationSource: String {
  case feedRefreshAudioChanged
  case autoPrune
  case reclaimStorage
  case manualRemove
  case archiveEpisode
  case playbackRecovery
}

struct SafelyDiscardedEpisodeDownloads {
  var invalidatedEpisodes: [Episode] = []
  var protectedEpisodeIds: Set<Episode.ID> = []

  var isEmpty: Bool {
    self.invalidatedEpisodes.isEmpty && self.protectedEpisodeIds.isEmpty
  }
}

func activelyDownloadingEpisodeIds(
  _ episodeIds: [Episode.ID],
  source: DownloadInvalidationSource,
) -> Set<Episode.ID> {
  guard !episodeIds.isEmpty else { return [] }
  let database = dep(\.db)
  let fileSystem = dep(\.fileSystem)
  let episodes = database.tryRead { db in
    try Episode
      .where { $0.id.in(episodeIds) }
      .fetchAll(db)
  }

  let protected = Set(episodes.filter(\.downloading).map(\.id))
  for episode in episodes where protected.contains(episode.id) {
    log(
      .info,
      .download,
      "4ac9084e",
      detail: invalidationDetail(episode: episode, source: source, fileSystem: fileSystem),
    )
  }
  return protected
}

@discardableResult
func safelyDiscardEpisodeDownloads(
  _ episodeIds: [Episode.ID],
  source: DownloadInvalidationSource,
) -> SafelyDiscardedEpisodeDownloads {
  guard !episodeIds.isEmpty else { return .init() }
  let protected = activelyDownloadingEpisodeIds(episodeIds, source: source)
  let allowedIds = episodeIds.filter { !protected.contains($0) }
  guard !allowedIds.isEmpty else {
    return .init(protectedEpisodeIds: protected)
  }

  let database = dep(\.db)
  let episodes = database.tryRead { db in
    try Episode
      .where { $0.id.in(allowedIds) }
      .fetchAll(db)
  }

  guard !episodes.isEmpty else {
    return .init(protectedEpisodeIds: protected)
  }

  database.tryWrite { db in
    try Episode
      .update { $0.downloadedAt = #bind(nil) }
      .where { $0.id.in(episodes.map(\.id)) }
      .execute(db)
  }

  episodes.forEach { $0.removeLocalAudioFile() }
  return .init(invalidatedEpisodes: episodes, protectedEpisodeIds: protected)
}

private func invalidationDetail(
  episode: Episode,
  source: DownloadInvalidationSource,
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
  return "source:\(source.rawValue) ep:\(episode.id) show:\(episode.showId) file:\(fileState) expected:\(episode.sizeInBytes)b downloadedAt:\(downloadedAt)"
}
