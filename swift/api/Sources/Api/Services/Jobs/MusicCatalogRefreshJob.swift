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
    var summary = Summary()
    do {
      let albums = try await Music.ApprovedAlbum.query()
        .orderBy(.createdAt, .asc)
        .all(in: self.db)
        .filter { filter?.contains($0.childId) ?? true }
      let artists = try await Music.ApprovedArtist.query()
        .orderBy(.createdAt, .asc)
        .all(in: self.db)
        .filter { filter?.contains($0.childId) ?? true }
      let tracks = try await Music.ApprovedTrack.query()
        .orderBy(.createdAt, .asc)
        .all(in: self.db)
        .filter { filter?.contains($0.childId) ?? true }

      let albumIds = Set(albums.map(\.appleMusicAlbumId) + tracks.map(\.preferredAlbumId))
      var albumResolutions: [Music.AlbumId: Music.ResolvedAlbum] = [:]
      var failedAlbumIds = Set<Music.AlbumId>()
      for albumId in albumIds.sorted(by: { $0.rawValue < $1.rawValue }) {
        do {
          let resolution = try await self.appleMusic.resolveAlbum(albumId)
          guard resolution.id == albumId else {
            throw Music.LibrarySnapshotCompiler.CompilerError.albumResolutionIdMismatch(
              expected: albumId,
              actual: resolution.id,
            )
          }
          albumResolutions[albumId] = resolution
        } catch {
          failedAlbumIds.insert(albumId)
          self.logger.error(
            "Apple Music refresh failed for album `\(albumId.rawValue)`: \(error)",
          )
        }
      }

      let artistIds = Set(artists.map(\.appleMusicArtistId))
      var artistResolutions: [Music.ArtistId: Music.ResolvedArtist] = [:]
      var failedArtistIds = Set<Music.ArtistId>()
      for artistId in artistIds.sorted(by: { $0.rawValue < $1.rawValue }) {
        do {
          let resolution = try await self.appleMusic.resolveArtist(artistId)
          guard resolution.id == artistId else {
            throw Music.LibrarySnapshotCompiler.CompilerError.artistResolutionIdMismatch(
              expected: artistId,
              actual: resolution.id,
            )
          }
          artistResolutions[artistId] = resolution
        } catch {
          failedArtistIds.insert(artistId)
          self.logger.error(
            "Apple Music refresh failed for artist `\(artistId.rawValue)`: \(error)",
          )
        }
      }

      let affectedChildIds = Set(
        albums.map(\.childId) + artists.map(\.childId) + tracks.map(\.childId),
      )
      for childId in affectedChildIds.sorted(by: {
        $0.rawValue.uuidString < $1.rawValue.uuidString
      }) {
        do {
          let delta = try await self.refreshChild(
            childId,
            albumResolutions: albumResolutions,
            failedAlbumIds: failedAlbumIds,
            artistResolutions: artistResolutions,
            failedArtistIds: failedArtistIds,
          )
          summary.merge(delta)
        } catch {
          summary.failures += 1
          self.logger.error(
            "Persisting Apple Music refresh failed for child `\(childId)`: \(error)",
          )
        }
      }
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
      var summary = Summary()
      var changed = false
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
        changed = true
      }

      policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
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
        changed = deleted > 0 || changed
      }
      if !coveredTrackIds.isEmpty {
        let deleted = try await Music.ApprovedTrack.query()
          .where(.childId == childId)
          .where(.appleMusicTrackId |=| coveredTrackIds.map(\.rawValue))
          .delete(in: db)
        summary.normalizedTracks += deleted
        changed = deleted > 0 || changed
      }

      policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
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
        changed = true
      }

      policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
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
        changed = deleted > 0 || changed
      }

      policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
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
        changed = true
      }

      if changed {
        _ = try await Music.LibrarySnapshotRepository.publishAfterPolicyChange(
          childId: childId,
          generatedAt: self.now,
          in: db,
        )
      }
      return summary
    }
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
