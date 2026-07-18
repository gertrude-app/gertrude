import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicCatalogRefreshJobTests: ApiTestCase, @unchecked Sendable {
  func testNoOpRefreshDoesNotRewriteOrBumpSnapshot() async throws {
    let child = try await self.child()
    let resolution = refreshAlbum(id: "album-1", title: "Album")
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: resolution.title,
      artistName: resolution.artistName,
      resolution: resolution,
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in resolution }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let reloaded = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(summary).toEqual(.init(
      refreshedAlbums: 0,
      refreshedArtists: 0,
      unchangedAlbums: 1,
      unchangedArtists: 0,
      failures: 0,
    ))
    expect(reloaded?.revision).toEqual(first.revision)
    expect(reloaded?.createdAt).toEqual(first.createdAt)
  }

  func testFailedRefreshRetainsLastGoodResolutionAndSnapshot() async throws {
    let child = try await self.child()
    let resolution = refreshAlbum(id: "album-1", title: "Last Good")
    let album = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: resolution.title,
      artistName: resolution.artistName,
      resolution: resolution,
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in throw RefreshError.unavailable }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let reloadedAlbum = try await self.db.find(album.id)
    let reloadedSnapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(summary.failures).toEqual(1)
    expect(reloadedAlbum.resolution).toEqual(resolution)
    expect(reloadedAlbum.resolvedAt).toEqual(.reference)
    expect(reloadedSnapshot?.payload).toEqual(first.payload)
  }

  func testSuccessfulArtistRefreshExactlyReplacesReleaseCoverage() async throws {
    let child = try await self.child()
    let old = refreshArtist(albumIds: ["album-1", "album-2"])
    let updated = refreshArtist(albumIds: ["album-1"])
    let artist = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: old.name,
      resolution: old,
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveArtist = { _ in updated }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let reloadedArtist = try await self.db.find(artist.id)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(summary.refreshedArtists).toEqual(1)
    expect(reloadedArtist.resolution).toEqual(updated)
    expect(snapshot?.revision).toEqual(first.revision + 1)
    expect(snapshot?.payload.albums.map(\.id)).toEqual(["album-1"])
    expect(snapshot?.payload.artists.first?.releaseAlbumIds).toEqual(["album-1"])
  }

  func testArtistRefreshDoesNotWriteWhenChangesAreShadowedByDirectAlbum() async throws {
    let child = try await self.child()
    let directResolution = refreshAlbum(id: "album-1", title: "Direct")
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: directResolution.title,
      artistName: directResolution.artistName,
      resolution: directResolution,
      resolvedAt: .reference,
    ))
    let old = Music.ResolvedArtist(
      id: "artist-1",
      name: "Artist",
      topSongs: [],
      albums: [refreshAlbum(id: "album-1", title: "Old artist metadata")],
    )
    let updated = Music.ResolvedArtist(
      id: "artist-1",
      name: "Artist",
      topSongs: [],
      albums: [refreshAlbum(id: "album-1", title: "New artist metadata")],
    )
    let artist = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: old.name,
      resolution: old,
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in directResolution }
      $0.appleMusic.resolveArtist = { _ in updated }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let reloadedArtist = try await self.db.find(artist.id)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(summary.unchangedAlbums).toEqual(1)
    expect(summary.unchangedArtists).toEqual(1)
    expect(reloadedArtist.resolution).toEqual(old)
    expect(reloadedArtist.resolvedAt).toEqual(.reference)
    expect(snapshot?.revision).toEqual(first.revision)
    expect(snapshot?.createdAt).toEqual(first.createdAt)
    expect(snapshot?.payload).toEqual(first.payload)
  }

  func testDuplicateAppleIdsResolveOnceAcrossChildren() async throws {
    let firstChild = try await self.child()
    let secondChild = try await self.child()
    let resolution = refreshAlbum(id: "album-1")
    for childId in [firstChild.id, secondChild.id] {
      _ = try await self.db.create(Music.ApprovedAlbum(
        childId: childId,
        appleMusicAlbumId: "album-1",
        title: "Old",
        artistName: "Artist",
        resolution: refreshAlbum(id: "album-1", title: "Old"),
        resolvedAt: .reference,
      ))
      _ = try await Music.LibrarySnapshotRepository.publish(
        childId: childId,
        generatedAt: .reference,
        in: self.db,
      )
    }
    let calls = RefreshCallCounter()

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in
        await calls.increment()
        return resolution
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [firstChild.id, secondChild.id])
    }

    let callCount = await calls.value()
    expect(callCount).toEqual(1)
    expect(summary.refreshedAlbums).toEqual(2)
  }
}

private actor RefreshCallCounter {
  private var count = 0

  func increment() {
    self.count += 1
  }

  func value() -> Int {
    self.count
  }
}

private enum RefreshError: Error {
  case unavailable
}

private func refreshArtist(albumIds: [Music.AlbumId]) -> Music.ResolvedArtist {
  .init(
    id: "artist-1",
    name: "Artist",
    topSongs: [],
    albums: albumIds.map { refreshAlbum(id: $0) },
  )
}

private func refreshAlbum(
  id: Music.AlbumId,
  title: String = "Album",
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    trackCount: 1,
    tracks: [
      .init(
        id: .init(rawValue: "\(id.rawValue)-track"),
        title: "Track",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: id,
        albumTitle: title,
      ),
    ],
  )
}
