import Dependencies
import DuetSQL
import Queues
import Vapor

struct MusicCatalogRefreshJob: AsyncScheduledJob {
  struct Summary: Equatable, Sendable {
    var refreshedAlbums = 0
    var refreshedArtists = 0
    var refreshedTracks = 0
    var unchangedAlbums = 0
    var unchangedArtists = 0
    var unchangedTracks = 0
    var normalizedAlbums = 0
    var normalizedTracks = 0
    var failures = 0

    var hasChanges: Bool {
      self.refreshedAlbums > 0 || self.refreshedArtists > 0 || self.refreshedTracks > 0
        || self.normalizedAlbums > 0 || self.normalizedTracks > 0
    }

    mutating func merge(_ other: Self) {
      self.refreshedAlbums += other.refreshedAlbums
      self.refreshedArtists += other.refreshedArtists
      self.refreshedTracks += other.refreshedTracks
      self.unchangedAlbums += other.unchangedAlbums
      self.unchangedArtists += other.unchangedArtists
      self.unchangedTracks += other.unchangedTracks
      self.normalizedAlbums += other.normalizedAlbums
      self.normalizedTracks += other.normalizedTracks
      self.failures += other.failures
    }
  }

  @Dependency(\.appleMusic) var appleMusic
  @Dependency(\.date.now) var now
  @Dependency(\.db) var db
  @Dependency(\.env) var env
  @Dependency(\.logger) var logger

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    _ = await self.exec()
  }

  func exec(childIds filter: Set<Child.Id>? = nil) async -> Summary {
    guard filter?.isEmpty != true else { return Summary() }
    var summary = Summary()
    do {
      let grants = try await self.db.customQuery(
        MusicRefreshGrantReference.self,
        withBindings: filter?.map { .uuid($0) },
      )
      let affectedChildIds = Set(grants.map(\.childId))
      let storefronts = try await Child.query()
        .where(.id |=| Array(affectedChildIds))
        .all(in: self.db)
        .reduce(into: [Child.Id: Music.Storefront]()) { $0[$1.id] = $1.appleMusicStorefront }

      let targets = Dictionary(grouping: grants, by: \.childId).map { childId, grants in
        MusicRefreshTargets(
          childId: childId,
          storefront: storefronts[childId] ?? .default,
          albumIds: Set(grants.compactMap(\.albumId)),
          artistIds: Set(grants.compactMap(\.artistId)),
        )
      }.sorted { $0.childId.rawValue.uuidString < $1.childId.rawValue.uuidString }
      var remainingAlbumUses: [Music.Storefront: [Music.AlbumId: Int]] = [:]
      var remainingArtistUses: [Music.Storefront: [Music.ArtistId: Int]] = [:]
      for target in targets {
        for albumId in target.albumIds {
          remainingAlbumUses[target.storefront, default: [:]][albumId, default: 0] += 1
        }
        for artistId in target.artistIds {
          remainingArtistUses[target.storefront, default: [:]][artistId, default: 0] += 1
        }
      }
      var albumResolutions: [Music.Storefront: [Music.AlbumId: Music.ResolvedAlbum]] = [:]
      var artistResolutions: [Music.Storefront: [Music.ArtistId: Music.ResolvedArtist]] = [:]
      var failedAlbumIds: [Music.Storefront: Set<Music.AlbumId>] = [:]
      var failedArtistIds: [Music.Storefront: Set<Music.ArtistId>] = [:]
      self.logger.info("Apple Music catalog refresh started for \(targets.count) children")

      for target in targets {
        let storefront = target.storefront
        for albumId in target.albumIds.sorted(by: { $0.rawValue < $1.rawValue }) {
          guard albumResolutions[storefront]?[albumId] == nil,
                failedAlbumIds[storefront]?.contains(albumId) != true else { continue }
          do {
            let resolution = try await self.appleMusic.resolveAlbum(.init(
              storefront: storefront,
              albumId: albumId,
            ))
            guard resolution.id == albumId else {
              throw Music.LibrarySnapshotCompiler.CompilerError.albumResolutionIdMismatch(
                expected: albumId,
                actual: resolution.id,
              )
            }
            albumResolutions[storefront, default: [:]][albumId] = resolution
          } catch {
            failedAlbumIds[storefront, default: []].insert(albumId)
            self.logger.error(
              "Apple Music refresh failed for album `\(albumId.rawValue)` in storefront `\(storefront.rawValue)`: \(error)",
            )
          }
        }
        for artistId in target.artistIds.sorted(by: { $0.rawValue < $1.rawValue }) {
          guard artistResolutions[storefront]?[artistId] == nil,
                failedArtistIds[storefront]?.contains(artistId) != true else { continue }
          do {
            let resolution = try await self.appleMusic.resolveArtist(.init(
              storefront: storefront,
              artistId: artistId,
            ))
            guard resolution.id == artistId else {
              throw Music.LibrarySnapshotCompiler.CompilerError.artistResolutionIdMismatch(
                expected: artistId,
                actual: resolution.id,
              )
            }
            artistResolutions[storefront, default: [:]][artistId] = resolution
          } catch {
            failedArtistIds[storefront, default: []].insert(artistId)
            self.logger.error(
              "Apple Music refresh failed for artist `\(artistId.rawValue)` in storefront `\(storefront.rawValue)`: \(error)",
            )
          }
        }
        do {
          let delta = try await self.refreshChild(
            target.childId,
            albumResolutions: albumResolutions[storefront] ?? [:],
            failedAlbumIds: failedAlbumIds[storefront] ?? [],
            artistResolutions: artistResolutions[storefront] ?? [:],
            failedArtistIds: failedArtistIds[storefront] ?? [],
          )
          summary.merge(delta)
        } catch {
          summary.failures += 1
          self.logger.error(
            "Persisting Apple Music refresh failed for child `\(target.childId)`: \(error)",
          )
        }
        for albumId in target.albumIds {
          remainingAlbumUses[storefront, default: [:]][albumId, default: 0] -= 1
          if remainingAlbumUses[storefront]?[albumId] == 0 {
            albumResolutions[storefront]?[albumId] = nil
          }
        }
        for artistId in target.artistIds {
          remainingArtistUses[storefront, default: [:]][artistId, default: 0] -= 1
          if remainingArtistUses[storefront]?[artistId] == 0 {
            artistResolutions[storefront]?[artistId] = nil
          }
        }
      }
      self.logger.info("Apple Music catalog refresh completed: \(summary)")
    } catch {
      summary.failures += 1
      self.logger.error("Loading music grants for catalog refresh failed: \(error)")
    }
    return summary
  }

  private func refreshChild(
    _ childId: Child.Id,
    albumResolutions: [Music.AlbumId: Music.ResolvedAlbum],
    failedAlbumIds: Set<Music.AlbumId>,
    artistResolutions: [Music.ArtistId: Music.ResolvedArtist],
    failedArtistIds: Set<Music.ArtistId>,
  ) async throws -> Summary {
    try await self.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: childId, in: db)
      let summary = try await self.refreshPolicy(
        childId,
        albumResolutions: albumResolutions,
        failedAlbumIds: failedAlbumIds,
        artistResolutions: artistResolutions,
        failedArtistIds: failedArtistIds,
        in: db,
      )
      if summary.hasChanges {
        _ = try await Music.LibrarySnapshotRepository.publishAfterPolicyChange(
          childId: childId,
          generatedAt: self.now,
          in: db,
        )
      }
      return summary
    }
  }

  private func refreshPolicy(
    _ childId: Child.Id,
    albumResolutions: [Music.AlbumId: Music.ResolvedAlbum],
    failedAlbumIds: Set<Music.AlbumId>,
    artistResolutions: [Music.ArtistId: Music.ResolvedArtist],
    failedArtistIds: Set<Music.ArtistId>,
    in db: any DuetSQL.Client,
  ) async throws -> Summary {
    var summary = Summary()
    var policy = try await Music.CatalogPolicy.load(childId: childId, in: db)

    for var artist in policy.artists {
      if failedArtistIds.contains(artist.appleMusicArtistId) {
        summary.failures += 1
        continue
      }
      guard let resolution = artistResolutions[artist.appleMusicArtistId] else { continue }
      if self.artistMatches(artist, resolution: resolution) {
        summary.unchangedArtists += 1
        continue
      }
      artist.name = resolution.name
      artist.catalogMetadata = resolution.catalogMetadata
      artist.resolution = resolution
      artist.resolvedAt = self.now
      try await db.update(artist)
      summary.refreshedArtists += 1
    }

    if summary.refreshedArtists > 0 {
      policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
    }
    var coveredAlbumIds = Set<Music.AlbumId>()
    var coveredTrackIds = Set<Music.TrackId>()
    for artist in policy.artists {
      let covered = try policy.coverage.directGrantsCovered(by: artist.resolution)
      coveredAlbumIds.formUnion(covered.albumIds)
      coveredTrackIds.formUnion(covered.trackIds)
    }
    if !coveredAlbumIds.isEmpty {
      let deleted = try await Music.ApprovedAlbum.query()
        .where(.childId == childId)
        .where(.appleMusicAlbumId |=| coveredAlbumIds.map(\.rawValue))
        .delete(in: db)
      summary.normalizedAlbums += deleted
    }
    if !coveredTrackIds.isEmpty {
      let deleted = try await Music.ApprovedTrack.query()
        .where(.childId == childId)
        .where(.appleMusicTrackId |=| coveredTrackIds.map(\.rawValue))
        .delete(in: db)
      summary.normalizedTracks += deleted
    }

    if summary.normalizedAlbums + summary.normalizedTracks > 0 {
      policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
    }
    for var album in policy.albums {
      if failedAlbumIds.contains(album.appleMusicAlbumId) {
        summary.failures += 1
        continue
      }
      guard let resolution = albumResolutions[album.appleMusicAlbumId] else { continue }
      if self.albumMatches(album, resolution: resolution) {
        summary.unchangedAlbums += 1
        continue
      }
      album.title = resolution.title
      album.artistName = resolution.artistName
      album.artworkUrl = resolution.artworkUrl
      album.artwork = resolution.artwork
      album.trackCount = resolution.trackCount
      album.resolution = resolution
      album.resolvedAt = self.now
      try await db.update(album)
      summary.refreshedAlbums += 1
    }

    if summary.refreshedAlbums > 0 {
      policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
    }
    var albumCoveredTrackIds = Set<Music.TrackId>()
    for album in policy.albums {
      try albumCoveredTrackIds.formUnion(
        policy.coverage.directTrackIdsCovered(by: album.resolution),
      )
      albumCoveredTrackIds.formUnion(
        policy.tracks(preferredAlbumId: album.appleMusicAlbumId).map(\.appleMusicTrackId),
      )
    }
    if !albumCoveredTrackIds.isEmpty {
      let deleted = try await Music.ApprovedTrack.query()
        .where(.childId == childId)
        .where(.appleMusicTrackId |=| albumCoveredTrackIds.map(\.rawValue))
        .delete(in: db)
      summary.normalizedTracks += deleted
      if deleted > 0 {
        policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
      }
    }

    for var track in policy.tracks {
      if failedAlbumIds.contains(track.preferredAlbumId) {
        summary.failures += 1
        continue
      }
      guard let album = albumResolutions[track.preferredAlbumId] else { continue }
      guard let position = album.tracks.firstIndex(where: {
        $0.id == track.appleMusicTrackId
      }) else {
        summary.failures += 1
        self.logger.error(
          "Apple Music album `\(album.id.rawValue)` no longer contains selected track `\(track.appleMusicTrackId.rawValue)`",
        )
        continue
      }
      let resolution = album.trackGrant(at: position)
      try resolution.validate(
        appleMusicTrackId: track.appleMusicTrackId,
        preferredAlbumId: track.preferredAlbumId,
      )
      if track.resolution == resolution {
        summary.unchangedTracks += 1
        continue
      }
      track.resolution = resolution
      track.resolvedAt = self.now
      try await db.update(track)
      summary.refreshedTracks += 1
    }

    return summary
  }

  private func albumMatches(
    _ album: Music.ApprovedAlbum,
    resolution: Music.ResolvedAlbum,
  ) -> Bool {
    album.title == resolution.title
      && album.artistName == resolution.artistName
      && album.artworkUrl == resolution.artworkUrl
      && album.artwork == resolution.artwork
      && album.trackCount == resolution.trackCount
      && album.resolution == resolution
  }

  private func artistMatches(
    _ artist: Music.ApprovedArtist,
    resolution: Music.ResolvedArtist,
  ) -> Bool {
    artist.name == resolution.name
      && artist.catalogMetadata == resolution.catalogMetadata
      && artist.resolution == resolution
  }
}

private struct MusicRefreshTargets {
  var childId: Child.Id
  var storefront: Music.Storefront
  var albumIds: Set<Music.AlbumId>
  var artistIds: Set<Music.ArtistId>
}

private struct MusicRefreshGrantReference: CustomQueryable {
  var childId: Child.Id
  var albumId: Music.AlbumId?
  var artistId: Music.ArtistId?

  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var statement = SQL.Statement("""
    SELECT child_id, album_id, artist_id FROM (
      SELECT child_id, apple_music_album_id AS album_id, NULL::text AS artist_id
      FROM \(table: Music.ApprovedAlbum.self)
      UNION ALL
      SELECT child_id, preferred_album_id AS album_id, NULL::text AS artist_id
      FROM \(table: Music.ApprovedTrack.self)
      UNION ALL
      SELECT child_id, NULL::text AS album_id, apple_music_artist_id AS artist_id
      FROM \(table: Music.ApprovedArtist.self)
    ) grants
    """)
    if !bindings.isEmpty {
      statement.components.append(.sql(" WHERE child_id IN ("))
      for (index, binding) in bindings.enumerated() {
        if index > 0 { statement.components.append(.sql(", ")) }
        statement.components.append(.binding(binding))
      }
      statement.components.append(.sql(")"))
    }
    return statement
  }
}
