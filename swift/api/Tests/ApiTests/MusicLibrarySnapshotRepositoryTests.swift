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

  func testPublishesPersistedTrackGrantAsPartialAlbum() async throws {
    let child = try await self.child()
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "selected-track",
      preferredAlbumId: "partial-album",
      resolution: resolvedTrackGrant(
        id: "selected-track",
        preferredAlbumId: "partial-album",
        albumTitle: "Partial Album",
        albumTrackCount: 4,
        albumArtworkUrl: "https://example.com/album.jpg",
        trackTitle: "Selected Track",
        catalogPosition: 2,
      ),
      showsArtwork: false,
      resolvedAt: .reference,
    ))

    let snapshot = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    expect(snapshot.revision).toEqual(1)
    expect(snapshot.payload.albums).toHaveCount(1)
    expect(snapshot.payload.albums[0].id).toEqual("partial-album")
    expect(snapshot.payload.albums[0].title).toEqual("Partial Album")
    expect(snapshot.payload.albums[0].trackCount).toEqual(4)
    expect(snapshot.payload.albums[0].showsArtwork).toEqual(false)
    expect(snapshot.payload.albums[0].tracks.map(\.id)).toEqual(["selected-track"])
  }

  func testPartialTrackPublicationReconcilesPlaylistToSelectedTracks() async throws {
    let child = try await self.child()
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "selected-track",
      preferredAlbumId: "partial-album",
      resolution: resolvedTrackGrant(
        id: "selected-track",
        preferredAlbumId: "partial-album",
        albumTrackCount: 2,
      ),
      resolvedAt: .reference,
    ))
    let playlist = try await self.db.create(Music.Playlist(
      childId: child.id,
      name: "Favorites",
      createdAt: .reference,
      updatedAt: .reference,
    ))
    let selectedEntry = try await self.db.create(Music.PlaylistEntry(
      playlistId: playlist.id,
      position: 0,
      appleMusicTrackId: "selected-track",
      preferredAlbumId: "partial-album",
      createdAt: .reference,
    ))
    _ = try await self.db.create(Music.PlaylistEntry(
      playlistId: playlist.id,
      position: 1,
      appleMusicTrackId: "unselected-track",
      preferredAlbumId: "partial-album",
      createdAt: .reference,
    ))

    let snapshot = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    let storedEntries = try await Music.PlaylistRepository.entries(
      for: playlist.id,
      in: self.db,
    )

    expect(snapshot.payload.playlists[0].entries.map(\.id))
      .toEqual([selectedEntry.id.rawValue])
    expect(snapshot.payload.playlists[0].entries.map(\.track.id))
      .toEqual(["selected-track"])
    expect(storedEntries.map(\.id)).toEqual([selectedEntry.id])
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

  func testPublishAfterPolicyChangeAdvancesUnchangedContentRevision() async throws {
    let child = try await self.child()
    let album = snapshotResolvedAlbum(id: "album-1")
    let coveredAlbum = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: album.title,
      artistName: album.artistName,
      resolution: album,
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
      resolution: .init(
        id: "artist-1",
        name: "Artist",
        topSongs: [],
        albums: [album],
      ),
      resolvedAt: .reference,
    ))
    let first = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    try await Music.ApprovedAlbum.query()
      .where(.id == coveredAlbum.id)
      .delete(in: self.db)
    let canonicalContent = try await Music.LibrarySnapshotRepository.catalogContent(
      for: child.id,
      in: self.db,
    )

    expect(first.payload.hasSameContent(as: canonicalContent)).toEqual(true)

    let advanced = try await Music.LibrarySnapshotRepository.publishAfterPolicyChange(
      childId: child.id,
      generatedAt: .reference + 100,
      in: self.db,
    )

    expect(advanced.id).toEqual(first.id)
    expect(advanced.revision).toEqual(first.revision + 1)
    expect(advanced.payload.revision).toEqual(first.payload.revision + 1)
    expect(advanced.payload.hasSameContent(as: canonicalContent)).toEqual(true)
    expect(advanced.createdAt).toEqual(.reference + 100)
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
