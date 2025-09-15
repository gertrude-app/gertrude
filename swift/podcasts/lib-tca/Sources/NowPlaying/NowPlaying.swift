import Foundation
import SharingGRDB

struct NowPlaying: FetchKeyRequest {
  typealias Value = Data?

  struct Data: Equatable {
    var episode: Episode
    var show: Show
    var record: Misc
    var state: State

    func updateState(_ update: (inout State) -> Void) throws {
      var newState = self.state
      update(&newState)
      try NowPlaying.set(episode: self.episode, show: self.show, state: newState)
    }

    func isPlaying(episodeId: Int) -> Bool {
      self.episode.id == episodeId && self.state.isPlaying
    }
  }

  struct State: Equatable, Codable {
    var isPlaying: Bool
    var minimized: Bool
  }

  static func set(episode: Episode, show: Show, state: State) throws {
    @Dependency(\.date.now) var now
    @Dependency(\.defaultDatabase) var db
    let value = try JSON.encode(state)
    db.tryWrite { db in
      try Misc.upsert {
        Misc(
          id: Misc.ids.nowPlaying,
          value: value,
          rowId: episode.id,
          updatedAt: now,
          createdAt: now
        )
      }
      .execute(db)
    }
  }

  func fetch(_ db: Database) throws -> Value {
    let result = try Misc
      .where { $0.id == Misc.ids.nowPlaying && $0.rowId != nil }
      .leftJoin(Episode.all) { $0.rowId == $1.id }
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

struct AnyNowPlaying: FetchKeyRequest {
  typealias Value = Bool

  func fetch(_ db: Database) throws -> Value {
    let count = try Misc
      .where { $0.id == Misc.ids.nowPlaying && $0.rowId != nil }
      .count()
      .fetchOne(db)
    return (count ?? 0) > 0
  }
}
