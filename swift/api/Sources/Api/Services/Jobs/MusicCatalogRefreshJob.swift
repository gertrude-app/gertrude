import Dependencies
import DuetSQL
import Queues
import Vapor

struct MusicCatalogRefreshJob: AsyncScheduledJob {
  struct Summary: Equatable, Sendable {
    var refreshedAlbums = 0
    var refreshedArtists = 0
    var unchangedAlbums = 0
    var unchangedArtists = 0
    var failures = 0
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

  func exec(childIds: Set<Child.Id>? = nil) async -> Summary {
    var summary = Summary()
    do {
      let albums = try await Music.ApprovedAlbum.query()
        .orderBy(.createdAt, .asc)
        .all(in: self.db)
        .filter { childIds?.contains($0.childId) ?? true }
      let albumsById = Dictionary(grouping: albums, by: \.appleMusicAlbumId)
      for albumId in albumsById.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
        let resolution: Music.ResolvedAlbum
        do {
          resolution = try await self.appleMusic.resolveAlbum(albumId)
        } catch {
          summary.failures += albumsById[albumId]?.count ?? 0
          self.logger.error(
            "Apple Music refresh failed for album `\(albumId.rawValue)`: \(error)",
          )
          continue
        }

        for album in albumsById[albumId] ?? [] {
          if let existing = album.resolution,
             !self.albumContentChanged(album, from: existing, to: resolution) {
            summary.unchangedAlbums += 1
            continue
          }
          do {
            let refreshed = try await self.refresh(album: album, resolution: resolution)
            if refreshed {
              summary.refreshedAlbums += 1
            } else {
              summary.unchangedAlbums += 1
            }
          } catch {
            summary.failures += 1
            self.logger.error(
              "Persisting Apple Music refresh failed for album grant `\(album.id)`: \(error)",
            )
          }
        }
      }

      let artists = try await Music.ApprovedArtist.query()
        .orderBy(.createdAt, .asc)
        .all(in: self.db)
        .filter { childIds?.contains($0.childId) ?? true }
      let artistsById = Dictionary(grouping: artists, by: \.appleMusicArtistId)
      for artistId in artistsById.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
        let resolution: Music.ResolvedArtist
        do {
          resolution = try await self.appleMusic.resolveArtist(artistId)
        } catch {
          summary.failures += artistsById[artistId]?.count ?? 0
          self.logger.error(
            "Apple Music refresh failed for artist `\(artistId.rawValue)`: \(error)",
          )
          continue
        }

        for artist in artistsById[artistId] ?? [] {
          if let existing = artist.resolution,
             !self.artistContentChanged(artist, from: existing, to: resolution) {
            summary.unchangedArtists += 1
            continue
          }
          do {
            let refreshed = try await self.refresh(artist: artist, resolution: resolution)
            if refreshed {
              summary.refreshedArtists += 1
            } else {
              summary.unchangedArtists += 1
            }
          } catch {
            summary.failures += 1
            self.logger.error(
              "Persisting Apple Music refresh failed for artist grant `\(artist.id)`: \(error)",
            )
          }
        }
      }
    } catch {
      summary.failures += 1
      self.logger.error("Loading music grants for catalog refresh failed: \(error)")
    }
    return summary
  }

  private func refresh(
    album: Music.ApprovedAlbum,
    resolution: Music.ResolvedAlbum,
  ) async throws -> Bool {
    try await self.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: album.childId, in: db)
      let current = try await Music.ApprovedAlbum.query()
        .where(.id == album.id)
        .all(in: db)
        .first
      guard var current else { return false }
      guard try await self.childContentChanged(album: current, to: resolution, in: db) else {
        return false
      }
      current.title = resolution.title
      current.artistName = resolution.artistName
      current.artworkUrl = resolution.artworkUrl
      current.artwork = resolution.artwork
      current.trackCount = resolution.trackCount
      current.resolution = resolution
      current.resolvedAt = self.now
      try await db.update(current)
      try await Music.LibrarySnapshotRepository.publish(
        childId: current.childId,
        generatedAt: self.now,
        in: db,
      )
      return true
    }
  }

  private func albumContentChanged(
    _ album: Music.ApprovedAlbum,
    from existing: Music.ResolvedAlbum,
    to refreshed: Music.ResolvedAlbum,
  ) -> Bool {
    let grant = { (resolution: Music.ResolvedAlbum) in
      Music.LibrarySnapshotCompiler.AlbumGrant(
        appleMusicAlbumId: album.appleMusicAlbumId,
        createdAt: album.createdAt,
        showsArtwork: album.showsArtwork,
        resolution: resolution,
      )
    }
    do {
      return try Music.LibrarySnapshotCompiler.compile(
        albumGrants: [grant(existing)],
        artistGrants: [],
      ) != Music.LibrarySnapshotCompiler.compile(
        albumGrants: [grant(refreshed)],
        artistGrants: [],
      )
    } catch {
      return true
    }
  }

  private func artistContentChanged(
    _ artist: Music.ApprovedArtist,
    from existing: Music.ResolvedArtist,
    to refreshed: Music.ResolvedArtist,
  ) -> Bool {
    let grant = { (resolution: Music.ResolvedArtist) in
      Music.LibrarySnapshotCompiler.ArtistGrant(
        appleMusicArtistId: artist.appleMusicArtistId,
        createdAt: artist.createdAt,
        resolution: resolution,
      )
    }
    do {
      return try Music.LibrarySnapshotCompiler.compile(
        albumGrants: [],
        artistGrants: [grant(existing)],
      ) != Music.LibrarySnapshotCompiler.compile(
        albumGrants: [],
        artistGrants: [grant(refreshed)],
      )
    } catch {
      return true
    }
  }

  private func childContentChanged(
    album: Music.ApprovedAlbum,
    to resolution: Music.ResolvedAlbum,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    let albums = try await Music.ApprovedAlbum.query()
      .where(.childId == album.childId)
      .all(in: db)
    let artists = try await Music.ApprovedArtist.query()
      .where(.childId == album.childId)
      .all(in: db)
    let existingGrants = albums.map {
      Music.LibrarySnapshotCompiler.AlbumGrant(
        appleMusicAlbumId: $0.appleMusicAlbumId,
        createdAt: $0.createdAt,
        showsArtwork: $0.showsArtwork,
        resolution: $0.resolution,
      )
    }
    let refreshedGrants = albums.map {
      Music.LibrarySnapshotCompiler.AlbumGrant(
        appleMusicAlbumId: $0.appleMusicAlbumId,
        createdAt: $0.createdAt,
        showsArtwork: $0.showsArtwork,
        resolution: $0.id == album.id ? resolution : $0.resolution,
      )
    }
    let artistGrants = artists.map {
      Music.LibrarySnapshotCompiler.ArtistGrant(
        appleMusicArtistId: $0.appleMusicArtistId,
        createdAt: $0.createdAt,
        resolution: $0.resolution,
      )
    }
    let refreshed = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: refreshedGrants,
      artistGrants: artistGrants,
    )
    guard let existing = try? Music.LibrarySnapshotCompiler.compile(
      albumGrants: existingGrants,
      artistGrants: artistGrants,
    ) else { return true }
    return existing != refreshed
  }

  private func childContentChanged(
    artist: Music.ApprovedArtist,
    to resolution: Music.ResolvedArtist,
    in db: any DuetSQL.Client,
  ) async throws -> Bool {
    let albums = try await Music.ApprovedAlbum.query()
      .where(.childId == artist.childId)
      .all(in: db)
    let artists = try await Music.ApprovedArtist.query()
      .where(.childId == artist.childId)
      .all(in: db)
    let albumGrants = albums.map {
      Music.LibrarySnapshotCompiler.AlbumGrant(
        appleMusicAlbumId: $0.appleMusicAlbumId,
        createdAt: $0.createdAt,
        showsArtwork: $0.showsArtwork,
        resolution: $0.resolution,
      )
    }
    let existingGrants = artists.map {
      Music.LibrarySnapshotCompiler.ArtistGrant(
        appleMusicArtistId: $0.appleMusicArtistId,
        createdAt: $0.createdAt,
        resolution: $0.resolution,
      )
    }
    let refreshedGrants = artists.map {
      Music.LibrarySnapshotCompiler.ArtistGrant(
        appleMusicArtistId: $0.appleMusicArtistId,
        createdAt: $0.createdAt,
        resolution: $0.id == artist.id ? resolution : $0.resolution,
      )
    }
    let refreshed = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: albumGrants,
      artistGrants: refreshedGrants,
    )
    guard let existing = try? Music.LibrarySnapshotCompiler.compile(
      albumGrants: albumGrants,
      artistGrants: existingGrants,
    ) else { return true }
    return existing != refreshed
  }

  private func refresh(
    artist: Music.ApprovedArtist,
    resolution: Music.ResolvedArtist,
  ) async throws -> Bool {
    try await self.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: artist.childId, in: db)
      let current = try await Music.ApprovedArtist.query()
        .where(.id == artist.id)
        .all(in: db)
        .first
      guard var current else { return false }
      guard try await self.childContentChanged(artist: current, to: resolution, in: db) else {
        return false
      }
      current.name = resolution.name
      current.catalogMetadata = resolution.catalogMetadata
      current.resolution = resolution
      current.resolvedAt = self.now
      try await db.update(current)
      try await Music.LibrarySnapshotRepository.publish(
        childId: current.childId,
        generatedAt: self.now,
        in: db,
      )
      return true
    }
  }
}
