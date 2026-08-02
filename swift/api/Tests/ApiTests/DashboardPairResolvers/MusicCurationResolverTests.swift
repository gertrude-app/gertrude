import Dependencies
import DuetSQL
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class MusicCurationResolverTests: ApiTestCase, @unchecked Sendable {
  func testRoutesMatch() throws {
    let token = UUID()
    let search = SearchMusicCatalog_v2.Input(
      childId: .init(rawValue: UUID()),
      query: "track",
      limit: 10,
    )
    let curation = GetMusicCuration.Input(childId: search.childId)
    let album = GetMusicAlbumCuration.Input(
      childId: search.childId,
      appleMusicAlbumId: "album-1",
    )
    let save = SaveMusicAlbumCuration.Input(
      childId: search.childId,
      appleMusicAlbumId: "album-1",
      expectedRevision: 2,
      selectedTrackIds: ["track-1"],
    )
    let approveTrack = ApproveMusicTrack.Input(
      childId: search.childId,
      appleMusicTrackId: "track-1",
      preferredAlbumId: "album-1",
    )
    let approveAlbum = ApproveMusicAlbum_v2.Input(
      childId: search.childId,
      appleMusicAlbumId: "album-1",
    )
    let approveArtist = ApproveMusicArtist_v2.Input(
      childId: search.childId,
      appleMusicArtistId: "artist-1",
    )
    let routes: [(String, Data, AuthedParentRoute)] = try [
      ("SearchMusicCatalog_v2", JSONEncoder().encode(search), .searchMusicCatalog_v2(search)),
      ("GetMusicCuration", JSONEncoder().encode(curation), .getMusicCuration(curation)),
      ("GetMusicAlbumCuration", JSONEncoder().encode(album), .getMusicAlbumCuration(album)),
      ("SaveMusicAlbumCuration", JSONEncoder().encode(save), .saveMusicAlbumCuration(save)),
      (
        "ApproveMusicTrack",
        JSONEncoder().encode(approveTrack),
        .approveMusicTrack(approveTrack),
      ),
      (
        "ApproveMusicAlbum_v2",
        JSONEncoder().encode(approveAlbum),
        .approveMusicAlbum_v2(approveAlbum),
      ),
      (
        "ApproveMusicArtist_v2",
        JSONEncoder().encode(approveArtist),
        .approveMusicArtist_v2(approveArtist),
      ),
    ]

    for (operation, body, route) in routes {
      var request = URLRequest(url: URL(string: "dashboard/\(operation)")!)
      request.httpMethod = "POST"
      request.addValue(token.uuidString, forHTTPHeaderField: "X-AdminToken")
      request.httpBody = body

      let matched = try PairQLRoute.router.match(request: request)

      expect(matched).toEqual(.dashboard(.adminAuthed(token, route)))
    }
  }

  func testApproveTracksCreatesPartialAlbumThenCanonicalWholeAlbum() async throws {
    let child = try await self.musicChild()
    let album = curationAlbum(
      id: "album-1",
      trackIds: ["track-1", "track-2"],
    )

    let first = try await withDependencies {
      $0.date.now = .reference
      $0.appleMusic.resolveTrack = { lookup in
        try curationTrackResolution(lookup: lookup, album: album)
      }
    } operation: {
      try await ApproveMusicTrack.resolve(
        with: .init(
          childId: child.id,
          appleMusicTrackId: "track-1",
          preferredAlbumId: "album-1",
        ),
        in: child.parent.context,
      )
    }

    expect(first.revision).toEqual(1)
    expect(first.albums.map(\.scope)).toEqual([.selectedTracks])
    expect(first.albums.map(\.selectedTrackCount)).toEqual([1])
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(1)
    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)

    let second = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveTrack = { lookup in
        try curationTrackResolution(lookup: lookup, album: album)
      }
    } operation: {
      try await ApproveMusicTrack.resolve(
        with: .init(
          childId: child.id,
          appleMusicTrackId: "track-2",
          preferredAlbumId: "album-1",
        ),
        in: child.parent.context,
      )
    }
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(second.revision).toEqual(2)
    expect(second.albums.map(\.scope)).toEqual([.wholeAlbum])
    expect(second.albums.map(\.selectedTrackCount)).toEqual([2])
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(1)
    expect(snapshot?.payload.albums[0].tracks.map(\.id)).toEqual(["track-1", "track-2"])
  }

  func testSaveAlbumSelectionNarrowsRemovesAndRejectsStaleRevision() async throws {
    let child = try await self.musicChild()
    let album = curationAlbum(
      id: "album-1",
      trackIds: ["track-1", "track-2", "track-3"],
    )
    let whole = try await withDependencies {
      $0.date.now = .reference
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await ApproveMusicAlbum_v2.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: album.id),
        in: child.parent.context,
      )
    }

    let narrowed = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: album.id,
          expectedRevision: whole.revision,
          selectedTrackIds: ["track-3", "track-1"],
        ),
        in: child.parent.context,
      )
    }

    expect(narrowed.status).toEqual(.updated)
    expect(narrowed.album.scope).toEqual(.selectedTracks)
    expect(narrowed.album.tracks.filter(\.isSelected).map(\.id))
      .toEqual(["track-1", "track-3"])
    expect(narrowed.curation.albums[0].selectedTrackCount).toEqual(2)
    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(2)

    let conflict = try await withDependencies {
      $0.date.now = .reference + 200
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: album.id,
          expectedRevision: whole.revision,
          selectedTrackIds: [],
        ),
        in: child.parent.context,
      )
    }

    expect(conflict.status).toEqual(.conflict)
    expect(conflict.curation.revision).toEqual(narrowed.curation.revision)
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(2)

    let removed = try await withDependencies {
      $0.date.now = .reference + 300
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: album.id,
          expectedRevision: narrowed.curation.revision,
          selectedTrackIds: [],
        ),
        in: child.parent.context,
      )
    }

    expect(removed.status).toEqual(.updated)
    expect(removed.album.scope).toEqual(.none)
    expect(removed.curation.albums).toEqual([])
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testSaveAlbumSelectionReturnsArtistCoveredWithoutMutation() async throws {
    let child = try await self.musicChild()
    let album = curationAlbum(id: "album-1", trackIds: ["track-1"])
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
      resolution: resolvedArtist(id: "artist-1", albums: [album]),
      resolvedAt: .reference,
    ))
    let snapshot = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await withDependencies {
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: album.id,
          expectedRevision: snapshot.revision,
          selectedTrackIds: [],
        ),
        in: child.parent.context,
      )
    }

    expect(output.status).toEqual(.coveredByArtist)
    expect(output.album.scope).toEqual(.artist)
    expect(output.album.governingArtistName).toEqual("Artist")
    expect(output.curation.revision).toEqual(snapshot.revision)
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testApproveAlbumDeletesCoveredAndManagedTrackGrants() async throws {
    let child = try await self.musicChild()
    let album = curationAlbum(id: "album-1", trackIds: ["shared-track"])
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "shared-track",
      preferredAlbumId: "alternate-album",
      resolution: resolvedTrackGrant(
        id: "shared-track",
        preferredAlbumId: "alternate-album",
      ),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "removed-track",
      preferredAlbumId: album.id,
      resolution: resolvedTrackGrant(
        id: "removed-track",
        preferredAlbumId: album.id,
      ),
      resolvedAt: .reference,
    ))
    _ = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await ApproveMusicAlbum_v2.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: album.id),
        in: child.parent.context,
      )
    }

    expect(output.albums.map(\.scope)).toEqual([.wholeAlbum])
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testArtistConfirmationReplacesOnlyExactCoveredGrants() async throws {
    let child = try await self.musicChild()
    let coveredAlbum = curationAlbum(id: "covered-album", trackIds: ["covered-track"])
    let outsideAlbum = curationAlbum(id: "outside-album", trackIds: ["outside-track"])
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
    let initial = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    let artist = resolvedArtist(id: "artist-1", albums: [coveredAlbum])

    let confirmation = try await withDependencies {
      $0.appleMusic.resolveArtist = { _ in artist }
    } operation: {
      try await ApproveMusicArtist_v2.resolve(
        with: .init(childId: child.id, appleMusicArtistId: artist.id),
        in: child.parent.context,
      )
    }

    expect(confirmation.status).toEqual(.confirmationRequired)
    expect(confirmation.confirmation?.revision).toEqual(initial.revision)
    expect(confirmation.confirmation?.albumCount).toEqual(1)
    expect(confirmation.confirmation?.trackCount).toEqual(1)
    await expect(try Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)

    let updated = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveArtist = { _ in artist }
    } operation: {
      try await ApproveMusicArtist_v2.resolve(
        with: .init(
          childId: child.id,
          appleMusicArtistId: artist.id,
          confirmationToken: confirmation.confirmation?.token,
        ),
        in: child.parent.context,
      )
    }

    expect(updated.status).toEqual(.updated)
    expect(updated.curation.revision).toEqual(initial.revision + 1)
    expect(updated.curation.artists.map(\.id)).toEqual(["artist-1"])
    expect(updated.curation.albums.map(\.id)).toEqual(["outside-album"])
    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .all(in: self.db)
      .map(\.appleMusicAlbumId)).toEqual(["outside-album"])
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testNarrowingAlbumPreservesArtworkSetting() async throws {
    let child = try await self.musicChild()
    let album = curationAlbum(
      id: "album-1",
      trackIds: ["track-1", "track-2"],
    )
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: album.id,
      title: album.title,
      artistName: album.artistName,
      artworkUrl: album.artworkUrl,
      artwork: album.artwork,
      trackCount: album.trackCount,
      showsArtwork: false,
      resolution: album,
      resolvedAt: .reference,
    ))
    let initial = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: album.id,
          expectedRevision: initial.revision,
          selectedTrackIds: ["track-1"],
        ),
        in: child.parent.context,
      )
    }
    let tracks = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .all(in: self.db)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(output.curation.albums[0].showsArtwork).toEqual(false)
    expect(tracks.map(\.showsArtwork)).toEqual([false])
    expect(snapshot?.payload.albums[0].showsArtwork).toEqual(false)
  }

  func testStaleCoveredApprovalsDoNotCreateGrantsOrAdvanceRevision() async throws {
    let child = try await self.musicChild()
    let album = curationAlbum(
      id: "album-1",
      trackIds: ["track-1", "track-2"],
    )
    let storedAlbum = curationAlbum(
      id: "album-1",
      trackIds: ["track-1"],
    )
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
      resolution: resolvedArtist(id: "artist-1", albums: [storedAlbum]),
      resolvedAt: .reference,
    ))
    let initial = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let trackOutput = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveTrack = { lookup in
        try curationTrackResolution(lookup: lookup, album: album)
      }
    } operation: {
      try await ApproveMusicTrack.resolve(
        with: .init(
          childId: child.id,
          appleMusicTrackId: "track-2",
          preferredAlbumId: album.id,
        ),
        in: child.parent.context,
      )
    }
    let albumOutput = try await withDependencies {
      $0.date.now = .reference + 200
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await ApproveMusicAlbum_v2.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: album.id),
        in: child.parent.context,
      )
    }
    let reloaded = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(trackOutput.revision).toEqual(initial.revision)
    expect(albumOutput.revision).toEqual(initial.revision)
    expect(reloaded?.revision).toEqual(initial.revision)
    expect(reloaded?.createdAt).toEqual(initial.createdAt)
    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
    await expect(try Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testSavingUnchangedWholeAlbumDoesNotAdvanceRevision() async throws {
    let child = try await self.musicChild()
    let album = curationAlbum(
      id: "album-1",
      trackIds: ["track-1", "track-2"],
    )
    let initial = try await withDependencies {
      $0.date.now = .reference
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await ApproveMusicAlbum_v2.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: album.id),
        in: child.parent.context,
      )
    }
    let beforeSave = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    let output = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveAlbum = { _ in album }
    } operation: {
      try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: album.id,
          expectedRevision: initial.revision,
          selectedTrackIds: album.tracks.map(\.id),
        ),
        in: child.parent.context,
      )
    }
    let afterSave = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    expect(output.status).toEqual(.updated)
    expect(output.curation.revision).toEqual(initial.revision)
    expect(afterSave?.revision).toEqual(initial.revision)
    expect(afterSave?.createdAt).toEqual(beforeSave?.createdAt)
  }

  func testApprovingSameExactTrackThroughAnotherAlbumMovesItsPreferredGrouping() async throws {
    let child = try await self.musicChild()
    let firstAlbum = curationAlbum(
      id: "album-1",
      trackIds: ["shared-track", "first-other"],
    )
    let secondAlbum = curationAlbum(
      id: "album-2",
      trackIds: ["second-other", "shared-track"],
    )

    let first = try await withDependencies {
      $0.date.now = .reference
      $0.appleMusic.resolveTrack = { lookup in
        try curationTrackResolution(lookup: lookup, album: firstAlbum)
      }
    } operation: {
      try await ApproveMusicTrack.resolve(
        with: .init(
          childId: child.id,
          appleMusicTrackId: "shared-track",
          preferredAlbumId: firstAlbum.id,
        ),
        in: child.parent.context,
      )
    }
    let moved = try await withDependencies {
      $0.date.now = .reference + 100
      $0.appleMusic.resolveTrack = { lookup in
        try curationTrackResolution(lookup: lookup, album: secondAlbum)
      }
    } operation: {
      try await ApproveMusicTrack.resolve(
        with: .init(
          childId: child.id,
          appleMusicTrackId: "shared-track",
          preferredAlbumId: secondAlbum.id,
        ),
        in: child.parent.context,
      )
    }
    let tracks = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .all(in: self.db)

    expect(first.albums.map(\.id)).toEqual(["album-1"])
    expect(moved.revision).toEqual(first.revision + 1)
    expect(moved.albums.map(\.id)).toEqual(["album-2"])
    expect(tracks.count).toEqual(1)
    expect(tracks[0].preferredAlbumId).toEqual("album-2")
    expect(tracks[0].resolution.catalogPosition).toEqual(1)
  }

  func testChildScopedSearchReturnsMixedExactAuthorizationStatuses() async throws {
    let child = try await self.musicChild()
    let wholeAlbum = curationAlbum(id: "whole-album", trackIds: ["whole-track"])
    let artistAlbum = curationAlbum(id: "artist-album", trackIds: ["artist-track"])
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "direct-track",
      preferredAlbumId: "partial-album",
      resolution: resolvedTrackGrant(
        id: "direct-track",
        preferredAlbumId: "partial-album",
      ),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: wholeAlbum.id,
      title: wholeAlbum.title,
      artistName: wholeAlbum.artistName,
      resolution: wholeAlbum,
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "allowed-artist",
      name: "Allowed Artist",
      resolution: .init(
        id: "allowed-artist",
        name: "Allowed Artist",
        topSongs: [],
        albums: [artistAlbum],
      ),
      resolvedAt: .reference,
    ))
    _ = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await withDependencies {
      $0.appleMusic.searchCatalog = { _ in
        let tracks = [
          searchTrack(id: "direct-track", albumId: "partial-album"),
          searchTrack(id: "whole-track", albumId: "whole-album"),
          searchTrack(id: "whole-new-track", albumId: "whole-album"),
          searchTrack(id: "artist-track", albumId: "artist-album"),
          searchTrack(id: "artist-new-track", albumId: "artist-album"),
          searchTrack(id: "available-track", albumId: "available-album"),
        ]
        let albums = [
          searchAlbum(id: "partial-album"),
          searchAlbum(id: "whole-album"),
          searchAlbum(id: "artist-album"),
          searchAlbum(id: "available-album"),
        ]
        let artists = [
          AppleMusicCatalogArtist(id: "allowed-artist", name: "Allowed Artist"),
          AppleMusicCatalogArtist(id: "available-artist", name: "Available Artist"),
        ]
        return .init(items: tracks.map(AppleMusicCatalogSearchItem.track)
          + albums.map(AppleMusicCatalogSearchItem.album)
          + artists.map(AppleMusicCatalogSearchItem.artist))
      }
    } operation: {
      try await SearchMusicCatalog_v2.resolve(
        with: .init(childId: child.id, query: "music", limit: 10),
        in: child.parent.context,
      )
    }

    expect(output.items.compactMap(\.track?.status.kind)).toEqual([
      .selected,
      .allowedWithAlbum,
      .allowedWithAlbum,
      .allowedWithArtist,
      .allowedWithArtist,
      .available,
    ])
    expect(output.items.compactMap(\.album?.status.kind)).toEqual([
      .selectedTracks,
      .wholeAlbum,
      .allowedWithArtist,
      .available,
    ])
    expect(output.items.compactMap(\.artist?.status)).toEqual([.allowed, .available])
    expect(output.items.compactMap(\.track?.status.governingArtistName))
      .toEqual(["Allowed Artist", "Allowed Artist"])
  }

  private func musicChild() async throws -> ChildEntities {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (_, install) = try await self.claimedMusicInstall(for: child)
    _ = try await self.db.create(MusicApp.Token(installId: install.id))
    return child
  }
}

private func curationAlbum(
  id: Music.AlbumId,
  trackIds: [Music.TrackId],
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: "Album \(id.rawValue)",
    artistName: "Artist",
    artistIds: ["artist-1"],
    artworkUrl: "https://example.com/\(id.rawValue).jpg",
    trackCount: trackIds.count,
    releaseDate: "2026-01-02",
    releaseType: "Album",
    tracks: trackIds.enumerated().map { index, trackId in
      .init(
        id: trackId,
        title: "Track \(index + 1)",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: id,
        albumTitle: "Album \(id.rawValue)",
        durationInMillis: 180_000,
        discNumber: 1,
        trackNumber: index + 1,
      )
    },
  )
}

private func searchTrack(
  id: Music.TrackId,
  albumId: Music.AlbumId,
) -> AppleMusicCatalogSearchTrack {
  .init(
    id: id,
    title: id.rawValue,
    artistName: "Artist",
    artistIds: ["artist-1"],
    preferredAlbumId: albumId,
    albumTitle: albumId.rawValue,
  )
}

private func searchAlbum(id: Music.AlbumId) -> AppleMusicCatalogAlbum {
  .init(
    id: id,
    title: id.rawValue,
    artistName: "Artist",
    trackCount: 3,
  )
}

private func curationTrackResolution(
  lookup: AppleMusicTrackResolutionLookup,
  album: Music.ResolvedAlbum,
) throws -> AppleMusicTrackResolution {
  let index = try XCTUnwrap(album.tracks.firstIndex { $0.id == lookup.trackId })
  return .init(
    grant: album.trackGrant(at: index),
    album: album,
  )
}
