import Dependencies
import DuetSQL
import PairQL

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
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let resolution = try await get(dependency: \.appleMusic).resolveArtist(
      input.appleMusicArtistId,
    )
    let now = get(dependency: \.date.now)
    try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let existing = try await Music.ApprovedArtist.query()
        .where(.childId == child.id)
        .where(.appleMusicArtistId == input.appleMusicArtistId.rawValue)
        .all(in: db)
        .first
      if let existing,
         existing.name == resolution.name,
         existing.catalogMetadata == resolution.catalogMetadata,
         existing.resolution == resolution {
        try await Music.LibrarySnapshotRepository.publish(
          childId: child.id,
          generatedAt: now,
          in: db,
        )
        return
      }
      try await db.upsert(
        Music.ApprovedArtist(
          childId: child.id,
          appleMusicArtistId: input.appleMusicArtistId,
          name: resolution.name,
          catalogMetadata: resolution.catalogMetadata,
          resolution: resolution,
          resolvedAt: now,
        ),
        conflictOn: [.childId, .appleMusicArtistId],
        do: .update(set: [
          .name,
          .catalogMetadata,
          .resolution,
          .resolvedAt,
        ]),
      )
      try await Music.LibrarySnapshotRepository.publish(
        childId: child.id,
        generatedAt: now,
        in: db,
      )
    }
    return .success
  }
}
