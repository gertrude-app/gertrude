import Dependencies
import DuetSQL
import PairQL

struct RemoveApprovedMusicAlbum: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicAlbumId: Music.AlbumId
  }
}

extension RemoveApprovedMusicAlbum: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let now = get(dependency: \.date.now)
    try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let deleted = try await Music.ApprovedAlbum.query()
        .where(.childId == child.id)
        .where(.appleMusicAlbumId == input.appleMusicAlbumId.rawValue)
        .delete(in: db)
      if deleted > 0 {
        try await Music.LibrarySnapshotRepository.publish(
          childId: child.id,
          generatedAt: now,
          in: db,
        )
      }
    }
    return .success
  }
}
