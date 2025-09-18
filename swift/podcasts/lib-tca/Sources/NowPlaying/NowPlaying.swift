import Foundation
import SharingGRDB

struct NowPlaying: FetchKeyRequest {
  typealias Value = Data?

  struct Data: Equatable {
    var episode: Episode
    var show: Show
    var record: Misc
    var state: State
  }

  struct State: Equatable, Codable {
    var isPlaying: Bool
    var minimized: Bool
  }

  func fetch(_ db: Database) throws -> Value {
    let result = try Misc
      .find(id: .nowPlaying)
      .leftJoin(Episode.all) { #sql("\($0.rowId) = \($1.id)") }
      .leftJoin(Show.all) { $1.showId == $2.id }
      .fetchOne(db)

    guard let misc = result?.0, let state = misc.decodingValue(as: State.self),
          let episode = result?.1, let show = result?.2 else {
      return nil
    }

    return .init(
      episode: episode,
      show: show,
      record: misc,
      state: state,
    )
  }
}

extension NowPlaying {
  static func set(episode: Episode, show: Show, state: State) {
    guard let value = try? JSON.encode(state) else {
      unexpected(id: "eb1d1800")
      return
    }
    let deps = Deps()
    deps.db.tryWrite { db in
      try Misc.upsert { Misc(
        id: .nowPlaying,
        value: value,
        rowId: episode.id.rawValue,
        createdAt: deps.date.now
      ) }
      .execute(db)
    }
  }

  private static func onCreate(episodeId: Episode.ID, state: State) async throws {
    if !state.isPlaying {
      return
    }
    let deps = Deps()
    guard let (episode, show) = deps.db.episodeWithShow(episodeId) else {
      unexpected(id: "1e83d193")
      return
    }
    try await deps.audio.play(episode: episode, show: show)
  }

  private static func onDelete(prevEpisodeId: Episode.ID, prevState: State) async throws {
    fatalError("ON DELETE")
  }

  private static func stateChanged(
    _ episodeId: Episode.ID,
    _ state: State,
    _ prevState: State
  ) async throws {
    let deps = Deps()
    if !state.isPlaying {
      try await deps.audio.pause()
      return
    }
    guard let (episode, show) = deps.db.episodeWithShow(episodeId) else {
      unexpected(id: "20df6265")
      return
    }
    try await deps.audio.play(episode: episode, show: show)
  }

  private static func episodeChanged(
    _ episodeId: Episode.ID,
    _ state: State,
    _ prevEpisodeId: Episode.ID,
    _ prevState: State,
  ) async throws {
    let deps = Deps()
    guard let (episode, show) = deps.db.episodeWithShow(episodeId) else {
      unexpected(id: "c13211b3")
      return
    }
    if state.isPlaying {
      try await deps.audio.play(episode: episode, show: show)
    }
  }

  static func dispatchUpdate(
    _ oldEpisodeId: Episode.ID?,
    _ oldState: State?,
    _ newEpisodeId: Episode.ID?,
    _ newState: State?
  ) async throws {
    switch (oldEpisodeId, oldState, newEpisodeId, newState) {
    case (nil, nil, .some(let episodeId), .some(let state)):
      try await NowPlaying.onCreate(episodeId: episodeId, state: state)
    case (.some(let episodeId), .some(let state), nil, nil):
      try await NowPlaying.onDelete(prevEpisodeId: episodeId, prevState: state)
    case (.some(let oldEpId), .some(let oldState), .some(let newEpId), .some(let newState))
      where oldEpId != newEpId || oldState != newState:
      if oldEpId == newEpId {
        try await NowPlaying.stateChanged(newEpId, newState, oldState,)
      } else {
        try await NowPlaying.episodeChanged(newEpId, newState, oldEpId, oldState,)
      }
    case (.some(let oldEpId), .some(let oldState), .some(let newEpId), .some(let newState))
      where oldEpId == newEpId && oldState == newState:
      break
    default:
      unexpected(id: "e975479b")
    }
  }
}

extension NowPlaying.Data {
  func updateState(_ update: (inout NowPlaying.State) -> Void) {
    var newState = self.state
    update(&newState)
    NowPlaying.set(episode: self.episode, show: self.show, state: newState)
  }

  func setProgress(_ progress: Double) {
    Deps().db.tryWrite { db in
      try Episode
        .where { $0.id == self.episode.id }
        .update { $0.progress = progress }
        .execute(db)
    }
  }

  func isPlaying(episodeId: Episode.ID) -> Bool {
    self.episode.id == episodeId && self.state.isPlaying
  }
}

struct AnyNowPlaying: FetchKeyRequest {
  typealias Value = Bool

  func fetch(_ db: Database) throws -> Value {
    let count = try Misc
      .find(id: .nowPlaying)
      .count()
      .fetchOne(db)
    return (count ?? 0) > 0
  }
}

private struct Deps {
  @Dependency(\.defaultDatabase) var db
  @Dependency(\.date) var date
  @Dependency(\.audioPlayer) var audio
}
