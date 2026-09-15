import CustomDump
import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicCatalogRefreshJobTests: ApiTestCase, @unchecked Sendable {
  func testEmptyChildFilterDoesNotQueryDatabase() async throws {
    let summary = await withDependencies {
      $0.db = DuetSQL.ThrowingClient()
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [])
    }

    expectNoDifference(summary, .init())
  }

  func testFilteredRefreshDoesNotDecodeAnotherChildsResolution() async throws {
    let child = try await self.child()
    let otherChild = try await self.child()
    let resolution = refreshArtist(albumIds: ["album-1"])
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: resolution.id,
      name: resolution.name,
      resolution: resolution,
      resolvedAt: .reference,
    ))
    let unrelated = try await self.db.create(Music.ApprovedArtist(
      childId: otherChild.id,
      appleMusicArtistId: resolution.id,
      name: resolution.name,
      resolution: resolution,
      resolvedAt: .reference,
    ))
    try await self.db.execute(raw: """
    UPDATE music.approved_artists SET resolution = '{}'::jsonb
    WHERE id = \(bind: unrelated.id.rawValue)
    """)

    let summary = await withDependencies {
      $0.db = self.db
      $0.appleMusic.resolveArtist = { _ in resolution }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    try await self.db.delete(unrelated.id)

    expectNoDifference(summary, .init(unchangedArtists: 1))
  }

  func testPersistsEachChildBeforeResolvingUnrelatedCatalog() async throws {
    let firstChild = try await self.child()
    let secondChild = try await self.child()
    let childIds = [firstChild.id, secondChild.id]
      .sorted { $0.rawValue.uuidString < $1.rawValue.uuidString }
    let firstAlbum = try await self.db.create(Music.ApprovedAlbum(
      childId: childIds[0],
      appleMusicAlbumId: "album-1",
      title: "Old",
      artistName: "Artist",
      resolution: refreshAlbum(id: "album-1", title: "Old"),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: childIds[1],
      appleMusicAlbumId: "album-2",
      title: "Old",
      artistName: "Artist",
      resolution: refreshAlbum(id: "album-2", title: "Old"),
      resolvedAt: .reference,
    ))

    let summary = await withDependencies {
      $0.db = self.db
      $0.appleMusic.resolveAlbum = { lookup in
        if lookup.albumId == "album-2" {
          let refreshed = try await self.db.find(firstAlbum.id)
          expectNoDifference(refreshed.title, "Updated")
        }
        return refreshAlbum(id: lookup.albumId, title: "Updated")
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: Set(childIds))
    }

    expectNoDifference(summary, .init(refreshedAlbums: 2))
  }

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

    let unchanged = await withDependencies {
      $0.db = self.db
      $0.date.now = .reference + 200
      $0.appleMusic.resolveAlbum = { _ in
        await calls.increment()
        return resolution
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [child.id])
    }
    let unchangedSnapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    await expect(calls.value()).toEqual(2)
    expect(unchanged.refreshedTracks).toEqual(0)
    expect(unchanged.unchangedTracks).toEqual(2)
    expect(unchangedSnapshot?.revision).toEqual(snapshot?.revision)
    expect(unchangedSnapshot?.createdAt).toEqual(snapshot?.createdAt)
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
      $0.appleMusic.resolveAlbum = { lookup in
        switch lookup.albumId.rawValue {
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

  func testSharedCatalogIdsAreResolvedSeparatelyForEachStorefront() async throws {
    let german = try await self.child(with: { $0.appleMusicStorefront = "de" })
    let american = try await self.child()
    let album = refreshAlbum(id: "album-1")
    let artist = refreshArtist(albumIds: ["artist-album"])
    for child in [german, american] {
      _ = try await self.db.create(Music.ApprovedAlbum(
        childId: child.id,
        appleMusicAlbumId: album.id,
        title: album.title,
        artistName: album.artistName,
        trackCount: album.trackCount,
        resolution: album,
        resolvedAt: .reference,
      ))
      _ = try await self.db.create(Music.ApprovedArtist(
        childId: child.id,
        appleMusicArtistId: artist.id,
        name: artist.name,
        resolution: artist,
        resolvedAt: .reference,
      ))
    }
    let albumCalls = RefreshCallCounter()
    let artistCalls = RefreshCallCounter()

    let summary = await withDependencies {
      $0.db = self.db
      $0.appleMusic.resolveAlbum = { lookup in
        await albumCalls.increment()
        return refreshAlbum(id: lookup.albumId, title: lookup.storefront.rawValue)
      }
      $0.appleMusic.resolveArtist = { lookup in
        await artistCalls.increment()
        var localized = artist
        localized.name = lookup.storefront.rawValue
        return localized
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [german.id, american.id])
    }

    await expect(albumCalls.value()).toEqual(2)
    await expect(artistCalls.value()).toEqual(2)
    expectNoDifference(summary, .init(refreshedAlbums: 2, refreshedArtists: 2))
    for (child, storefront) in [(german, "de"), (american, "us")] {
      let refreshedAlbum = try await Music.ApprovedAlbum.query()
        .where(.childId == child.id)
        .first(in: self.db)
      let refreshedArtist = try await Music.ApprovedArtist.query()
        .where(.childId == child.id)
        .first(in: self.db)
      expectNoDifference(refreshedAlbum.title, storefront)
      expectNoDifference(refreshedArtist.name, storefront)
    }
  }

  func testSharedArtistResolutionSurvivesFailureAndInterveningChild() async throws {
    let firstChild = try await self.child()
    let secondChild = try await self.child()
    let thirdChild = try await self.child()
    let childIds = [firstChild.id, secondChild.id, thirdChild.id]
      .sorted { $0.rawValue.uuidString < $1.rawValue.uuidString }
    let resolution = refreshArtist(albumIds: ["artist-album"])
    let grants = try await self.db.create([childIds[0], childIds[2]].map { childId in
      Music.ApprovedArtist(
        childId: childId,
        appleMusicArtistId: resolution.id,
        name: "Old",
        resolution: resolution,
        resolvedAt: .reference,
      )
    })
    try await self.db.execute(raw: """
    UPDATE music.approved_artists SET resolution = '{}'::jsonb
    WHERE id = \(bind: grants[0].id.rawValue)
    """)
    let album = refreshAlbum(id: "unrelated-album")
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: childIds[1],
      appleMusicAlbumId: album.id,
      title: album.title,
      artistName: album.artistName,
      trackCount: album.trackCount,
      resolution: album,
      resolvedAt: .reference,
    ))
    let calls = RefreshCallCounter()

    let summary = await withDependencies {
      $0.db = self.db
      $0.appleMusic.resolveAlbum = { _ in album }
      $0.appleMusic.resolveArtist = { _ in
        await calls.increment()
        return resolution
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: Set(childIds))
    }
    try await self.db.delete(grants[0].id)
    let refreshed = try await self.db.find(grants[1].id)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: childIds[2],
      in: self.db,
    )

    await expect(calls.value()).toEqual(1)
    expectNoDifference(summary, .init(refreshedArtists: 1, unchangedAlbums: 1, failures: 1))
    expectNoDifference(refreshed.name, resolution.name)
    expectNoDifference(refreshed.resolution, resolution)
    expectNoDifference(snapshot?.revision, 1)
    expectNoDifference(snapshot?.payload.albums.map(\.id), ["artist-album"])
  }

  func testSharedArtistFailureIsNotRetriedForEachChild() async throws {
    let firstChild = try await self.child()
    let secondChild = try await self.child()
    let artist = refreshArtist(albumIds: ["artist-album"])
    for childId in [firstChild.id, secondChild.id] {
      _ = try await self.db.create(Music.ApprovedArtist(
        childId: childId,
        appleMusicArtistId: artist.id,
        name: artist.name,
        resolution: artist,
        resolvedAt: .reference,
      ))
    }
    let calls = RefreshCallCounter()

    let summary = await withDependencies {
      $0.db = self.db
      $0.appleMusic.resolveArtist = { _ in
        await calls.increment()
        throw RefreshError.unavailable
      }
    } operation: {
      await MusicCatalogRefreshJob().exec(childIds: [firstChild.id, secondChild.id])
    }

    await expect(calls.value()).toEqual(1)
    expectNoDifference(summary, .init(failures: 2))
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
