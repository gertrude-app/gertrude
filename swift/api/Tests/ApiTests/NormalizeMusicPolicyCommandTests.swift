import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class NormalizeMusicPolicyCommandTests: ApiTestCase, @unchecked Sendable {
  func testNormalizesExactCoveragePublishesOnceAndIsIdempotent() async throws {
    let child = try await self.child()
    let coveredAlbum = resolvedAlbum(
      id: "covered-album",
      tracks: [resolvedTrack(id: "covered-track", albumId: "covered-album")],
    )
    let outsideAlbum = resolvedAlbum(
      id: "outside-album",
      tracks: [resolvedTrack(id: "outside-track", albumId: "outside-album")],
    )
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: coveredAlbum.id,
      title: coveredAlbum.title,
      artistName: coveredAlbum.artistName,
      resolution: coveredAlbum,
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: outsideAlbum.id,
      title: outsideAlbum.title,
      artistName: outsideAlbum.artistName,
      resolution: outsideAlbum,
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "covered-track",
      preferredAlbumId: "alternate-album",
      resolution: resolvedTrackGrant(
        id: "covered-track",
        preferredAlbumId: "alternate-album",
      ),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "outside-direct-track",
      preferredAlbumId: "outside-direct-album",
      resolution: resolvedTrackGrant(
        id: "outside-direct-track",
        preferredAlbumId: "outside-direct-album",
      ),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
      resolution: resolvedArtist(id: "artist-1", albums: [coveredAlbum]),
      resolvedAt: .reference,
    ))
    let initial = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let first = try await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
    } operation: {
      try await NormalizeMusicPolicyCommand().exec(childIds: [child.id])
    }
    let albums = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .all(in: self.db)
    let tracks = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .all(in: self.db)
    let normalized = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(first).toEqual(.init(
      scannedChildren: 1,
      affectedChildren: 1,
      deletedAlbums: 1,
      deletedTracks: 1,
      publishedChildren: 1,
    ))
    expect(albums.map(\.appleMusicAlbumId)).toEqual(["outside-album"])
    expect(tracks.map(\.appleMusicTrackId)).toEqual(["outside-direct-track"])
    expect(normalized?.revision).toEqual(initial.revision + 1)
    expect(normalized?.payload.albums.map(\.id)).toEqual(
      initial.payload.albums.map(\.id),
    )

    let second = try await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 200
    } operation: {
      try await NormalizeMusicPolicyCommand().exec(childIds: [child.id])
    }
    let rerun = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(second).toEqual(.init(scannedChildren: 1))
    expect(rerun?.revision).toEqual(normalized?.revision)

    try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .delete(in: self.db)
    let afterArtistRemoval = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference + 300,
      in: self.db,
    )

    expect(afterArtistRemoval.payload.albums.map(\.id)).toEqual([
      "outside-album",
      "outside-direct-album",
    ])
  }

  func testInvalidPolicyFailsBeforeDeletingAnyRows() async throws {
    let validChild = try await self.child()
    let invalidChild = try await self.child()
    let album = resolvedAlbum(id: "album-1")
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: validChild.id,
      appleMusicAlbumId: album.id,
      title: album.title,
      artistName: album.artistName,
      resolution: album,
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: validChild.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
      resolution: resolvedArtist(id: "artist-1", albums: [album]),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: invalidChild.id,
      appleMusicArtistId: "artist-2",
      name: "Unresolved",
    ))

    do {
      _ = try await withDependencies {
        $0.db = self.db
      } operation: {
        try await NormalizeMusicPolicyCommand().exec(
          childIds: [validChild.id, invalidChild.id],
        )
      }
      XCTFail("expected invalid policy error")
    } catch let error as Music.CatalogPolicy.ValidationError {
      expect(error).toEqual(.missingArtistResolution("artist-2"))
    }

    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == validChild.id)
      .count(in: self.db)).toEqual(1)
  }
}
