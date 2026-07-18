import Dependencies
import DuetSQL
import PairQL

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
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let resolution = try await get(dependency: \.appleMusic).resolveAlbum(
      input.appleMusicAlbumId,
    )
    let now = get(dependency: \.date.now)
    try await context.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: child.id, in: db)
      let existing = try await Music.ApprovedAlbum.query()
        .where(.childId == child.id)
        .where(.appleMusicAlbumId == input.appleMusicAlbumId.rawValue)
        .all(in: db)
        .first
      if let existing,
         existing.title == resolution.title,
         existing.artistName == resolution.artistName,
         existing.artworkUrl == resolution.artworkUrl,
         existing.artwork == resolution.artwork,
         existing.trackCount == resolution.trackCount,
         existing.showsArtwork == input.showsArtwork,
         existing.resolution == resolution {
        try await Music.LibrarySnapshotRepository.publish(
          childId: child.id,
          generatedAt: now,
          in: db,
        )
        return
      }
      try await db.upsert(
        Music.ApprovedAlbum(
          childId: child.id,
          appleMusicAlbumId: input.appleMusicAlbumId,
          title: resolution.title,
          artistName: resolution.artistName,
          artworkUrl: resolution.artworkUrl,
          artwork: resolution.artwork,
          trackCount: resolution.trackCount,
          showsArtwork: input.showsArtwork,
          resolution: resolution,
          resolvedAt: now,
        ),
        conflictOn: [.childId, .appleMusicAlbumId],
        do: .update(set: [
          .title,
          .artistName,
          .artworkUrl,
          .artwork,
          .trackCount,
          .showsArtwork,
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
