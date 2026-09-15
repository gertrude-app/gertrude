import DuetSQL
import Foundation

extension Music {
  enum LibrarySnapshotRepository {
    static func lock(
      childId: Child.Id,
      in db: any DuetSQL.Client,
    ) async throws {
      try await db.execute(raw: """
        SELECT \(col: Child.columnName(.id))
        FROM \(table: Child.self)
        WHERE \(col: Child.columnName(.id)) = '\(id: childId)'
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

    static func catalogContent(
      for childId: Child.Id,
      in db: any DuetSQL.Client,
    ) async throws -> LibrarySnapshotCompiler.Content {
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
      let trackGrants = try await ApprovedTrack.query()
        .where(.childId == childId)
        .orderBy(.createdAt, .asc)
        .all(in: db)
        .map { track in
          LibrarySnapshotCompiler.TrackGrant(
            appleMusicTrackId: track.appleMusicTrackId,
            preferredAlbumId: track.preferredAlbumId,
            createdAt: track.createdAt,
            showsArtwork: track.showsArtwork,
            resolution: track.resolution,
          )
        }
      return try LibrarySnapshotCompiler.compile(
        albumGrants: albumGrants,
        artistGrants: artistGrants,
        trackGrants: trackGrants,
      )
    }

    @discardableResult
    static func publish(
      childId: Child.Id,
      generatedAt: Date,
      in db: any DuetSQL.Client,
    ) async throws -> LibrarySnapshot {
      try await self.publish(
        childId: childId,
        generatedAt: generatedAt,
        publication: .ifContentChanged,
        in: db,
      )
    }

    @discardableResult
    static func publish(
      childId: Child.Id,
      policyChanged: Bool,
      generatedAt: Date,
      in db: any DuetSQL.Client,
    ) async throws -> LibrarySnapshot {
      try await self.publish(
        childId: childId,
        generatedAt: generatedAt,
        publication: policyChanged ? .afterPolicyChange : .ifContentChanged,
        in: db,
      )
    }

    @discardableResult
    static func publishAfterPolicyChange(
      childId: Child.Id,
      generatedAt: Date,
      in db: any DuetSQL.Client,
    ) async throws -> LibrarySnapshot {
      try await self.publish(
        childId: childId,
        generatedAt: generatedAt,
        publication: .afterPolicyChange,
        in: db,
      )
    }

    private enum Publication {
      case ifContentChanged
      case afterPolicyChange
    }

    private struct PersistedFields: Decodable, Sendable {
      var id: LibrarySnapshot.Id
      var createdAt: Date
    }

    private static func publish(
      childId: Child.Id,
      generatedAt: Date,
      publication: Publication,
      in db: any DuetSQL.Client,
    ) async throws -> LibrarySnapshot {
      var content = try await self.catalogContent(for: childId, in: db)
      let index = PlaylistRules.EffectiveTrackIndex(albums: content.albums)
      let playlists = try await PlaylistRepository.reconcileForPublication(
        childId: childId,
        using: index,
        at: generatedAt,
        in: db,
      )
      content.playlists = PlaylistRules.compile(playlists: playlists, using: index)
      let previousRevision: Int64
      switch publication {
      case .ifContentChanged:
        let existing = try await self.snapshot(for: childId, in: db)
        if let existing,
           existing.revision == existing.payload.revision,
           existing.payload.hasSameContent(as: content) {
          return existing
        }
        previousRevision = existing?.revision ?? 0
      case .afterPolicyChange:
        let rows = try await db.execute(raw: """
          SELECT \(col: LibrarySnapshot.columnName(.revision))
          FROM \(table: LibrarySnapshot.self)
          WHERE \(col: LibrarySnapshot.columnName(.childId)) = '\(id: childId)';
        """)
        previousRevision = try rows.first?.decode(
          column: LibrarySnapshot.columnName(.revision),
          as: Int64.self,
        ) ?? 0
      }

      let revision = previousRevision + 1
      let payload = content.snapshot(revision: revision, generatedAt: generatedAt)
      var snapshot = LibrarySnapshot(
        childId: childId,
        revision: revision,
        payload: payload,
        createdAt: generatedAt,
      )
      let rows = try await db.upsert(
        [snapshot],
        conflictOn: [.childId],
        do: .update(set: [.revision, .payload, .createdAt]),
        returning: [.id, .createdAt],
        as: PersistedFields.self,
      )
      guard let persisted = rows.first else {
        throw DuetSQLError.notFound("LibrarySnapshot")
      }
      snapshot.id = persisted.id
      snapshot.createdAt = persisted.createdAt
      return snapshot
    }
  }
}
