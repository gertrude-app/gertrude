import Dependencies
import DuetSQL
import Vapor

struct NormalizeMusicPolicyCommand: AsyncCommand {
  struct Signature: CommandSignature {}

  struct Report: Equatable, Sendable {
    var scannedChildren = 0
    var affectedChildren = 0
    var deletedAlbums = 0
    var deletedTracks = 0
    var publishedChildren = 0
  }

  var help: String { "Remove music grants covered by active artist grants" }

  @Dependency(\.date.now) var now
  @Dependency(\.db) var db
  @Dependency(\.logger) var logger

  func run(using context: CommandContext, signature: Signature) async throws {
    let report = try await self.exec()
    self.logger.info(
      "Music policy normalization complete: affected \(report.affectedChildren) children; deleted \(report.deletedAlbums) albums and \(report.deletedTracks) tracks; published \(report.publishedChildren) snapshots",
    )
  }

  func exec(childIds filter: Set<Child.Id>? = nil) async throws -> Report {
    let artists = try await Music.ApprovedArtist.query().all(in: self.db)
      .filter { filter?.contains($0.childId) ?? true }
    let childIds = Set(artists.map(\.childId)).sorted {
      $0.rawValue.uuidString < $1.rawValue.uuidString
    }

    for childId in childIds {
      _ = try await Music.CatalogPolicy.load(childId: childId, in: self.db)
    }

    var report = Report(scannedChildren: childIds.count)
    for childId in childIds {
      let counts = try await self.db.withTransaction { db in
        try await Music.LibrarySnapshotRepository.lock(childId: childId, in: db)
        let policy = try await Music.CatalogPolicy.load(childId: childId, in: db)
        var coveredAlbumIds = Set<Music.AlbumId>()
        var coveredTrackIds = Set<Music.TrackId>()
        for artist in policy.artists {
          guard let resolution = artist.resolution else {
            throw Music.CatalogPolicy.ValidationError.missingArtistResolution(
              artist.appleMusicArtistId,
            )
          }
          let covered = try policy.coverage.directGrantsCovered(by: resolution)
          coveredAlbumIds.formUnion(covered.albumIds)
          coveredTrackIds.formUnion(covered.trackIds)
        }
        guard !coveredAlbumIds.isEmpty || !coveredTrackIds.isEmpty else {
          return (albums: 0, tracks: 0, published: false)
        }

        let deletedAlbums: Int = if coveredAlbumIds.isEmpty {
          0
        } else {
          try await Music.ApprovedAlbum.query()
            .where(.childId == childId)
            .where(.appleMusicAlbumId |=| coveredAlbumIds.map(\.rawValue))
            .delete(in: db)
        }
        let deletedTracks: Int = if coveredTrackIds.isEmpty {
          0
        } else {
          try await Music.ApprovedTrack.query()
            .where(.childId == childId)
            .where(.appleMusicTrackId |=| coveredTrackIds.map(\.rawValue))
            .delete(in: db)
        }
        guard deletedAlbums + deletedTracks > 0 else {
          return (albums: 0, tracks: 0, published: false)
        }
        _ = try await Music.LibrarySnapshotRepository.publishAfterPolicyChange(
          childId: childId,
          generatedAt: self.now,
          in: db,
        )
        return (albums: deletedAlbums, tracks: deletedTracks, published: true)
      }
      if counts.albums + counts.tracks > 0 {
        report.affectedChildren += 1
      }
      report.deletedAlbums += counts.albums
      report.deletedTracks += counts.tracks
      if counts.published {
        report.publishedChildren += 1
      }
    }
    return report
  }
}
