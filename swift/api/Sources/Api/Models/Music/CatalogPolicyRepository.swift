import DuetSQL

extension Music.CatalogPolicy {
  struct StoredPolicy: Sendable {
    var albums: [Music.ApprovedAlbum]
    var artists: [Music.ApprovedArtist]
    var tracks: [Music.ApprovedTrack]
    var coverage: CoverageIndex

    init(
      albums: [Music.ApprovedAlbum],
      artists: [Music.ApprovedArtist],
      tracks: [Music.ApprovedTrack],
    ) throws {
      self.albums = albums
      self.artists = artists
      self.tracks = tracks
      self.coverage = try CoverageIndex(
        artistGrants: artists.map {
          .init(
            appleMusicArtistId: $0.appleMusicArtistId,
            resolution: $0.resolution,
          )
        },
        albumGrants: albums.map {
          .init(
            appleMusicAlbumId: $0.appleMusicAlbumId,
            resolution: $0.resolution,
          )
        },
        trackGrants: tracks.map {
          .init(
            appleMusicTrackId: $0.appleMusicTrackId,
            preferredAlbumId: $0.preferredAlbumId,
            resolution: $0.resolution,
          )
        },
      )
    }

    func album(_ id: Music.AlbumId) -> Music.ApprovedAlbum? {
      self.albums.first { $0.appleMusicAlbumId == id }
    }

    func artist(_ id: Music.ArtistId) -> Music.ApprovedArtist? {
      self.artists.first { $0.appleMusicArtistId == id }
    }

    func track(_ id: Music.TrackId) -> Music.ApprovedTrack? {
      self.tracks.first { $0.appleMusicTrackId == id }
    }

    func tracks(preferredAlbumId: Music.AlbumId) -> [Music.ApprovedTrack] {
      self.tracks.filter { $0.preferredAlbumId == preferredAlbumId }
    }

    func artworkSetting(for albumId: Music.AlbumId) -> Bool {
      if let album = self.album(albumId) {
        return album.showsArtwork
      }
      return self.tracks(preferredAlbumId: albumId)
        .min(by: Self.trackOrder)?
        .showsArtwork ?? true
    }

    private static func trackOrder(
      _ lhs: Music.ApprovedTrack,
      _ rhs: Music.ApprovedTrack,
    ) -> Bool {
      if lhs.createdAt != rhs.createdAt {
        return lhs.createdAt < rhs.createdAt
      }
      return lhs.id.rawValue.uuidString < rhs.id.rawValue.uuidString
    }
  }

  static func load(
    childId: Child.Id,
    in db: any DuetSQL.Client,
  ) async throws -> StoredPolicy {
    let albums = try await Music.ApprovedAlbum.query()
      .where(.childId == childId)
      .orderBy(.createdAt, .asc)
      .all(in: db)
    let artists = try await Music.ApprovedArtist.query()
      .where(.childId == childId)
      .orderBy(.createdAt, .asc)
      .all(in: db)
    let tracks = try await Music.ApprovedTrack.query()
      .where(.childId == childId)
      .orderBy(.createdAt, .asc)
      .all(in: db)
    return try .init(albums: albums, artists: artists, tracks: tracks)
  }

  static func applyAlbumSelection(
    _ plan: AlbumSelectionPlan,
    childId: Child.Id,
    album: Music.ResolvedAlbum,
    policy: StoredPolicy,
    resolvedAt: Date,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    switch plan {
    case .coveredByArtist:
      return false

    case .removeDirectAuthorization:
      let deletedAlbum = try await Music.ApprovedAlbum.query()
        .where(.childId == childId)
        .where(.appleMusicAlbumId == album.id.rawValue)
        .delete(in: db)
      let deletedTracks = try await Music.ApprovedTrack.query()
        .where(.childId == childId)
        .where(.preferredAlbumId == album.id.rawValue)
        .delete(in: db)
      return deletedAlbum + deletedTracks > 0

    case .replaceWithTrackGrants(let grants):
      var changed = try await Music.ApprovedAlbum.query()
        .where(.childId == childId)
        .where(.appleMusicAlbumId == album.id.rawValue)
        .delete(in: db) > 0
      let directGrants = grants.filter { grant in
        switch policy.coverage.governingGrant(
          forTrack: grant.track.id,
          preferredAlbumId: album.id,
        ) {
        case .artist?:
          false
        case .album(let covering)?:
          covering.appleMusicAlbumId == album.id
        case .track?, nil:
          true
        }
      }
      let desiredTrackIds = Set(directGrants.map(\.track.id))
      let obsoleteTrackIds = policy.tracks(preferredAlbumId: album.id)
        .filter { !desiredTrackIds.contains($0.appleMusicTrackId) }
        .map(\.appleMusicTrackId)
      if !obsoleteTrackIds.isEmpty {
        changed = try await Music.ApprovedTrack.query()
          .where(.childId == childId)
          .where(.appleMusicTrackId |=| obsoleteTrackIds.map(\.rawValue))
          .delete(in: db) > 0 || changed
      }
      let showsArtwork = policy.artworkSetting(for: album.id)
      for grant in directGrants {
        changed = try await self.upsertTrack(
          childId: childId,
          resolution: grant,
          showsArtwork: showsArtwork,
          resolvedAt: resolvedAt,
          existing: policy.track(grant.track.id),
          in: db,
        ) || changed
      }
      return changed

    case .replaceWithAlbumGrant(let resolution):
      var changed = false
      let coveredTrackIds = try policy.coverage.directTrackIdsCovered(by: resolution)
        .union(policy.tracks(preferredAlbumId: resolution.id).map(\.appleMusicTrackId))
      if !coveredTrackIds.isEmpty {
        changed = try await Music.ApprovedTrack.query()
          .where(.childId == childId)
          .where(.appleMusicTrackId |=| coveredTrackIds.map(\.rawValue))
          .delete(in: db) > 0
      }
      return try await self.upsertAlbum(
        childId: childId,
        resolution: resolution,
        showsArtwork: policy.artworkSetting(for: album.id),
        resolvedAt: resolvedAt,
        existing: policy.album(album.id),
        in: db,
      ) || changed
    }
  }

  static func addAlbum(
    childId: Child.Id,
    resolution: Music.ResolvedAlbum,
    showsArtwork: Bool? = nil,
    policy: StoredPolicy,
    resolvedAt: Date,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    if case .artist? = policy.coverage.governingGrant(forAlbum: resolution.id) {
      return false
    }
    var changed = false
    let coveredTrackIds = try policy.coverage.directTrackIdsCovered(by: resolution)
      .union(policy.tracks(preferredAlbumId: resolution.id).map(\.appleMusicTrackId))
    if !coveredTrackIds.isEmpty {
      changed = try await Music.ApprovedTrack.query()
        .where(.childId == childId)
        .where(.appleMusicTrackId |=| coveredTrackIds.map(\.rawValue))
        .delete(in: db) > 0
    }
    return try await self.upsertAlbum(
      childId: childId,
      resolution: resolution,
      showsArtwork: showsArtwork ?? policy.artworkSetting(for: resolution.id),
      resolvedAt: resolvedAt,
      existing: policy.album(resolution.id),
      in: db,
    ) || changed
  }

  static func addTrack(
    childId: Child.Id,
    resolution: AppleMusicTrackResolution,
    policy: StoredPolicy,
    resolvedAt: Date,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    let grant = resolution.grant
    switch policy.coverage.governingGrant(forAlbum: grant.preferredAlbum.id) {
    case .artist?, .album?:
      return false
    case .track?, nil:
      break
    }
    switch policy.coverage.governingGrant(
      forTrack: grant.track.id,
      preferredAlbumId: grant.preferredAlbum.id,
    ) {
    case .artist?, .album?:
      return false
    case .track?, nil:
      break
    }
    let selectedTrackIds = policy.tracks(preferredAlbumId: grant.preferredAlbum.id)
      .map(\.appleMusicTrackId) + [grant.track.id]
    let plan = try policy.coverage.planAlbumSelection(
      for: resolution.album,
      selectedTrackIds: selectedTrackIds,
    )
    return try await self.applyAlbumSelection(
      plan,
      childId: childId,
      album: resolution.album,
      policy: policy,
      resolvedAt: resolvedAt,
      in: db,
    )
  }

  static func addArtist(
    childId: Child.Id,
    resolution: Music.ResolvedArtist,
    policy: StoredPolicy,
    resolvedAt: Date,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    let covered = try policy.coverage.directGrantsCovered(by: resolution)
    var changed = false
    if !covered.albumIds.isEmpty {
      changed = try await Music.ApprovedAlbum.query()
        .where(.childId == childId)
        .where(.appleMusicAlbumId |=| covered.albumIds.map(\.rawValue))
        .delete(in: db) > 0
    }
    if !covered.trackIds.isEmpty {
      changed = try await Music.ApprovedTrack.query()
        .where(.childId == childId)
        .where(.appleMusicTrackId |=| covered.trackIds.map(\.rawValue))
        .delete(in: db) > 0 || changed
    }
    return try await self.upsertArtist(
      childId: childId,
      resolution: resolution,
      resolvedAt: resolvedAt,
      existing: policy.artist(resolution.id),
      in: db,
    ) || changed
  }

  static func removeArtist(
    _ artist: Music.ApprovedArtist,
    policy: StoredPolicy,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    let covered = try policy.coverage.directGrantsCovered(by: artist.resolution)
    if !covered.albumIds.isEmpty {
      _ = try await Music.ApprovedAlbum.query()
        .where(.childId == artist.childId)
        .where(.appleMusicAlbumId |=| covered.albumIds.map(\.rawValue))
        .delete(in: db)
    }
    if !covered.trackIds.isEmpty {
      _ = try await Music.ApprovedTrack.query()
        .where(.childId == artist.childId)
        .where(.appleMusicTrackId |=| covered.trackIds.map(\.rawValue))
        .delete(in: db)
    }
    return try await Music.ApprovedArtist.query()
      .where(.id == artist.id)
      .delete(in: db) > 0
  }

  private static func upsertAlbum(
    childId: Child.Id,
    resolution: Music.ResolvedAlbum,
    showsArtwork: Bool,
    resolvedAt: Date,
    existing: Music.ApprovedAlbum?,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    if let existing,
       existing.title == resolution.title,
       existing.artistName == resolution.artistName,
       existing.artworkUrl == resolution.artworkUrl,
       existing.artwork == resolution.artwork,
       existing.trackCount == resolution.trackCount,
       existing.showsArtwork == showsArtwork,
       existing.resolution == resolution {
      return false
    }
    _ = try await db.upsert(
      Music.ApprovedAlbum(
        childId: childId,
        appleMusicAlbumId: resolution.id,
        title: resolution.title,
        artistName: resolution.artistName,
        artworkUrl: resolution.artworkUrl,
        artwork: resolution.artwork,
        trackCount: resolution.trackCount,
        showsArtwork: showsArtwork,
        resolution: resolution,
        resolvedAt: resolvedAt,
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
    return true
  }

  private static func upsertTrack(
    childId: Child.Id,
    resolution: Music.ResolvedTrackGrant,
    showsArtwork: Bool,
    resolvedAt: Date,
    existing: Music.ApprovedTrack?,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    if let existing,
       existing.preferredAlbumId == resolution.preferredAlbum.id,
       existing.resolution == resolution,
       existing.showsArtwork == showsArtwork {
      return false
    }
    _ = try await db.upsert(
      Music.ApprovedTrack(
        childId: childId,
        appleMusicTrackId: resolution.track.id,
        preferredAlbumId: resolution.preferredAlbum.id,
        resolution: resolution,
        showsArtwork: showsArtwork,
        resolvedAt: resolvedAt,
      ),
      conflictOn: [.childId, .appleMusicTrackId],
      do: .update(set: [
        .preferredAlbumId,
        .resolution,
        .showsArtwork,
        .resolvedAt,
      ]),
    )
    return true
  }

  private static func upsertArtist(
    childId: Child.Id,
    resolution: Music.ResolvedArtist,
    resolvedAt: Date,
    existing: Music.ApprovedArtist?,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    if let existing,
       existing.name == resolution.name,
       existing.catalogMetadata == resolution.catalogMetadata,
       existing.resolution == resolution {
      return false
    }
    _ = try await db.upsert(
      Music.ApprovedArtist(
        childId: childId,
        appleMusicArtistId: resolution.id,
        name: resolution.name,
        catalogMetadata: resolution.catalogMetadata,
        resolution: resolution,
        resolvedAt: resolvedAt,
      ),
      conflictOn: [.childId, .appleMusicArtistId],
      do: .update(set: [
        .name,
        .catalogMetadata,
        .resolution,
        .resolvedAt,
      ]),
    )
    return true
  }
}
