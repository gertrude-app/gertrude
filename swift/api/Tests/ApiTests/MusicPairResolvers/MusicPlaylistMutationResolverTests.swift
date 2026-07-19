import Dependencies
import DuetSQL
import Foundation
import MusicRoute
import PairQL
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class MusicPlaylistMutationResolverTests: ApiTestCase, @unchecked Sendable {
  func testMutationRoutesMatch() throws {
    let token = UUID()
    let routes: [(String, Data, AuthedRoute)] = try [
      (
        CreateMusicPlaylist.name,
        JSONEncoder().encode(CreateMusicPlaylist.Input(name: "New")),
        .createMusicPlaylist(.init(name: "New")),
      ),
      (
        RenameMusicPlaylist.name,
        JSONEncoder().encode(RenameMusicPlaylist.Input(
          playlistId: UUID(1),
          expectedRevision: 2,
          name: "Renamed",
        )),
        .renameMusicPlaylist(.init(
          playlistId: UUID(1),
          expectedRevision: 2,
          name: "Renamed",
        )),
      ),
      (
        DeleteMusicPlaylist.name,
        JSONEncoder().encode(DeleteMusicPlaylist.Input(
          playlistId: UUID(1),
          expectedRevision: 2,
        )),
        .deleteMusicPlaylist(.init(playlistId: UUID(1), expectedRevision: 2)),
      ),
      (
        AddToMusicPlaylist.name,
        JSONEncoder().encode(AddToMusicPlaylist.Input(
          playlistId: UUID(1),
          source: .album(albumId: "album-1"),
        )),
        .addToMusicPlaylist(.init(
          playlistId: UUID(1),
          source: .album(albumId: "album-1"),
        )),
      ),
      (
        RemoveMusicPlaylistEntry.name,
        JSONEncoder().encode(RemoveMusicPlaylistEntry.Input(
          playlistId: UUID(1),
          expectedRevision: 2,
          entryId: UUID(2),
        )),
        .removeMusicPlaylistEntry(.init(
          playlistId: UUID(1),
          expectedRevision: 2,
          entryId: UUID(2),
        )),
      ),
      (
        ReorderMusicPlaylistEntries.name,
        JSONEncoder().encode(ReorderMusicPlaylistEntries.Input(
          playlistId: UUID(1),
          expectedRevision: 2,
          entryIds: [UUID(2)],
        )),
        .reorderMusicPlaylistEntries(.init(
          playlistId: UUID(1),
          expectedRevision: 2,
          entryIds: [UUID(2)],
        )),
      ),
    ]

    for (operation, body, expectedRoute) in routes {
      var request = URLRequest(url: URL(string: "gertrude-music/\(operation)")!)
      request.httpMethod = "POST"
      request.addValue(token.uuidString, forHTTPHeaderField: "X-MusicToken")
      request.httpBody = body

      let matched = try PairQLRoute.router.match(request: request)

      expect(matched).toEqual(.music(.authed(token, expectedRoute)))
    }
  }

  func testCreatesTrimmedEmptySameNamedPlaylists() async throws {
    let (_, ctx) = try await self.setup()

    _ = try await CreateMusicPlaylist.resolve(with: .init(name: "  Favorites  "), in: ctx)
    let output = try await CreateMusicPlaylist.resolve(with: .init(name: "Favorites"), in: ctx)
    let snapshot = try updatedSnapshot(output)

    expect(snapshot.playlists.map(\.name)).toEqual(["Favorites", "Favorites"])
    expect(snapshot.playlists.map(\.revision)).toEqual([1, 1])
    expect(snapshot.playlists.map(\.entries)).toEqual([[], []])
    let stored = try await Music.PlaylistRepository.playlists(for: ctx.child.id, in: self.db)
    expect(stored.map(\.name)).toEqual(["Favorites", "Favorites"])
  }

  func testAtomicallyCreatesPlaylistFromApprovedAlbumInSourceOrder() async throws {
    let (_, ctx) = try await self.setup(albums: [playlistResolvedAlbum(
      id: "album-1",
      tracks: [
        playlistResolvedTrack(id: "track-2", albumId: "album-1", title: "Two"),
        playlistResolvedTrack(id: "track-1", albumId: "album-1", title: "One"),
      ],
    )])

    let output = try await CreateMusicPlaylist.resolve(
      with: .init(name: "Album", source: .album(albumId: "album-1")),
      in: ctx,
    )
    let snapshot = try updatedSnapshot(output)

    expect(snapshot.playlists.first?.entries.map(\.track.id)).toEqual(["track-2", "track-1"])
    let playlists = try await Music.PlaylistRepository.playlists(
      for: ctx.child.id,
      in: self.db,
    )
    let playlistId = try XCTUnwrap(playlists.first?.id)
    let entries = try await Music.PlaylistRepository.entries(
      for: playlistId,
      in: self.db,
    )
    expect(entries.map(\.position)).toEqual([0, 1])
    expect(entries.map(\.preferredAlbumId)).toEqual(["album-1", "album-1"])
  }

  func testRejectsCraftedUnapprovedSelectionAndInvalidName() async throws {
    let (_, ctx) = try await self.setup()

    do {
      _ = try await CreateMusicPlaylist.resolve(
        with: .init(name: "Nope", source: .track(trackId: "track", albumId: "album")),
        in: ctx,
      )
      XCTFail("expected unauthorized selection")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }
    do {
      _ = try await CreateMusicPlaylist.resolve(with: .init(name: "bad\nname"), in: ctx)
      XCTFail("expected invalid name")
    } catch let error as PqlError {
      expect(error.type).toEqual(.badRequest)
    }
    await expect(try Music.PlaylistRepository.playlists(
      for: ctx.child.id,
      in: self.db,
    )).toEqual([])
  }

  func testIndividualDuplicateConfirmationAddAgainAndExactRemoval() async throws {
    let (_, ctx) = try await self.setup(albums: [playlistResolvedAlbum(
      id: "album-1",
      tracks: [playlistResolvedTrack(id: "track-1", albumId: "album-1")],
    )])
    let created = try await updatedSnapshot(CreateMusicPlaylist.resolve(
      with: .init(
        name: "Duplicates",
        source: .track(trackId: "track-1", albumId: "album-1"),
      ),
      in: ctx,
    ))
    let playlist = try XCTUnwrap(created.playlists.first)
    let originalEntryId = try XCTUnwrap(playlist.entries.first?.id)

    let confirmationOutput = try await AddToMusicPlaylist.resolve(
      with: .init(
        playlistId: playlist.id,
        source: .track(trackId: "track-1", albumId: "album-1"),
      ),
      in: ctx,
    )
    let (confirmationSnapshot, confirmation) = try duplicateConfirmation(confirmationOutput)
    expect(confirmationSnapshot.revision).toEqual(created.revision)
    expect(confirmation).toEqual(.track(
      playlistId: playlist.id,
      duplicate: .init(trackId: "track-1", title: "Track", existingCount: 1),
    ))

    let added = try await updatedSnapshot(AddToMusicPlaylist.resolve(
      with: .init(
        playlistId: playlist.id,
        source: .track(trackId: "track-1", albumId: "album-1"),
        duplicateResolution: .addAgain,
      ),
      in: ctx,
    ))
    let addedPlaylist = try XCTUnwrap(added.playlists.first)
    expect(addedPlaylist.entries.map(\.track.id)).toEqual(["track-1", "track-1"])
    XCTAssertEqual(Set(addedPlaylist.entries.map(\.id)).count, 2)

    let removed = try await updatedSnapshot(RemoveMusicPlaylistEntry.resolve(
      with: .init(
        playlistId: playlist.id,
        expectedRevision: addedPlaylist.revision,
        entryId: originalEntryId,
      ),
      in: ctx,
    ))
    let remaining = try XCTUnwrap(removed.playlists.first)
    expect(remaining.entries.map(\.id)).toEqual([addedPlaylist.entries[1].id])
    let storedEntries = try await Music.PlaylistRepository.entries(
      for: .init(rawValue: playlist.id),
      in: self.db,
    )
    expect(storedEntries.map(\.position)).toEqual([0])
  }

  func testWholeAlbumCanAddOnlyNewSongs() async throws {
    let (_, ctx) = try await self.setup(albums: [playlistResolvedAlbum(
      id: "album-1",
      tracks: [
        playlistResolvedTrack(id: "track-1", albumId: "album-1", title: "One"),
        playlistResolvedTrack(id: "track-2", albumId: "album-1", title: "Two"),
        playlistResolvedTrack(id: "track-3", albumId: "album-1", title: "Three"),
      ],
    )])
    let created = try await updatedSnapshot(CreateMusicPlaylist.resolve(
      with: .init(
        name: "Partial",
        source: .track(trackId: "track-2", albumId: "album-1"),
      ),
      in: ctx,
    ))
    let playlist = try XCTUnwrap(created.playlists.first)

    let confirmationOutput = try await AddToMusicPlaylist.resolve(
      with: .init(playlistId: playlist.id, source: .album(albumId: "album-1")),
      in: ctx,
    )
    let (_, confirmation) = try duplicateConfirmation(confirmationOutput)
    expect(confirmation).toEqual(.album(
      playlistId: playlist.id,
      albumId: "album-1",
      duplicates: [.init(trackId: "track-2", title: "Two", existingCount: 1)],
    ))

    let updated = try await updatedSnapshot(AddToMusicPlaylist.resolve(
      with: .init(
        playlistId: playlist.id,
        source: .album(albumId: "album-1"),
        duplicateResolution: .addOnlyNew,
      ),
      in: ctx,
    ))

    expect(updated.playlists.first?.entries.map(\.track.id)).toEqual([
      "track-2", "track-1", "track-3",
    ])
  }

  func testReordersExactEntryIdsAndRejectsStaleRevision() async throws {
    let (_, ctx) = try await self.setup(albums: [playlistResolvedAlbum(
      id: "album-1",
      tracks: [
        playlistResolvedTrack(id: "track-1", albumId: "album-1"),
        playlistResolvedTrack(id: "track-2", albumId: "album-1"),
        playlistResolvedTrack(id: "track-3", albumId: "album-1"),
      ],
    )])
    let created = try await updatedSnapshot(CreateMusicPlaylist.resolve(
      with: .init(name: "Order", source: .album(albumId: "album-1")),
      in: ctx,
    ))
    let playlist = try XCTUnwrap(created.playlists.first)
    let reversedIds = playlist.entries.map(\.id).reversed()

    let reordered = try await updatedSnapshot(ReorderMusicPlaylistEntries.resolve(
      with: .init(
        playlistId: playlist.id,
        expectedRevision: playlist.revision,
        entryIds: Array(reversedIds),
      ),
      in: ctx,
    ))
    let reorderedPlaylist = try XCTUnwrap(reordered.playlists.first)
    expect(reorderedPlaylist.entries.map(\.track.id)).toEqual(["track-3", "track-2", "track-1"])

    let stale = try await RenameMusicPlaylist.resolve(
      with: .init(
        playlistId: playlist.id,
        expectedRevision: playlist.revision,
        name: "Stale Rename",
      ),
      in: ctx,
    )
    guard case .conflict(let conflictSnapshot) = stale else {
      return XCTFail("expected conflict")
    }
    expect(conflictSnapshot.playlists.first?.name).toEqual("Order")
    expect(conflictSnapshot.playlists.first?.revision).toEqual(reorderedPlaylist.revision)
  }

  func testOtherChildCannotMutatePlaylist() async throws {
    let (_, ownerContext) = try await self.setup()
    let (otherChild, otherContext) = try await self.setup()
    let created = try await updatedSnapshot(CreateMusicPlaylist.resolve(
      with: .init(name: "Owner Only"),
      in: ownerContext,
    ))
    let playlist = try XCTUnwrap(created.playlists.first)

    let output = try await DeleteMusicPlaylist.resolve(
      with: .init(playlistId: playlist.id, expectedRevision: playlist.revision),
      in: otherContext,
    )

    guard case .conflict(let snapshot) = output else {
      return XCTFail("expected conflict")
    }
    expect(snapshot.playlists).toEqual([])
    await expect(try Music.PlaylistRepository.playlists(
      for: ownerContext.child.id,
      in: self.db,
    )).toHaveCount(1)
    await expect(try Music.PlaylistRepository.playlists(
      for: otherChild.id,
      in: self.db,
    )).toEqual([])
  }

  func testGrantRevocationRetainsOverlapThenRemovesFinalCoverage() async throws {
    let directAlbum = playlistResolvedAlbum(
      id: "album-1",
      title: "Preferred",
      tracks: [playlistResolvedTrack(id: "shared", albumId: "album-1", title: "Preferred")],
    )
    let overlappingAlbum = playlistResolvedAlbum(
      id: "album-2",
      title: "Fallback",
      tracks: [playlistResolvedTrack(id: "shared", albumId: "album-2", title: "Fallback")],
    )
    let (child, ctx) = try await self.setup(
      albums: [directAlbum],
      artists: [.init(
        id: "artist-1",
        name: "Artist",
        topSongs: [],
        albums: [overlappingAlbum],
      )],
    )
    let created = try await updatedSnapshot(CreateMusicPlaylist.resolve(
      with: .init(
        name: "Overlap",
        source: .track(trackId: "shared", albumId: "album-1"),
      ),
      in: ctx,
    ))
    let originalRevision = try XCTUnwrap(created.playlists.first?.revision)
    let childId = child.id

    let afterDirectRemoval = try await self.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: childId, in: db)
      _ = try await Music.ApprovedAlbum.query()
        .where(.childId == childId)
        .delete(in: db)
      return try await Music.LibrarySnapshotRepository.publish(
        childId: childId,
        generatedAt: .reference + 10,
        in: db,
      ).payload
    }

    expect(afterDirectRemoval.playlists.first?.entries.map(\.track.albumId)).toEqual(["album-2"])
    expect(afterDirectRemoval.playlists.first?.revision).toEqual(originalRevision)

    let afterFinalRemoval = try await self.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: childId, in: db)
      _ = try await Music.ApprovedArtist.query()
        .where(.childId == childId)
        .delete(in: db)
      return try await Music.LibrarySnapshotRepository.publish(
        childId: childId,
        generatedAt: .reference + 20,
        in: db,
      ).payload
    }

    expect(afterFinalRemoval.playlists.first?.entries).toEqual([])
    expect(afterFinalRemoval.playlists.first?.revision).toEqual(originalRevision + 1)
    await expect(try Music.PlaylistRepository.entries(
      for: .init(rawValue: XCTUnwrap(afterFinalRemoval.playlists.first?.id)),
      in: self.db,
    )).toEqual([])
  }

  private func setup(
    albums: [Music.ResolvedAlbum] = [],
    artists: [Music.ResolvedArtist] = [],
  ) async throws -> (ChildEntities, MusicApp.InstallContext) {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let ctx = try await self.musicContext(for: child)
    for album in albums {
      _ = try await self.db.create(Music.ApprovedAlbum(
        childId: child.id,
        appleMusicAlbumId: album.id,
        title: album.title,
        artistName: album.artistName,
        resolution: album,
        resolvedAt: .reference,
      ))
    }
    for artist in artists {
      _ = try await self.db.create(Music.ApprovedArtist(
        childId: child.id,
        appleMusicArtistId: artist.id,
        name: artist.name,
        resolution: artist,
        resolvedAt: .reference,
      ))
    }
    return (child, ctx)
  }
}

private func updatedSnapshot(
  _ output: MusicPlaylistMutationOutput,
  file: StaticString = #filePath,
  line: UInt = #line,
) throws -> MusicLibrarySnapshot {
  guard case .updated(let snapshot) = output else {
    XCTFail("expected updated snapshot", file: file, line: line)
    throw PlaylistMutationTestError.unexpectedOutput
  }
  return snapshot
}

private func duplicateConfirmation(
  _ output: MusicPlaylistMutationOutput,
  file: StaticString = #filePath,
  line: UInt = #line,
) throws -> (MusicLibrarySnapshot, MusicPlaylistDuplicateConfirmation) {
  guard case .duplicateConfirmationRequired(let snapshot, let confirmation) = output else {
    XCTFail("expected duplicate confirmation", file: file, line: line)
    throw PlaylistMutationTestError.unexpectedOutput
  }
  return (snapshot, confirmation)
}

private enum PlaylistMutationTestError: Error {
  case unexpectedOutput
}

private func playlistResolvedAlbum(
  id: Music.AlbumId,
  title: String = "Album",
  tracks: [Music.ResolvedTrack],
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    trackCount: tracks.count,
    tracks: tracks,
  )
}

private func playlistResolvedTrack(
  id: Music.TrackId,
  albumId: Music.AlbumId,
  title: String = "Track",
) -> Music.ResolvedTrack {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    albumId: albumId,
    albumTitle: albumId.rawValue,
  )
}
