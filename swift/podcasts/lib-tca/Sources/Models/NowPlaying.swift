import Foundation
import SQLiteData
import Tagged

@Table("nowPlaying")
struct NowPlayingModel {
  typealias ID = Tagged<Self, Int>
  let id: ID
  var episodeId: Episode.ID
  var isPlaying: Bool = false
  var minimized: Bool = true
  var nextDownloaded: Bool = false
  var bufferedProgress: Double?
  var updatedAt: Date = .init()

  init(
    id: ID = ID(1),
    episodeId: Episode.ID,
    isPlaying: Bool = false,
    minimized: Bool = true,
    nextDownloaded: Bool = false,
    progress: Double? = nil,
    updatedAt: Date = .init(),
  ) {
    self.id = id
    self.episodeId = episodeId
    self.isPlaying = isPlaying
    self.minimized = minimized
    self.nextDownloaded = nextDownloaded
    self.bufferedProgress = progress
    self.updatedAt = updatedAt
  }
}

struct NowPlaying: FetchKeyRequest {
  typealias Value = Data?

  struct Data: Equatable {
    var isPlaying: Bool
    var minimized: Bool
    var nextDownloaded: Bool
    var bufferedProgress: Double?
    var episode: Episode
    var show: Show
  }

  func fetch(_ db: Database) throws -> Value {
    let result = try NowPlayingModel
      .find(NowPlayingModel.ID(1))
      .leftJoin(Episode.all) { $0.episodeId.eq($1.id) }
      .join(Show.all) { $1.showId == $2.id }
      .fetchOne(db)

    guard let model = result?.0,
          let episode = result?.1,
          let show = result?.2 else {
      return nil
    }

    return .init(
      isPlaying: model.isPlaying,
      minimized: model.minimized,
      nextDownloaded: model.nextDownloaded,
      bufferedProgress: model.bufferedProgress,
      episode: episode,
      show: show,
    )
  }
}

extension NowPlaying.Value {
  func isPlaying(episodeId: Episode.ID) -> Bool {
    self?.episode.id == episodeId && self?.isPlaying == true
  }

  func bufferedProgress(episodeId: Episode.ID) -> Double? {
    guard self?.episode.id == episodeId else { return nil }
    return self?.bufferedProgress
  }
}

extension NowPlaying.Data {
  func setProgress(_ progress: Double, sync: Bool = true) {
    dep(\.db).tryWrite { db in
      try NowPlayingModel
        .update { $0.bufferedProgress = progress }
        .execute(db)
      if sync {
        try Episode
          .where { $0.id == self.episode.id }
          .update { $0.progress = progress }
          .execute(db)
      }
    }
  }

  func shouldDownloadNext(at progress: Double) -> Bool {
    !self.nextDownloaded &&
      progress > (Double(self.episode.duration ?? .max) - 120.0)
  }
}

extension NowPlaying {
  static func set(_ model: NowPlayingModel) {
    dep(\.db).tryWrite { db in
      try NowPlayingModel.upsert { model }
        .execute(db)
    }
  }

  static func delete() {
    dep(\.db).tryWrite { db in
      try NowPlayingModel
        .delete()
        .execute(db)
    }
  }

  /// also syncs buffered progress to episode.progress, which can cause
  /// db fetch triggers, so should not be used to update only progress
  /// use NowPlaying.setProgress(_:Double,sync:Bool) for that
  static func updateSyncingProgress(update: (inout NowPlayingModel) -> Void) {
    let database = dep(\.db)
    let model = database.tryRead { db in
      try NowPlayingModel.find(NowPlayingModel.ID(1)).fetchOne(db)
    }
    guard var model else {
      // NB: used to log `8de8f996` here, but i got 34 during first 2 months
      // i think because the system sometimes sends errant or delayed events
      return
    }

    update(&model)
    database.tryWrite { db in
      try NowPlayingModel.update(model).execute(db)
      if let buffered = model.bufferedProgress {
        try Episode
          .where { $0.id == model.episodeId }
          .update { $0.progress = buffered }
          .execute(db)
      }
    }
  }

  static func dispatchUpdate(
    _ oldEpisodeId: Episode.ID?,
    _ oldWasPlaying: Bool?,
    _ newEpisodeId: Episode.ID?,
    _ newIsPlaying: Bool?,
  ) async throws {
    switch (oldEpisodeId, oldWasPlaying, newEpisodeId, newIsPlaying) {
    case (nil, nil, .some(let episodeId), .some(let isPlaying)):
      try await NowPlaying.onCreate(episodeId: episodeId, isPlaying: isPlaying)
    case (.some(let episodeId), .some(let wasPlaying), nil, nil):
      try await NowPlaying.onDelete(prevEpisodeId: episodeId, wasPlaying: wasPlaying)
    case (.some(let oldEpId), .some(let wasPlaying), .some(let newEpId), .some(let isPlaying))
      where oldEpId != newEpId || wasPlaying != isPlaying:
      if oldEpId == newEpId {
        try await NowPlaying.playingToggled(newEpId, wasPlaying)
      } else {
        try await NowPlaying.episodeChanged(newEpId, isPlaying)
      }
    case (.some(let oldEpId), .some(let oldState), .some(let newEpId), .some(let newState))
      where oldEpId == newEpId && oldState == newState:
      break
    default:
      unexpected(id: "e975479b", assert: true)
    }
  }

  private static func onCreate(episodeId: Episode.ID, isPlaying: Bool) async throws {
    guard isPlaying else { return }
    guard let (episode, show) = dep(\.db).episodeWithShow(episodeId) else {
      unexpected(id: "1e83d193", assert: true)
      return
    }
    try await _play(episode: episode, show: show)
  }

  private static func onDelete(prevEpisodeId: Episode.ID, wasPlaying: Bool) async throws {
    await dep(\.audio).pause()
  }

  private static func episodeChanged(_ episodeId: Episode.ID, _ isPlaying: Bool) async throws {
    guard let (episode, show) = dep(\.db).episodeWithShow(episodeId) else {
      unexpected(id: "c13211b3", assert: true)
      return
    }
    if isPlaying {
      try await _play(episode: episode, show: show)
    }
  }

  private static func playingToggled(
    _ episodeId: Episode.ID,
    _ wasPlaying: Bool,
  ) async throws {
    if wasPlaying {
      await dep(\.audio).pause()
      return
    }
    guard let (episode, show) = dep(\.db).episodeWithShow(episodeId) else {
      unexpected(id: "20df6265", assert: true)
      return
    }
    try await _play(episode: episode, show: show)
  }
}

private func _play(episode: Episode, show: Show) async throws {
  await dep(\.audio).setPlaybackRate(show.playbackRate)
  let fileSystem = dep(\.fileSystem)
  let fileExists = fileSystem.fileExists(at: episode.localAudioUrl)
  let fileSize = fileSystem.fileSize(at: episode.localAudioUrl)

  if fileExists, let size = fileSize, size > 0 {
    try await dep(\.audio).play(episode: episode, show: show)
  } else {
    NowPlaying.updateSyncingProgress { $0.isPlaying = false }
    dep(\.db).tryWrite { db in
      try Episode
        .update { $0.downloadedAt = nil }
        .where { $0.id == episode.id }
        .execute(db)
    }
    let detail = missingPlaybackFileDetail(
      episode: episode,
      show: show,
      fileExists: fileExists,
      fileSize: fileSize,
    )
    if dep(\.network).isConnected() {
      switch await trackedDownload(episode: episode) {
      case .success:
        try await dep(\.audio).play(episode: episode, show: show)
        NowPlaying.updateSyncingProgress { $0.isPlaying = true }
        log(
          .info("d299b47a"),
          "episode play recovered after local file check failed",
          detail: detail,
        )
      case .cancelled:
        NowPlaying.delete()
      case .failure:
        NowPlaying.delete()
        unexpected(id: "2e2c9e97", detail)
      }
    } else {
      NowPlaying.delete()
    }
  }
}

private func missingPlaybackFileDetail(
  episode: Episode,
  show: Show,
  fileExists: Bool,
  fileSize: Int64?,
) -> String {
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

  return "ep:\(episode.id) show:\(show.id) file:\(fileState) expected:\(episode.sizeInBytes)b downloadedAt:\(downloadedAt) domain:\(domain)"
}
