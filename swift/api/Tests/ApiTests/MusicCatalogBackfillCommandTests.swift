import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicCatalogBackfillCommandTests: ApiTestCase, @unchecked Sendable {
  func testBackfillsLegacyAlbumGrantsPreservesIdentityAndIsRerunnable() async throws {
    let child = try await self.child()
    var album = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy Album",
      artistName: "Legacy Artist",
    ))
    try await album.modifyCreatedAt(.exact(.reference - 200))
    album = try await self.db.find(album.id)
    let resolvedAlbum = backfillAlbum(id: album.appleMusicAlbumId)
    let emptyPlaylist = try await self.db.create(Music.Playlist(
      childId: child.id,
      name: "Empty",
      createdAt: .reference - 50,
      updatedAt: .reference - 50,
    ))
    let populatedPlaylist = try await self.db.create(Music.Playlist(
      childId: child.id,
      name: "Populated",
      createdAt: .reference - 40,
      updatedAt: .reference - 40,
    ))
    let populatedEntry = try await self.db.create(Music.PlaylistEntry(
      playlistId: populatedPlaylist.id,
      position: 0,
      appleMusicTrackId: "album-1-track",
      preferredAlbumId: "album-1",
      createdAt: .reference - 30,
    ))
    _ = try await self.db.create(Music.PlaylistEntry(
      playlistId: populatedPlaylist.id,
      position: 1,
      appleMusicTrackId: "unapproved-track",
      preferredAlbumId: "album-1",
      createdAt: .reference - 20,
    ))

    let firstReport = try await withDependencies {
      $0.db = self.db
      $0.date.now = .reference
      $0.appleMusic.resolveAlbum = { _ in resolvedAlbum }
    } operation: {
      try await MusicCatalogBackfillCommand().exec(childIds: [child.id])
    }
    let reloadedAlbum = try await self.db.find(album.id)
    let firstSnapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(firstReport).toEqual(.init(
      resolvedAlbums: 1,
      publishedChildren: 1,
      unresolvedAlbums: 0,
      unpublishedChildren: 0,
    ))
    expect(reloadedAlbum.id).toEqual(album.id)
    expect(reloadedAlbum.createdAt).toEqual(album.createdAt)
    expect(reloadedAlbum.resolution).toEqual(resolvedAlbum)
    expect(firstSnapshot?.payload.albums.map(\.id)).toEqual(["album-1"])
    expect(firstSnapshot?.payload.playlists.map(\.id)).toEqual([
      emptyPlaylist.id.rawValue,
      populatedPlaylist.id.rawValue,
    ])
    expect(firstSnapshot?.payload.playlists.map { $0.entries.map(\.id) }).toEqual([
      [],
      [populatedEntry.id.rawValue],
    ])
    let reconciledEntries = try await Music.PlaylistRepository.entries(
      for: populatedPlaylist.id,
      in: self.db,
    )
    expect(reconciledEntries.map(\.id)).toEqual([populatedEntry.id])

    let secondReport = try await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in
        XCTFail("resolved album should not be fetched again")
        return resolvedAlbum
      }
    } operation: {
      try await MusicCatalogBackfillCommand().exec(childIds: [child.id])
    }
    let secondSnapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(secondReport.resolvedAlbums).toEqual(0)
    expect(secondReport.unresolvedAlbums).toEqual(0)
    expect(secondReport.unpublishedChildren).toEqual(0)
    expect(secondSnapshot?.revision).toEqual(firstSnapshot?.revision)
    expect(secondSnapshot?.createdAt).toEqual(firstSnapshot?.createdAt)
    expect(secondSnapshot?.payload).toEqual(firstSnapshot?.payload)
  }

  func testIncompleteBackfillFailsClearlyWithoutPartialSnapshot() async throws {
    let child = try await self.child()
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy",
      artistName: "Legacy",
    ))
    do {
      _ = try await withDependencies {
        $0.db = self.db
        $0.date.now = .reference
        $0.appleMusic.resolveAlbum = { _ in throw BackfillTestError.unavailable }
      } operation: {
        try await MusicCatalogBackfillCommand().exec(childIds: [child.id])
      }
      XCTFail("expected incomplete backfill")
    } catch let error as MusicCatalogBackfillCommand.BackfillError {
      switch error {
      case .incomplete(let report):
        expect(report.unresolvedAlbums).toEqual(1)
        expect(report.unpublishedChildren).toEqual(1)
      }
    }

    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )
    expect(snapshot).toBeNil()
  }
}

private enum BackfillTestError: Error {
  case unavailable
}

private func backfillAlbum(id: Music.AlbumId) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: "Artist's Album",
    artistName: "Trusted Artist",
    artistIds: ["artist-1"],
    trackCount: 1,
    tracks: [
      .init(
        id: .init(rawValue: "\(id.rawValue)-track"),
        title: "Artist's Track",
        artistName: "Trusted Artist",
        artistIds: ["artist-1"],
        albumId: id,
        albumTitle: "Artist's Album",
      ),
    ],
  )
}
