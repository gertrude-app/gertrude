import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicCatalogBackfillCommandTests: ApiTestCase, @unchecked Sendable {
  func testBackfillsLegacyGrantsPreservesIdentityAndIsRerunnable() async throws {
    let child = try await self.child()
    var album = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy Album",
      artistName: "Legacy Artist",
    ))
    var artist = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Legacy Artist",
    ))
    try await album.modifyCreatedAt(.exact(.reference - 200))
    try await artist.modifyCreatedAt(.exact(.reference - 100))
    album = try await self.db.find(album.id)
    artist = try await self.db.find(artist.id)
    let resolvedAlbum = backfillAlbum(id: album.appleMusicAlbumId)
    let resolvedArtist = backfillArtist(id: artist.appleMusicArtistId)
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
      $0.appleMusic.resolveArtist = { _ in resolvedArtist }
    } operation: {
      try await MusicCatalogBackfillCommand().exec(childIds: [child.id])
    }
    let reloadedAlbum = try await self.db.find(album.id)
    let reloadedArtist = try await self.db.find(artist.id)
    let firstSnapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(firstReport).toEqual(.init(
      resolvedAlbums: 1,
      resolvedArtists: 1,
      publishedChildren: 1,
      unresolvedAlbums: 0,
      unresolvedArtists: 0,
      unpublishedChildren: 0,
    ))
    expect(reloadedAlbum.id).toEqual(album.id)
    expect(reloadedAlbum.createdAt).toEqual(album.createdAt)
    expect(reloadedAlbum.resolution).toEqual(resolvedAlbum)
    expect(reloadedArtist.id).toEqual(artist.id)
    expect(reloadedArtist.createdAt).toEqual(artist.createdAt)
    expect(reloadedArtist.resolution).toEqual(resolvedArtist)
    expect(firstSnapshot?.payload.albums.map(\.id)).toEqual(["album-1", "artist-album"])
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
      $0.appleMusic.resolveArtist = { _ in
        XCTFail("resolved artist should not be fetched again")
        return resolvedArtist
      }
    } operation: {
      try await MusicCatalogBackfillCommand().exec(childIds: [child.id])
    }
    let secondSnapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(secondReport.resolvedAlbums).toEqual(0)
    expect(secondReport.resolvedArtists).toEqual(0)
    expect(secondReport.unresolvedAlbums).toEqual(0)
    expect(secondReport.unresolvedArtists).toEqual(0)
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
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Legacy",
    ))

    do {
      _ = try await withDependencies {
        $0.db = self.db
        $0.date.now = .reference
        $0.appleMusic.resolveAlbum = { _ in backfillAlbum(id: "album-1") }
        $0.appleMusic.resolveArtist = { _ in throw BackfillTestError.unavailable }
      } operation: {
        try await MusicCatalogBackfillCommand().exec(childIds: [child.id])
      }
      XCTFail("expected incomplete backfill")
    } catch let error as MusicCatalogBackfillCommand.BackfillError {
      switch error {
      case .incomplete(let report):
        expect(report.unresolvedAlbums).toEqual(0)
        expect(report.unresolvedArtists).toEqual(1)
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

private func backfillArtist(id: Music.ArtistId) -> Music.ResolvedArtist {
  .init(
    id: id,
    name: "Trusted Artist",
    topSongs: [],
    albums: [backfillAlbum(id: "artist-album")],
  )
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
