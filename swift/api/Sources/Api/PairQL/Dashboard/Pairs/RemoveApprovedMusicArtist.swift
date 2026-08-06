import Dependencies
import DuetSQL
import PairQL

struct RemoveApprovedMusicArtist: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicArtistId: Music.ArtistId
  }
}

extension RemoveApprovedMusicArtist: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let now = get(dependency: \.date.now)
    try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let policy = try await Music.CatalogPolicy.load(childId: child.id, in: db)
      guard let artist = policy.artist(input.appleMusicArtistId) else { return }
      let changed = try await Music.CatalogPolicy.removeArtist(
        artist,
        policy: policy,
        in: db,
      )
      if changed {
        _ = try await Music.LibrarySnapshotRepository.publishAfterPolicyChange(
          childId: child.id,
          generatedAt: now,
          in: db,
        )
      }
    }
    return .success
  }
}
