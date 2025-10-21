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
  var updatedAt: Date = .init()

  init(
    id: ID = ID(1),
    episodeId: Episode.ID,
    isPlaying: Bool = false,
    minimized: Bool = true,
    nextDownloaded: Bool = false,
    updatedAt: Date = .init()
  ) {
    self.id = id
    self.episodeId = episodeId
    self.isPlaying = isPlaying
    self.minimized = minimized
    self.nextDownloaded = nextDownloaded
    self.updatedAt = updatedAt
  }
}

struct NowPlaying: FetchKeyRequest {
  typealias Value = Data?

  struct Data: Equatable {
    var isPlaying: Bool
    var minimized: Bool
    var nextDownloaded: Bool
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
      episode: episode,
      show: show
    )
  }
}

struct EpisodePlaying: FetchKeyRequest {
  typealias Value = Data?

  struct Data: Equatable {
    var episodeId: Episode.ID
    var isPlaying: Bool
  }

  func fetch(_ db: Database) throws -> Value {
    let data = try NowPlayingModel
      // NB: minimal query prevents unnecessary extra fetches on progress updates
      .select { ($0.episodeId, $0.isPlaying) }
      .where { $0.id == NowPlayingModel.ID(1) }
      .fetchOne(db)
    guard let data else { return nil }
    return .init(episodeId: data.0, isPlaying: data.1)
  }
}

extension EpisodePlaying.Value {
  func isPlaying(episodeId: Episode.ID) -> Bool {
    self?.episodeId == episodeId && self?.isPlaying == true
  }
}

extension NowPlaying.Value {
  func isPlaying(episodeId: Episode.ID) -> Bool {
    self?.episode.id == episodeId && self?.isPlaying == true
  }
}

extension NowPlaying.Data {
  func setProgress(_ progress: Double) {
    dep(\.db).tryWrite { db in
      try Episode
        .where { $0.id == self.episode.id }
        .update { $0.progress = progress }
        .execute(db)
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

  static func update(_ update: (inout NowPlayingModel) -> Void) {
    let database = dep(\.db)
    let model = database.tryRead { db in
      try NowPlayingModel.find(NowPlayingModel.ID(1)).fetchOne(db)
    }
    guard var model else {
      unexpected(id: "8de8f996", assert: true)
      return
    }

    update(&model)
    database.tryWrite { db in
      try NowPlayingModel.update(model).execute(db)
    }
  }

  static func dispatchUpdate(
    _ oldEpisodeId: Episode.ID?,
    _ oldWasPlaying: Bool?,
    _ newEpisodeId: Episode.ID?,
    _ newIsPlaying: Bool?
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
    try await dep(\.audio).play(episode: episode, show: show)
  }

  private static func onDelete(prevEpisodeId: Episode.ID, wasPlaying: Bool) async throws {
    try await dep(\.audio).pause()
  }

  private static func episodeChanged(_ episodeId: Episode.ID, _ isPlaying: Bool,) async throws {
    guard let (episode, show) = dep(\.db).episodeWithShow(episodeId) else {
      unexpected(id: "c13211b3", assert: true)
      return
    }
    if isPlaying {
      try await dep(\.audio).play(episode: episode, show: show)
    }
  }

  private static func playingToggled(
    _ episodeId: Episode.ID,
    _ wasPlaying: Bool,
  ) async throws {
    if wasPlaying {
      try await dep(\.audio).pause()
      return
    }
    guard let (episode, show) = dep(\.db).episodeWithShow(episodeId) else {
      unexpected(id: "20df6265", assert: true)
      return
    }
    try await dep(\.audio).play(episode: episode, show: show)
  }
}
