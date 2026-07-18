import DuetSQL
import Foundation

extension Music {
  enum LibrarySnapshotRepository {
    static func lock(
      childId: Child.Id,
      in db: any DuetSQL.Client,
    ) async throws {
      try await db.execute(raw: """
        SELECT id
        FROM parent.children
        WHERE id = '\(uuid: childId.rawValue)'
        FOR UPDATE;
      """)
    }

    static func snapshot(
      for childId: Child.Id,
      in db: any DuetSQL.Client,
    ) async throws -> LibrarySnapshot? {
      try await LibrarySnapshot.query()
        .where(.childId == childId)
        .all(in: db)
        .first
    }

    @discardableResult
    static func publish(
      childId: Child.Id,
      generatedAt: Date,
      in db: any DuetSQL.Client,
    ) async throws -> LibrarySnapshot {
      let albumGrants = try await ApprovedAlbum.query()
        .where(.childId == childId)
        .orderBy(.createdAt, .asc)
        .all(in: db)
        .map { album in
          LibrarySnapshotCompiler.AlbumGrant(
            appleMusicAlbumId: album.appleMusicAlbumId,
            createdAt: album.createdAt,
            showsArtwork: album.showsArtwork,
            resolution: album.resolution,
          )
        }
      let artistGrants = try await ApprovedArtist.query()
        .where(.childId == childId)
        .orderBy(.createdAt, .asc)
        .all(in: db)
        .map { artist in
          LibrarySnapshotCompiler.ArtistGrant(
            appleMusicArtistId: artist.appleMusicArtistId,
            createdAt: artist.createdAt,
            resolution: artist.resolution,
          )
        }
      let content = try LibrarySnapshotCompiler.compile(
        albumGrants: albumGrants,
        artistGrants: artistGrants,
      )
      let existing = try await self.snapshot(for: childId, in: db)
      if let existing,
         existing.revision == existing.payload.revision,
         existing.payload.hasSameContent(as: content) {
        return existing
      }

      let revision = (existing?.revision ?? 0) + 1
      let payload = content.snapshot(revision: revision, generatedAt: generatedAt)
      let snapshot = LibrarySnapshot(
        childId: childId,
        revision: revision,
        payload: payload,
        createdAt: generatedAt,
      )
      return try await db.upsert(
        snapshot,
        conflictOn: [.childId],
        do: .update(set: [.revision, .payload, .createdAt]),
      )
    }
  }
}
