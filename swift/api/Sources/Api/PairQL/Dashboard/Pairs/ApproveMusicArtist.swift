import Dependencies
import DuetSQL
import PairQL

// @deprecated safe to remove 2026-09-01
struct ApproveMusicArtist: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicArtistId: Music.ArtistId
    var name: String
    var catalogMetadata: Music.CatalogMetadata?
  }
}

extension ApproveMusicArtist: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    await context.db.logDeprecated("ApproveMusicArtist(v1)")
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let resolution = try await get(dependency: \.appleMusic).resolveArtist(
      input.appleMusicArtistId,
    )
    let now = get(dependency: \.date.now)
    try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let policy = try await Music.CatalogPolicy.load(childId: child.id, in: db)
      let covered = try policy.coverage.directGrantsCovered(by: resolution)
      guard covered.albumIds.isEmpty, covered.trackIds.isEmpty else {
        throw context.error(
          "3184828b",
          .badRequest,
          user: "Reload Gertrude to review which existing music allowances this artist will replace.",
        )
      }
      let changed = try await Music.CatalogPolicy.addArtist(
        childId: child.id,
        resolution: resolution,
        policy: policy,
        resolvedAt: now,
        in: db,
      )
      _ = try await publishMusicPolicy(
        childId: child.id,
        changed: changed,
        generatedAt: now,
        in: db,
      )
    }
    return .success
  }
}
