import Dependencies
import DuetSQL
import PairQL

// @deprecated safe to remove 2026-09-01
struct ApproveMusicAlbum: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicAlbumId: Music.AlbumId
    var title: String
    var artistName: String
    var artworkUrl: String?
    var artwork: Music.Artwork?
    var trackCount: Int?
    var showsArtwork = true
  }
}

extension ApproveMusicAlbum: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    await context.db.logDeprecated("ApproveMusicAlbum(v1)")
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let resolution = try await get(dependency: \.appleMusic).resolveAlbum(
      input.appleMusicAlbumId,
    )
    let now = get(dependency: \.date.now)
    try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let policy = try await Music.CatalogPolicy.load(childId: child.id, in: db)
      let changed = try await Music.CatalogPolicy.addAlbum(
        childId: child.id,
        resolution: resolution,
        showsArtwork: input.showsArtwork,
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
