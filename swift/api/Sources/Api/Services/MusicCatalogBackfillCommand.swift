import Dependencies
import DuetSQL
import Vapor

struct MusicCatalogBackfillCommand: AsyncCommand {
  struct Signature: CommandSignature {}

  struct Report: Equatable, Sendable {
    var resolvedAlbums = 0
    var resolvedArtists = 0
    var publishedChildren = 0
    var unresolvedAlbums = 0
    var unresolvedArtists = 0
    var unpublishedChildren = 0
  }

  enum BackfillError: Error, CustomStringConvertible {
    case incomplete(Report)

    var description: String {
      switch self {
      case .incomplete(let report):
        "Music catalog backfill incomplete: \(report.unresolvedAlbums) albums, \(report.unresolvedArtists) artists, and \(report.unpublishedChildren) children remain incomplete"
      }
    }
  }

  var help: String { "Resolve music grants and publish complete child libraries" }

  @Dependency(\.appleMusic) var appleMusic
  @Dependency(\.date.now) var now
  @Dependency(\.db) var db
  @Dependency(\.logger) var logger

  func run(using context: CommandContext, signature: Signature) async throws {
    let report = try await self.exec()
    self.logger.info(
      "Music catalog backfill complete: resolved \(report.resolvedAlbums) albums and \(report.resolvedArtists) artists; published \(report.publishedChildren) children",
    )
  }

  func exec(childIds: Set<Child.Id>? = nil) async throws -> Report {
    var report = Report()
    let albums = try await Music.ApprovedAlbum.query()
      .orderBy(.createdAt, .asc)
      .all(in: self.db)
      .filter { childIds?.contains($0.childId) ?? true }
    let unresolvedAlbums = albums.filter { $0.resolution == nil }
    let albumsById = Dictionary(grouping: unresolvedAlbums, by: \.appleMusicAlbumId)
    for albumId in albumsById.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
      do {
        let resolution = try await self.appleMusic.resolveAlbum(albumId)
        guard resolution.id == albumId else {
          throw Music.LibrarySnapshotCompiler.CompilerError.albumResolutionIdMismatch(
            expected: albumId,
            actual: resolution.id,
          )
        }
        for album in albumsById[albumId] ?? [] {
          let resolved = try await self.db.withTransaction { db in
            try await Music.LibrarySnapshotRepository.lock(childId: album.childId, in: db)
            let stored = try await Music.ApprovedAlbum.query()
              .where(.id == album.id)
              .all(in: db)
              .first
            guard var stored, stored.resolution == nil else { return false }
            stored.title = resolution.title
            stored.artistName = resolution.artistName
            stored.artworkUrl = resolution.artworkUrl
            stored.artwork = resolution.artwork
            stored.trackCount = resolution.trackCount
            stored.resolution = resolution
            stored.resolvedAt = self.now
            try await db.update(stored)
            return true
          }
          if resolved {
            report.resolvedAlbums += 1
          }
        }
      } catch {
        self.logger.error(
          "Backfilling Apple Music album `\(albumId.rawValue)` failed: \(error)",
        )
      }
    }

    let artists = try await Music.ApprovedArtist.query()
      .orderBy(.createdAt, .asc)
      .all(in: self.db)
      .filter { childIds?.contains($0.childId) ?? true }
    let unresolvedArtists = artists.filter { $0.resolution == nil }
    let artistsById = Dictionary(grouping: unresolvedArtists, by: \.appleMusicArtistId)
    for artistId in artistsById.keys.sorted(by: { $0.rawValue < $1.rawValue }) {
      do {
        let resolution = try await self.appleMusic.resolveArtist(artistId)
        guard resolution.id == artistId else {
          throw Music.LibrarySnapshotCompiler.CompilerError.artistResolutionIdMismatch(
            expected: artistId,
            actual: resolution.id,
          )
        }
        for artist in artistsById[artistId] ?? [] {
          let resolved = try await self.db.withTransaction { db in
            try await Music.LibrarySnapshotRepository.lock(childId: artist.childId, in: db)
            let stored = try await Music.ApprovedArtist.query()
              .where(.id == artist.id)
              .all(in: db)
              .first
            guard var stored, stored.resolution == nil else { return false }
            stored.name = resolution.name
            stored.catalogMetadata = resolution.catalogMetadata
            stored.resolution = resolution
            stored.resolvedAt = self.now
            try await db.update(stored)
            return true
          }
          if resolved {
            report.resolvedArtists += 1
          }
        }
      } catch {
        self.logger.error(
          "Backfilling Apple Music artist `\(artistId.rawValue)` failed: \(error)",
        )
      }
    }

    let allAlbums = try await Music.ApprovedAlbum.query().all(in: self.db)
      .filter { childIds?.contains($0.childId) ?? true }
    let allArtists = try await Music.ApprovedArtist.query().all(in: self.db)
      .filter { childIds?.contains($0.childId) ?? true }
    let childIds = Set(allAlbums.map(\.childId) + allArtists.map(\.childId))
    for childId in childIds.sorted(by: { $0.rawValue.uuidString < $1.rawValue.uuidString }) {
      let childAlbums = allAlbums.filter { $0.childId == childId }
      let childArtists = allArtists.filter { $0.childId == childId }
      guard childAlbums.allSatisfy({ $0.resolution != nil }),
            childArtists.allSatisfy({ $0.resolution != nil })
      else { continue }
      do {
        try await self.db.withTransaction { db in
          try await Music.LibrarySnapshotRepository.lock(childId: childId, in: db)
          try await Music.LibrarySnapshotRepository.publish(
            childId: childId,
            generatedAt: self.now,
            in: db,
          )
        }
        report.publishedChildren += 1
      } catch {
        self.logger.error("Publishing music snapshot for child `\(childId)` failed: \(error)")
      }
    }

    report.unresolvedAlbums = allAlbums.count { $0.resolution == nil }
    report.unresolvedArtists = allArtists.count { $0.resolution == nil }
    let snapshotsByChildId = try await Dictionary(
      uniqueKeysWithValues: Music.LibrarySnapshot.query()
        .all(in: self.db)
        .map { ($0.childId, $0) },
    )
    for childId in childIds {
      guard let snapshot = snapshotsByChildId[childId],
            snapshot.revision == snapshot.payload.revision else {
        report.unpublishedChildren += 1
        continue
      }
      do {
        var content = try Music.LibrarySnapshotCompiler.compile(
          albumGrants: allAlbums.filter { $0.childId == childId }.map {
            .init(
              appleMusicAlbumId: $0.appleMusicAlbumId,
              createdAt: $0.createdAt,
              showsArtwork: $0.showsArtwork,
              resolution: $0.resolution,
            )
          },
          artistGrants: allArtists.filter { $0.childId == childId }.map {
            .init(
              appleMusicArtistId: $0.appleMusicArtistId,
              createdAt: $0.createdAt,
              resolution: $0.resolution,
            )
          },
        )
        let index = Music.PlaylistRules.EffectiveTrackIndex(albums: content.albums)
        let playlists = try await Music.PlaylistRepository.rulesPlaylists(
          for: childId,
          in: self.db,
        )
        content.playlists = Music.PlaylistRules.compile(playlists: playlists, using: index)
        if !snapshot.payload.hasSameContent(as: content) {
          report.unpublishedChildren += 1
        }
      } catch {
        report.unpublishedChildren += 1
      }
    }

    guard report.unresolvedAlbums == 0,
          report.unresolvedArtists == 0,
          report.unpublishedChildren == 0 else {
      throw BackfillError.incomplete(report)
    }
    return report
  }
}
