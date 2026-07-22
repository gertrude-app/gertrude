import Foundation
import MusicRoute
import XCTest
import XExpect

@testable import Api

final class MusicCatalogCompilerTests: XCTestCase {
  func testEmptyLibrary() throws {
    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [],
    )

    expect(content.albums).toEqual([])
    expect(content.artists).toEqual([])
  }

  func testDirectAlbumIncludesCompleteOrderedTracks() throws {
    let album = resolvedAlbum(
      id: "album-1",
      title: "Direct",
      artworkUrl: "https://example.com/album.jpg",
      tracks: [
        resolvedTrack(id: "track-2", albumId: "album-1", title: "Second"),
        resolvedTrack(
          id: "track-1",
          albumId: "album-1",
          title: "First",
          artworkUrl: "https://example.com/track.jpg",
        ),
      ],
    )

    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: .reference,
        showsArtwork: false,
        resolution: album,
      )],
      artistGrants: [],
    )

    expect(content.albums).toEqual([
      .init(
        id: "album-1",
        title: "Direct",
        artistName: "Artist",
        artworkUrl: "https://example.com/album.jpg",
        trackCount: 2,
        releaseDate: "2026-01-02",
        releaseType: "Album",
        showsArtwork: false,
        addedAt: .reference,
        tracks: [
          .init(
            id: "track-2",
            title: "Second",
            artistName: "Artist",
            albumId: "album-1",
            albumTitle: "Direct",
            artworkUrl: "https://example.com/album.jpg",
            durationInMillis: 180_000,
          ),
          .init(
            id: "track-1",
            title: "First",
            artistName: "Artist",
            albumId: "album-1",
            albumTitle: "Direct",
            artworkUrl: "https://example.com/track.jpg",
            durationInMillis: 180_000,
          ),
        ],
      ),
    ])
  }

  func testArtistAlbumsAndTopSongsPreserveOrderAndFilterToCoverage() throws {
    let firstAlbum = resolvedAlbum(
      id: "album-1",
      title: "First",
      tracks: [resolvedTrack(id: "song-1", albumId: "album-1", title: "One")],
    )
    let secondAlbum = resolvedAlbum(
      id: "album-2",
      title: "Second",
      tracks: [resolvedTrack(id: "song-2", albumId: "album-2", title: "Two")],
    )
    let artist = Music.ResolvedArtist(
      id: "artist-1",
      name: "Artist",
      catalogMetadata: .init(genreNames: ["Folk"]),
      topSongs: [
        resolvedTrack(id: "song-2", albumId: "album-2", title: "Two"),
        resolvedTrack(id: "song-1", albumId: "album-1", title: "One"),
        resolvedTrack(id: "song-2", albumId: "album-2", title: "Duplicate"),
        resolvedTrack(id: "uncovered", albumId: "album-3", title: "Uncovered"),
      ],
      albums: [secondAlbum, firstAlbum, secondAlbum],
    )

    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [.init(
        appleMusicArtistId: "artist-1",
        createdAt: .reference,
        resolution: artist,
      )],
    )

    expect(content.albums.map(\.id)).toEqual(["album-2", "album-1"])
    expect(content.albums.map(\.showsArtwork)).toEqual([true, true])
    expect(content.artists.map(\.releaseAlbumIds)).toEqual([["album-2", "album-1"]])
    expect(content.artists.first?.topSongs.map(\.id)).toEqual(["song-2", "song-1"])
    expect(content.artists.first?.addedAt).toEqual(.reference)
    expect(content.artists.first?.catalogMetadata?.genreNames).toEqual(["Folk"])
  }

  func testOverlapUsesDirectMetadataAndNewestApplicableGrantDate() throws {
    let directDate = Date.reference + 100
    let artistDate = Date.reference + 200
    let direct = resolvedAlbum(id: "album-1", title: "Direct title")
    let artistAlbum = resolvedAlbum(id: "album-1", title: "Artist title")
    let artist = resolvedArtist(id: "artist-1", albums: [artistAlbum])

    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: directDate,
        showsArtwork: false,
        resolution: direct,
      )],
      artistGrants: [.init(
        appleMusicArtistId: "artist-1",
        createdAt: artistDate,
        resolution: artist,
      )],
    )

    expect(content.albums).toHaveCount(1)
    expect(content.albums.first?.title).toEqual("Direct title")
    expect(content.albums.first?.showsArtwork).toEqual(false)
    expect(content.albums.first?.addedAt).toEqual(artistDate)
  }

  func testRemovingOneOverlappingGrantRetainsOtherCoverage() throws {
    let album = resolvedAlbum(id: "album-1", title: "Direct")
    let artistAlbum = resolvedAlbum(id: "album-1", title: "Artist")
    let artistGrant = Music.LibrarySnapshotCompiler.ArtistGrant(
      appleMusicArtistId: "artist-1",
      createdAt: .reference,
      resolution: resolvedArtist(id: "artist-1", albums: [artistAlbum]),
    )
    let withBoth = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: .reference + 100,
        showsArtwork: false,
        resolution: album,
      )],
      artistGrants: [artistGrant],
    )
    let afterDirectRemoval = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [artistGrant],
    )

    expect(withBoth.albums.map(\.id)).toEqual(["album-1"])
    expect(withBoth.albums.first?.title).toEqual("Direct")
    expect(afterDirectRemoval.albums.map(\.id)).toEqual(["album-1"])
    expect(afterDirectRemoval.albums.first?.title).toEqual("Artist")
  }

  func testExactIdDeduplicationIsStable() throws {
    let duplicatedTrack = resolvedTrack(id: "track-1", albumId: "album-1")
    let direct = resolvedAlbum(
      id: "album-1",
      title: "Direct",
      tracks: [duplicatedTrack, duplicatedTrack],
    )
    let olderArtist = resolvedArtist(
      id: "artist-2",
      albums: [resolvedAlbum(id: "album-2", title: "Older")],
    )
    let newerArtist = resolvedArtist(
      id: "artist-1",
      albums: [
        resolvedAlbum(id: "album-2", title: "Duplicate"),
        resolvedAlbum(id: "album-3", title: "Newer"),
      ],
    )

    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: .reference,
        showsArtwork: true,
        resolution: direct,
      )],
      artistGrants: [
        .init(
          appleMusicArtistId: "artist-1",
          createdAt: .reference + 20,
          resolution: newerArtist,
        ),
        .init(
          appleMusicArtistId: "artist-2",
          createdAt: .reference + 10,
          resolution: olderArtist,
        ),
      ],
    )

    expect(content.albums.map(\.id)).toEqual(["album-1", "album-2", "album-3"])
    expect(content.albums[0].tracks.map(\.id)).toEqual(["track-1"])
    expect(content.albums[1].title).toEqual("Older")
    expect(content.artists.map(\.id)).toEqual(["artist-2", "artist-1"])
  }

  func testDuplicateArtistGrantDoesNotUnionCoverage() throws {
    let older = resolvedArtist(
      id: "artist-1",
      albums: [resolvedAlbum(id: "album-1", title: "First")],
    )
    let duplicate = resolvedArtist(
      id: "artist-1",
      albums: [resolvedAlbum(id: "album-2", title: "Duplicate")],
    )

    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [
        .init(
          appleMusicArtistId: "artist-1",
          createdAt: .reference,
          resolution: older,
        ),
        .init(
          appleMusicArtistId: "artist-1",
          createdAt: .reference + 100,
          resolution: duplicate,
        ),
      ],
    )

    expect(content.artists).toHaveCount(1)
    expect(content.artists.first?.releaseAlbumIds).toEqual(["album-1"])
    expect(content.artists.first?.addedAt).toEqual(.reference + 100)
    expect(content.albums.map(\.id)).toEqual(["album-1"])
  }

  func testMissingResolutionRefusesPartialPublication() throws {
    XCTAssertThrowsError(try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: .reference,
        showsArtwork: true,
        resolution: nil,
      )],
      artistGrants: [],
    )) { error in
      expect(error as? Music.LibrarySnapshotCompiler.CompilerError)
        .toEqual(.missingAlbumResolution("album-1"))
    }

    XCTAssertThrowsError(try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [.init(
        appleMusicArtistId: "artist-1",
        createdAt: .reference,
        resolution: nil,
      )],
    )) { error in
      expect(error as? Music.LibrarySnapshotCompiler.CompilerError)
        .toEqual(.missingArtistResolution("artist-1"))
    }
  }

  func testMismatchedResolutionAndTrackProvenanceAreRejected() throws {
    XCTAssertThrowsError(try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: .reference,
        showsArtwork: true,
        resolution: resolvedAlbum(id: "album-2"),
      )],
      artistGrants: [],
    )) { error in
      expect(error as? Music.LibrarySnapshotCompiler.CompilerError).toEqual(
        .albumResolutionIdMismatch(expected: "album-1", actual: "album-2"),
      )
    }

    let malformed = resolvedAlbum(
      id: "album-1",
      tracks: [resolvedTrack(id: "track-1", albumId: "album-2")],
    )
    XCTAssertThrowsError(try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: .reference,
        showsArtwork: true,
        resolution: malformed,
      )],
      artistGrants: [],
    )) { error in
      expect(error as? Music.LibrarySnapshotCompiler.CompilerError).toEqual(
        .trackAlbumIdMismatch(track: "track-1", expected: "album-1", actual: "album-2"),
      )
    }
  }

  func testContentEqualityIgnoresRevisionAndGenerationTime() throws {
    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-1",
        createdAt: .reference,
        showsArtwork: true,
        resolution: resolvedAlbum(id: "album-1"),
      )],
      artistGrants: [],
    )
    let oldSnapshot = content.snapshot(revision: 41, generatedAt: .reference)
    let newerSnapshot = content.snapshot(revision: 42, generatedAt: .reference + 100)

    expect(oldSnapshot.hasSameContent(as: content)).toEqual(true)
    expect(newerSnapshot.hasSameContent(as: content)).toEqual(true)

    var changed = content
    changed.albums[0].title = "Changed"
    expect(oldSnapshot.hasSameContent(as: changed)).toEqual(false)
  }
}

private func resolvedArtist(
  id: Music.ArtistId,
  albums: [Music.ResolvedAlbum],
) -> Music.ResolvedArtist {
  .init(id: id, name: "Artist", topSongs: [], albums: albums)
}

private func resolvedAlbum(
  id: Music.AlbumId,
  title: String = "Album",
  artworkUrl: String? = nil,
  tracks: [Music.ResolvedTrack]? = nil,
) -> Music.ResolvedAlbum {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    artworkUrl: artworkUrl,
    trackCount: tracks?.count ?? 1,
    releaseDate: "2026-01-02",
    releaseType: "Album",
    tracks: tracks ?? [resolvedTrack(id: "\(id.rawValue)-track", albumId: id)],
  )
}

private func resolvedTrack(
  id: Music.TrackId,
  albumId: Music.AlbumId,
  title: String = "Track",
  artworkUrl: String? = nil,
) -> Music.ResolvedTrack {
  .init(
    id: id,
    title: title,
    artistName: "Artist",
    artistIds: ["artist-1"],
    albumId: albumId,
    albumTitle: albumId == "album-1" ? "Direct" : "Album",
    artworkUrl: artworkUrl,
    durationInMillis: 180_000,
  )
}
