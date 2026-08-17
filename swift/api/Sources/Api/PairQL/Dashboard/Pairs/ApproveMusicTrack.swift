import Dependencies
import DuetSQL
import PairQL

struct ApproveMusicTrack: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicTrackId: Music.TrackId
    var preferredAlbumId: Music.AlbumId
  }

  typealias Output = MusicCurationOutput
}

extension ApproveMusicTrack: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let resolution = try await get(dependency: \.appleMusic).resolveTrack(.init(
      storefront: child.appleMusicStorefront,
      trackId: input.appleMusicTrackId,
      preferredAlbumId: input.preferredAlbumId,
    ))
    let now = get(dependency: \.date.now)
    return try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let policy = try await Music.CatalogPolicy.load(childId: child.id, in: db)
      let changed = try await Music.CatalogPolicy.addTrack(
        childId: child.id,
        resolution: resolution,
        policy: policy,
        resolvedAt: now,
        in: db,
      )
      let snapshot = try await Music.LibrarySnapshotRepository.publish(
        childId: child.id,
        policyChanged: changed,
        generatedAt: now,
        in: db,
      )
      let updatedPolicy = try await Music.CatalogPolicy.load(childId: child.id, in: db)
      return updatedPolicy.curation(revision: snapshot.revision)
    }
  }
}
