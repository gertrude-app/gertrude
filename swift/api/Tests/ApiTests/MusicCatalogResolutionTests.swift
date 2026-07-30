import Foundation
import XCTest
import XExpect

@testable import Api

final class MusicCatalogResolutionTests: XCTestCase {
  func testLegacyAlbumResolutionDecodesWithoutNewTrackMetadata() throws {
    let data = Data(
      #"""
      {
        "id": "album-1",
        "title": "Album",
        "artistName": "Artist",
        "artistIds": ["artist-1"],
        "artworkUrl": "https://example.com/album.jpg",
        "trackCount": 1,
        "tracks": [
          {
            "id": "track-1",
            "title": "Track",
            "artistName": "Artist",
            "artistIds": ["artist-1"],
            "albumId": "album-1",
            "albumTitle": "Album",
            "durationInMillis": 180000
          }
        ]
      }
      """#.utf8,
    )

    let decoded = try JSONDecoder().decode(Music.ResolvedAlbum.self, from: data)

    expect(decoded).toEqual(.init(
      id: "album-1",
      title: "Album",
      artistName: "Artist",
      artistIds: ["artist-1"],
      artworkUrl: "https://example.com/album.jpg",
      trackCount: 1,
      tracks: [.init(
        id: "track-1",
        title: "Track",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: "album-1",
        albumTitle: "Album",
        durationInMillis: 180_000,
      )],
    ))
  }

  func testCompactTrackGrantRoundTripsAllMetadata() throws {
    let expected = resolvedTrackGrant()

    let encoded = try JSONEncoder().encode(expected)
    let decoded = try JSONDecoder().decode(Music.ResolvedTrackGrant.self, from: encoded)

    expect(decoded).toEqual(expected)
  }

  func testTrackGrantValidationChecksStoredIdentityAndCatalogPosition() throws {
    let grant = resolvedTrackGrant()

    XCTAssertNoThrow(try grant.validate(
      appleMusicTrackId: "track-1",
      preferredAlbumId: "album-1",
    ))

    XCTAssertThrowsError(try grant.validate(
      appleMusicTrackId: "track-2",
      preferredAlbumId: "album-1",
    )) { error in
      expect(error as? Music.ResolvedTrackGrant.ValidationError).toEqual(
        .trackIdMismatch(expected: "track-2", actual: "track-1"),
      )
    }

    XCTAssertThrowsError(try grant.validate(
      appleMusicTrackId: "track-1",
      preferredAlbumId: "album-2",
    )) { error in
      expect(error as? Music.ResolvedTrackGrant.ValidationError).toEqual(
        .preferredAlbumIdMismatch(expected: "album-2", actual: "album-1"),
      )
    }

    var mismatchedAlbum = grant
    mismatchedAlbum.track.albumId = "album-2"
    XCTAssertThrowsError(try mismatchedAlbum.validate(
      appleMusicTrackId: "track-1",
      preferredAlbumId: "album-1",
    )) { error in
      expect(error as? Music.ResolvedTrackGrant.ValidationError).toEqual(
        .trackAlbumIdMismatch(
          track: "track-1",
          expected: "album-1",
          actual: "album-2",
        ),
      )
    }

    let invalidPosition = resolvedTrackGrant(catalogPosition: -1)
    XCTAssertThrowsError(try invalidPosition.validate(
      appleMusicTrackId: "track-1",
      preferredAlbumId: "album-1",
    )) { error in
      expect(error as? Music.ResolvedTrackGrant.ValidationError).toEqual(
        .invalidCatalogPosition(-1),
      )
    }
  }
}

private func resolvedTrackGrant(
  catalogPosition: Int = 6,
) -> Music.ResolvedTrackGrant {
  .init(
    track: .init(
      id: "track-1",
      title: "Track",
      artistName: "Artist",
      artistIds: ["artist-1"],
      albumId: "album-1",
      albumTitle: "Album",
      artworkUrl: "https://example.com/track.jpg",
      durationInMillis: 180_000,
      discNumber: 1,
      trackNumber: 7,
      contentRating: .explicit,
      appleMusicUrl: "https://music.apple.com/us/album/album/1?i=2",
    ),
    preferredAlbum: .init(
      id: "album-1",
      title: "Album",
      artistName: "Artist",
      artistIds: ["artist-1"],
      artworkUrl: "https://example.com/album.jpg",
      artwork: .init(
        url: "https://example.com/{w}x{h}.jpg",
        width: 1200,
        height: 1200,
      ),
      trackCount: 12,
      releaseDate: "2026-01-02",
      releaseType: "Album",
      appleMusicUrl: "https://music.apple.com/us/album/album/1",
    ),
    catalogPosition: catalogPosition,
  )
}
