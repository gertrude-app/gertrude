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
      trackCount: resolution.trackCount,
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

  func testArtistRefreshRemovesNewlyCoveredTrackGrant() async throws {
    let child = try await self.child()
    let originalAlbum = refreshAlbumWithTracks(
      id: "artist-album",
      trackIds: ["track-1"],
    )
    let artist = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
      resolution: resolvedArtist(id: "artist-1", albums: [originalAlbum]),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "track-2",
      preferredAlbumId: "preferred-album",
      resolution: resolvedTrackGrant(
        id: "track-2",
        preferredAlbumId: "preferred-album",
      ),
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    let expandedAlbum = refreshAlbumWithTracks(
      id: "artist-album",
      trackIds: ["track-1", "track-2"],
    )
    let expandedArtist = resolvedArtist(id: "artist-1", albums: [expandedAlbum])
    let preferredAlbum = refreshAlbumWithTracks(
      id: "preferred-album",
      trackIds: ["track-2"],
    )

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in preferredAlbum }
      $0.appleMusic.resolveArtist = { _ in expandedArtist }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let reloadedArtist = try await self.db.find(artist.id)
    let tracks = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .all(in: self.db)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(summary.refreshedArtists).toEqual(1)
    expect(summary.normalizedTracks).toEqual(1)
    expect(reloadedArtist.resolution).toEqual(expandedArtist)
    expect(tracks).toBeEmpty()
    expect(snapshot?.revision).toEqual(first.revision + 1)
    expect(snapshot?.payload.albums.map(\.id)).toEqual(["artist-album"])
    expect(snapshot?.payload.albums[0].tracks.map(\.id)).toEqual(["track-1", "track-2"])
  }

  func testArtistRefreshWritesWhenBroaderMetadataChangesEffectiveAlbum() async throws {
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

    expect(summary.normalizedAlbums).toEqual(1)
    expect(summary.refreshedArtists).toEqual(1)
    expect(reloadedArtist.resolution).toEqual(updated)
    expect(reloadedArtist.resolvedAt).toEqual(.reference + 100)
    expect(snapshot?.revision).toEqual(first.revision + 1)
    expect(snapshot?.createdAt).toEqual(.reference + 100)
    expect(snapshot?.payload.albums.first?.title).toEqual("New artist metadata")
  }

  func testTrackRefreshUsesCompletePreferredAlbumWithoutPromotingScope() async throws {
    let child = try await self.child()
    let selectedTrackIds: [Music.TrackId] = ["track-1", "track-3"]
    for (position, trackId) in selectedTrackIds.enumerated() {
      _ = try await self.db.create(Music.ApprovedTrack(
        childId: child.id,
        appleMusicTrackId: trackId,
        preferredAlbumId: "album-1",
        resolution: resolvedTrackGrant(
          id: trackId,
          preferredAlbumId: "album-1",
          trackTitle: "Old \(trackId.rawValue)",
          catalogPosition: position,
        ),
        resolvedAt: .reference,
      ))
    }
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    let resolution = refreshAlbumWithTracks(
      id: "album-1",
      trackIds: ["track-1", "track-2", "track-3"],
    )
    let calls = RefreshCallCounter()

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in
        await calls.increment()
        return resolution
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let tracks = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .orderBy(.appleMusicTrackId, .asc)
      .all(in: self.db)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    await expect(calls.value()).toEqual(1)
    expect(summary.refreshedTracks).toEqual(2)
    expect(summary.normalizedTracks).toEqual(0)
    expect(tracks.map(\.resolution.catalogPosition)).toEqual([0, 2])
    expect(tracks.map(\.resolution.preferredAlbum.trackCount)).toEqual([3, 3])
    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
    expect(snapshot?.revision).toEqual(first.revision + 1)
    expect(snapshot?.payload.albums[0].tracks.map(\.id)).toEqual(["track-1", "track-3"])
  }

  func testAlbumRefreshRemovesNewlyCoveredTrackGrant() async throws {
    let child = try await self.child()
    let originalAlbum = refreshAlbumWithTracks(
      id: "album-1",
      trackIds: ["track-1"],
    )
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: originalAlbum.id,
      title: originalAlbum.title,
      artistName: originalAlbum.artistName,
      trackCount: originalAlbum.trackCount,
      resolution: originalAlbum,
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "track-2",
      preferredAlbumId: "album-2",
      resolution: resolvedTrackGrant(
        id: "track-2",
        preferredAlbumId: "album-2",
      ),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "removed-track",
      preferredAlbumId: "album-1",
      resolution: resolvedTrackGrant(
        id: "removed-track",
        preferredAlbumId: "album-1",
      ),
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    let expandedAlbum = refreshAlbumWithTracks(
      id: "album-1",
      trackIds: ["track-1", "track-2"],
    )
    let preferredAlbum = refreshAlbumWithTracks(
      id: "album-2",
      trackIds: ["track-2"],
    )

    let summary = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { albumId in
        switch albumId.rawValue {
        case "album-1": expandedAlbum
        case "album-2": preferredAlbum
        default: throw RefreshError.unavailable
        }
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let tracks = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .all(in: self.db)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(summary.refreshedAlbums).toEqual(1)
    expect(summary.normalizedTracks).toEqual(2)
    expect(tracks).toBeEmpty()
    expect(snapshot?.revision).toEqual(first.revision + 1)
    expect(snapshot?.payload.albums.map(\.id)).toEqual(["album-1"])
    expect(snapshot?.payload.albums[0].tracks.map(\.id)).toEqual(["track-1", "track-2"])
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

private func refreshAlbumWithTracks(
  id: Music.AlbumId,
  trackIds: [Music.TrackId],
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: "Album",
    artistName: "Artist",
    artistIds: ["artist-1"],
    trackCount: trackIds.count,
    tracks: trackIds.enumerated().map { index, trackId in
      .init(
        id: trackId,
        title: "Updated \(trackId.rawValue)",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: id,
        albumTitle: "Album",
        discNumber: 1,
        trackNumber: index + 1,
      )
    },
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
