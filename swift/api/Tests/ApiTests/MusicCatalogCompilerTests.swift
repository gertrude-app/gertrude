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

  func testArtistScopeWinsOverOverlappingDirectAlbum() throws {
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
    expect(content.albums.first?.title).toEqual("Artist title")
    expect(content.albums.first?.showsArtwork).toEqual(true)
    expect(content.albums.first?.addedAt).toEqual(artistDate)
  }

  func testRemovingOverlappingDirectGrantDoesNotChangeArtistCoverage() throws {
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
    expect(withBoth.albums.first?.title).toEqual("Artist")
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
    expect(content.albums[1].title).toEqual("Duplicate")
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

  func testDirectTracksCreateOnePartialAlbumInCatalogOrder() throws {
    let first = compilerTrackGrant(
      id: "track-1",
      preferredAlbumId: "partial-album",
      createdAt: .reference + 20,
      showsArtwork: false,
      albumTitle: "Partial Album",
      albumTrackCount: 8,
      albumArtworkUrl: "https://example.com/album.jpg",
      trackTitle: "First",
      catalogPosition: 0,
    )
    let second = compilerTrackGrant(
      id: "track-2",
      preferredAlbumId: "partial-album",
      createdAt: .reference,
      showsArtwork: false,
      albumTitle: "Partial Album",
      albumTrackCount: 8,
      albumArtworkUrl: "https://example.com/album.jpg",
      trackTitle: "Second",
      trackArtworkUrl: "https://example.com/second.jpg",
      discNumber: 1,
      trackNumber: 2,
      catalogPosition: 2,
    )
    let third = compilerTrackGrant(
      id: "track-3",
      preferredAlbumId: "partial-album",
      createdAt: .reference + 10,
      showsArtwork: false,
      albumTitle: "Partial Album",
      albumTrackCount: 8,
      albumArtworkUrl: "https://example.com/album.jpg",
      trackTitle: "Third",
      discNumber: 2,
      trackNumber: 1,
      catalogPosition: 2,
    )
    let tied = compilerTrackGrant(
      id: "track-0",
      preferredAlbumId: "partial-album",
      createdAt: .reference + 30,
      showsArtwork: false,
      albumTitle: "Partial Album",
      albumTrackCount: 8,
      albumArtworkUrl: "https://example.com/album.jpg",
      trackTitle: "Tied",
      discNumber: 1,
      trackNumber: 2,
      catalogPosition: 2,
    )

    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [],
      trackGrants: [third, first, second, tied],
    )

    expect(content.albums).toHaveCount(1)
    expect(content.albums[0].id).toEqual("partial-album")
    expect(content.albums[0].title).toEqual("Partial Album")
    expect(content.albums[0].trackCount).toEqual(8)
    expect(content.albums[0].showsArtwork).toEqual(false)
    expect(content.albums[0].addedAt).toEqual(.reference)
    expect(content.albums[0].tracks.map(\.id)).toEqual([
      "track-1",
      "track-0",
      "track-2",
      "track-3",
    ])
    expect(content.albums[0].tracks.map(\.artworkUrl)).toEqual([
      "https://example.com/album.jpg",
      "https://example.com/album.jpg",
      "https://example.com/second.jpg",
      "https://example.com/album.jpg",
    ])
    expect(content.albums[0].tracks.map(\.discNumber)).toEqual([nil, 1, 1, 2])
    expect(content.albums[0].tracks.map(\.trackNumber)).toEqual([nil, 2, 2, 1])
  }

  func testCurrentAllTrackGrantSetDoesNotRequireAlbumScope() throws {
    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [],
      trackGrants: [compilerTrackGrant(
        id: "only-track",
        preferredAlbumId: "single-album",
        createdAt: .reference,
        albumTrackCount: 1,
      )],
    )

    expect(content.albums.map(\.id)).toEqual(["single-album"])
    expect(content.albums[0].trackCount).toEqual(1)
    expect(content.albums[0].tracks.map(\.id)).toEqual(["only-track"])
  }

  func testAlbumGrantSuppressesCoveredTrackWithDifferentPreferredAlbum() throws {
    let album = resolvedAlbum(
      id: "album-a",
      tracks: [resolvedTrack(id: "shared-track", albumId: "album-a")],
    )
    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [.init(
        appleMusicAlbumId: "album-a",
        createdAt: .reference,
        showsArtwork: true,
        resolution: album,
      )],
      artistGrants: [],
      trackGrants: [compilerTrackGrant(
        id: "shared-track",
        preferredAlbumId: "album-b",
        createdAt: .reference + 10,
      )],
    )

    expect(content.albums.map(\.id)).toEqual(["album-a"])
    expect(content.albums[0].tracks.map(\.id)).toEqual(["shared-track"])
  }

  func testArtistAlbumMergesUncoveredTrackWithoutLosingWiderMetadata() throws {
    let artistAlbum = resolvedAlbum(
      id: "album-1",
      title: "Artist Album",
      tracks: [resolvedTrack(id: "artist-track", albumId: "album-1")],
    )
    let artistGrant = Music.LibrarySnapshotCompiler.ArtistGrant(
      appleMusicArtistId: "artist-1",
      createdAt: .reference + 20,
      resolution: resolvedArtist(id: "artist-1", albums: [artistAlbum]),
    )
    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [artistGrant],
      trackGrants: [
        compilerTrackGrant(
          id: "artist-track",
          preferredAlbumId: "alternate-album",
          createdAt: .reference,
          catalogPosition: 0,
        ),
        compilerTrackGrant(
          id: "extra-track",
          preferredAlbumId: "album-1",
          createdAt: .reference + 10,
          catalogPosition: 1,
        ),
      ],
    )

    expect(content.albums).toHaveCount(1)
    expect(content.albums[0].title).toEqual("Artist Album")
    expect(content.albums[0].showsArtwork).toEqual(true)
    expect(content.albums[0].addedAt).toEqual(.reference + 20)
    expect(content.albums[0].tracks.map(\.id)).toEqual(["artist-track", "extra-track"])
  }

  func testDuplicateTrackGrantUsesNewestPreferredAlbum() throws {
    let older = compilerTrackGrant(
      id: "shared-track",
      preferredAlbumId: "album-a",
      createdAt: .reference,
      albumTitle: "Older",
    )
    let newer = compilerTrackGrant(
      id: "shared-track",
      preferredAlbumId: "album-b",
      createdAt: .reference + 10,
      albumTitle: "Newer",
    )

    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [],
      trackGrants: [newer, older],
    )

    expect(content.albums.map(\.id)).toEqual(["album-b"])
    expect(content.albums[0].title).toEqual("Newer")
    expect(content.albums[0].tracks.map(\.id)).toEqual(["shared-track"])
  }

  func testPartialAlbumPlaylistExcludesUnselectedTrack() throws {
    let content = try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [],
      trackGrants: [compilerTrackGrant(
        id: "allowed-track",
        preferredAlbumId: "partial-album",
        createdAt: .reference,
        albumTrackCount: 2,
      )],
      playlists: [.init(
        id: UUID(1),
        name: "Favorites",
        revision: 1,
        createdAt: .reference,
        updatedAt: .reference,
        entries: [
          .init(id: UUID(2), trackId: "allowed-track", preferredAlbumId: "partial-album"),
          .init(id: UUID(3), trackId: "unselected-track", preferredAlbumId: "partial-album"),
        ],
      )],
    )

    expect(content.albums[0].tracks.map(\.id)).toEqual(["allowed-track"])
    expect(content.playlists[0].entries.map(\.id)).toEqual([UUID(2)])
    expect(content.playlists[0].entries.map(\.track.id)).toEqual(["allowed-track"])
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

    let trackResolution = resolvedTrackGrant(
      id: "track-1",
      preferredAlbumId: "album-1",
    )
    XCTAssertThrowsError(try Music.LibrarySnapshotCompiler.compile(
      albumGrants: [],
      artistGrants: [],
      trackGrants: [.init(
        appleMusicTrackId: "track-1",
        preferredAlbumId: "album-2",
        createdAt: .reference,
        showsArtwork: true,
        resolution: trackResolution,
      )],
    )) { error in
      expect(error as? Music.LibrarySnapshotCompiler.CompilerError).toEqual(
        .invalidTrackResolution(
          .preferredAlbumIdMismatch(expected: "album-2", actual: "album-1"),
        ),
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

private func compilerTrackGrant(
  id: Music.TrackId,
  preferredAlbumId: Music.AlbumId,
  createdAt: Date,
  showsArtwork: Bool = true,
  albumTitle: String = "Album",
  albumTrackCount: Int = 1,
  albumArtworkUrl: String? = nil,
  trackTitle: String = "Track",
  trackArtworkUrl: String? = nil,
  discNumber: Int? = nil,
  trackNumber: Int? = nil,
  catalogPosition: Int = 0,
) -> Music.LibrarySnapshotCompiler.TrackGrant {
  .init(
    appleMusicTrackId: id,
    preferredAlbumId: preferredAlbumId,
    createdAt: createdAt,
    showsArtwork: showsArtwork,
    resolution: resolvedTrackGrant(
      id: id,
      preferredAlbumId: preferredAlbumId,
      albumTitle: albumTitle,
      albumTrackCount: albumTrackCount,
      albumArtworkUrl: albumArtworkUrl,
      trackTitle: trackTitle,
      trackArtworkUrl: trackArtworkUrl,
      discNumber: discNumber,
      trackNumber: trackNumber,
      catalogPosition: catalogPosition,
    ),
  )
}
