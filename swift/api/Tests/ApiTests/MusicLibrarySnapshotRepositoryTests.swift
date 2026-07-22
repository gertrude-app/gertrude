import DuetSQL
import Foundation
import XCTest
import XExpect

@testable import Api

final class MusicLibrarySnapshotRepositoryTests: ApiTestCase, @unchecked Sendable {
  func testPublishesAndRoundTripsCompleteSnapshot() async throws {
    let child = try await self.child()
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy title",
      artistName: "Legacy artist",
      showsArtwork: false,
      resolution: snapshotResolvedAlbum(id: "album-1", title: "Trusted title"),
      resolvedAt: .reference,
    ))

    let snapshot = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    let reloaded = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(snapshot.revision).toEqual(1)
    expect(snapshot.payload.revision).toEqual(1)
    expect(snapshot.payload.albums.map(\.title)).toEqual(["Trusted title"])
    expect(snapshot.payload.albums.first?.showsArtwork).toEqual(false)
    expect(snapshot.payload.albums.first?.tracks.map(\.albumId)).toEqual(["album-1"])
    expect(reloaded?.payload).toEqual(snapshot.payload)
    expect(reloaded?.createdAt).toEqual(.reference)
  }

  func testNoOpDoesNotBumpOrRewriteAndChangeDoes() async throws {
    let child = try await self.child()
    var album = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Album",
      artistName: "Artist",
      resolution: snapshotResolvedAlbum(id: "album-1", title: "First"),
      resolvedAt: .reference,
    ))

    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    let noOp = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference + 100,
      in: self.db,
    )

    expect(noOp.id).toEqual(first.id)
    expect(noOp.revision).toEqual(1)
    expect(noOp.createdAt).toEqual(.reference)

    album.resolution = snapshotResolvedAlbum(id: "album-1", title: "Changed")
    album.resolvedAt = .reference + 200
    try await self.db.update(album)
    let changed = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference + 200,
      in: self.db,
    )

    expect(changed.id).toEqual(first.id)
    expect(changed.revision).toEqual(2)
    expect(changed.payload.revision).toEqual(2)
    expect(changed.payload.albums.map(\.title)).toEqual(["Changed"])
    expect(changed.createdAt).toEqual(.reference + 200)
  }

  func testPublishRepairsPayloadRevisionMismatch() async throws {
    let child = try await self.child()
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Album",
      artistName: "Artist",
      resolution: snapshotResolvedAlbum(id: "album-1"),
      resolvedAt: .reference,
    ))
    var first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    first.payload.revision = 99
    try await self.db.update(first)

    let repaired = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference + 100,
      in: self.db,
    )

    expect(repaired.id).toEqual(first.id)
    expect(repaired.revision).toEqual(2)
    expect(repaired.payload.revision).toEqual(2)
    expect(repaired.createdAt).toEqual(.reference + 100)
  }

  func testMissingResolutionCannotReplaceLastGoodSnapshot() async throws {
    let child = try await self.child()
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Album",
      artistName: "Artist",
      resolution: snapshotResolvedAlbum(id: "album-1"),
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
    ))

    do {
      _ = try await Music.LibrarySnapshotRepository.publish(
        childId: child.id,
        generatedAt: .reference + 100,
        in: self.db,
      )
      XCTFail("expected missing resolution error")
    } catch let error as Music.LibrarySnapshotCompiler.CompilerError {
      expect(error).toEqual(.missingArtistResolution("artist-1"))
    }

    let reloaded = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )
    expect(reloaded?.payload).toEqual(first.payload)
  }

  func testPublishesCompleteEmptySnapshotAfterRemoval() async throws {
    let child = try await self.child()
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Album",
      artistName: "Artist",
      resolution: snapshotResolvedAlbum(id: "album-1"),
      resolvedAt: .reference,
    ))
    _ = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .delete(in: self.db)

    let empty = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference + 100,
      in: self.db,
    )

    expect(empty.revision).toEqual(2)
    expect(empty.payload.albums).toEqual([])
    expect(empty.payload.artists).toEqual([])
  }
}

private func snapshotResolvedAlbum(
  id: Music.AlbumId,
  title: String = "Album",
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    artworkUrl: "https://example.com/album.jpg",
    trackCount: 1,
    releaseDate: "2026-01-01",
    releaseType: "Album",
    tracks: [
      .init(
        id: "track-1",
        title: "Track",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: id,
        albumTitle: title,
        durationInMillis: 100_000,
      ),
    ],
  )
}
