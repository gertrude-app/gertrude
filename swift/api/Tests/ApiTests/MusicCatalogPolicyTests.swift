import XCTest
import XExpect

@testable import Api

final class MusicCatalogPolicyTests: XCTestCase {
  func testWidestExactScopeGovernsAlbumsAndTracks() throws {
    let artistAlbum = resolvedAlbum(
      id: "artist-album",
      tracks: [resolvedTrack(id: "artist-track", albumId: "artist-album")],
    )
    let artistGrant = Policy.ArtistGrant(
      appleMusicArtistId: "artist-1",
      resolution: resolvedArtist(id: "artist-1", albums: [artistAlbum]),
    )
    let coveredAlbumGrant = Policy.AlbumGrant(
      appleMusicAlbumId: "artist-album",
      resolution: artistAlbum,
    )
    let directAlbum = resolvedAlbum(
      id: "direct-album",
      tracks: [resolvedTrack(id: "album-track", albumId: "direct-album")],
    )
    let directAlbumGrant = Policy.AlbumGrant(
      appleMusicAlbumId: "direct-album",
      resolution: directAlbum,
    )
    let coveredTrackGrant = trackGrant(
      id: "artist-track",
      preferredAlbumId: "artist-album",
    )
    let directTrackGrant = trackGrant(
      id: "direct-track",
      preferredAlbumId: "partial-album",
    )

    let index = try Policy.CoverageIndex(
      artistGrants: [artistGrant],
      albumGrants: [coveredAlbumGrant, directAlbumGrant],
      trackGrants: [coveredTrackGrant, directTrackGrant],
    )

    expect(index.governingGrant(forAlbum: "artist-album")).toEqual(.artist(artistGrant))
    expect(index.governingGrant(forTrack: "artist-track")).toEqual(.artist(artistGrant))
    expect(index.governingGrant(forTrack: "album-track")).toEqual(.album(directAlbumGrant))
    expect(index.governingGrant(forTrack: "direct-track")).toEqual(.track(directTrackGrant))
    expect(index.governingGrant(forAlbum: "partial-album")).toBeNil()
    expect(index.governingGrant(forTrack: "unknown-track")).toBeNil()
  }

  func testArtistCoverageUsesResolvedExactIdsNotNamesOrTopSongs() throws {
    let ownedAlbum = resolvedAlbum(
      id: "owned-album",
      title: "Same Album Name",
      tracks: [resolvedTrack(id: "owned-track", albumId: "owned-album")],
    )
    let collaborationTrack = resolvedTrack(
      id: "collaboration-track",
      albumId: "collaboration-album",
    )
    let artist = Music.ResolvedArtist(
      id: "artist-1",
      name: "Same Artist Name",
      topSongs: [collaborationTrack],
      albums: [ownedAlbum],
    )
    let artistGrant = Policy.ArtistGrant(
      appleMusicArtistId: "artist-1",
      resolution: artist,
    )
    let collaborationAlbum = resolvedAlbum(
      id: "collaboration-album",
      title: "Same Album Name",
      tracks: [collaborationTrack],
    )
    let collaborationGrant = Policy.AlbumGrant(
      appleMusicAlbumId: "collaboration-album",
      resolution: collaborationAlbum,
    )
    let index = try Policy.CoverageIndex(
      artistGrants: [artistGrant],
      albumGrants: [collaborationGrant],
    )

    expect(index.governingGrant(forAlbum: "owned-album")).toEqual(.artist(artistGrant))
    expect(index.governingGrant(forTrack: "owned-track")).toEqual(.artist(artistGrant))
    expect(index.governingGrant(forAlbum: "collaboration-album"))
      .toEqual(.album(collaborationGrant))
    expect(index.governingGrant(forTrack: "collaboration-track"))
      .toEqual(.album(collaborationGrant))
    expect(index.governingGrant(forAlbum: "same-name-only")).toBeNil()
    expect(index.governingGrant(forTrack: "same-name-only")).toBeNil()
    expect(try index.directGrantsCovered(by: artist)).toEqual(.init(
      albumIds: [],
      trackIds: [],
    ))
  }

  func testBroaderCoverageFindsOnlyExactActiveNarrowerGrants() throws {
    let sharedTrack = resolvedTrack(id: "shared-track", albumId: "covered-album")
    let coveredAlbum = resolvedAlbum(
      id: "covered-album",
      tracks: [sharedTrack],
    )
    let prospectiveArtist = resolvedArtist(
      id: "prospective-artist",
      albums: [coveredAlbum],
    )
    let coveredAlbumGrant = Policy.AlbumGrant(
      appleMusicAlbumId: "covered-album",
      resolution: coveredAlbum,
    )
    let outsideAlbum = resolvedAlbum(id: "outside-album")
    let outsideAlbumGrant = Policy.AlbumGrant(
      appleMusicAlbumId: "outside-album",
      resolution: outsideAlbum,
    )
    let sharedTrackGrant = trackGrant(
      id: "shared-track",
      preferredAlbumId: "alternate-album",
    )
    let outsideTrackGrant = trackGrant(
      id: "outside-track",
      preferredAlbumId: "covered-album",
    )
    let index = try Policy.CoverageIndex(
      albumGrants: [coveredAlbumGrant, outsideAlbumGrant],
      trackGrants: [sharedTrackGrant, outsideTrackGrant],
    )

    expect(try index.directGrantsCovered(by: prospectiveArtist)).toEqual(.init(
      albumIds: ["covered-album"],
      trackIds: ["shared-track"],
    ))
    expect(try index.directTrackIdsCovered(by: coveredAlbum))
      .toEqual(Set<Music.TrackId>(["shared-track"]))
  }

  func testMultipleAlbumCoverageUsesPreferredThenDeterministicGrant() throws {
    let albumA = resolvedAlbum(
      id: "album-a",
      tracks: [resolvedTrack(id: "shared-track", albumId: "album-a")],
    )
    let albumB = resolvedAlbum(
      id: "album-b",
      tracks: [resolvedTrack(id: "shared-track", albumId: "album-b")],
    )
    let grantA = Policy.AlbumGrant(appleMusicAlbumId: "album-a", resolution: albumA)
    let grantB = Policy.AlbumGrant(appleMusicAlbumId: "album-b", resolution: albumB)
    let index = try Policy.CoverageIndex(albumGrants: [grantB, grantA])

    expect(index.governingGrant(forTrack: "shared-track")).toEqual(.album(grantA))
    expect(index.governingGrant(
      forTrack: "shared-track",
      preferredAlbumId: "album-b",
    )).toEqual(.album(grantB))
    expect(index.governingGrant(
      forTrack: "shared-track",
      preferredAlbumId: "unrelated-album",
    )).toEqual(.album(grantA))
  }

  func testDirectTracksRemainTrackScopedAndUseCatalogOrder() throws {
    let later = trackGrant(
      id: "later-track",
      preferredAlbumId: "partial-album",
      catalogPosition: 3,
    )
    let earlier = trackGrant(
      id: "earlier-track",
      preferredAlbumId: "partial-album",
      catalogPosition: 1,
    )
    let index = try Policy.CoverageIndex(trackGrants: [later, earlier])

    expect(index.governingGrant(forAlbum: "partial-album")).toBeNil()
    expect(index.governingGrant(forTrack: "earlier-track")).toEqual(.track(earlier))
    expect(index.governingGrant(forTrack: "later-track")).toEqual(.track(later))
    expect(index.directTrackGrants(preferredAlbumId: "partial-album"))
      .toEqual([earlier, later])
  }

  func testExplicitAlbumSelectionCanonicalizesNoneSubsetAndAll() throws {
    let album = resolvedAlbum(
      id: "curation-album",
      artworkUrl: "https://example.com/album.jpg",
      tracks: [
        resolvedTrack(id: "track-1", albumId: "curation-album", trackNumber: 1),
        resolvedTrack(id: "track-2", albumId: "curation-album", trackNumber: 2),
        resolvedTrack(id: "track-3", albumId: "curation-album", trackNumber: 3),
      ],
    )
    let index = try Policy.CoverageIndex()

    expect(try index.planAlbumSelection(
      for: album,
      selectedTrackIds: [],
    )).toEqual(.removeDirectAuthorization)

    let partial = try index.planAlbumSelection(
      for: album,
      selectedTrackIds: ["track-3", "track-1", "track-3"],
    )
    guard case .replaceWithTrackGrants(let grants) = partial else {
      return XCTFail("expected track grants")
    }
    expect(grants.map(\.track.id)).toEqual(["track-1", "track-3"])
    expect(grants.map(\.catalogPosition)).toEqual([0, 2])
    expect(grants.map(\.preferredAlbum.id)).toEqual(["curation-album", "curation-album"])
    expect(grants.map(\.preferredAlbum.trackCount)).toEqual([3, 3])

    expect(try index.planAlbumSelection(
      for: album,
      selectedTrackIds: ["track-3", "track-1", "track-2", "track-2"],
    )).toEqual(.replaceWithAlbumGrant(album))
  }

  func testExplicitSoleTrackSelectionCreatesAlbumGrant() throws {
    let album = resolvedAlbum(
      id: "single-album",
      tracks: [resolvedTrack(id: "only-track", albumId: "single-album")],
    )
    let index = try Policy.CoverageIndex()

    expect(try index.planAlbumSelection(
      for: album,
      selectedTrackIds: ["only-track"],
    )).toEqual(.replaceWithAlbumGrant(album))
  }

  func testAlbumSelectionRejectsUnknownExactTrackIds() throws {
    let album = resolvedAlbum(
      id: "album-1",
      tracks: [resolvedTrack(id: "track-1", albumId: "album-1")],
    )
    let index = try Policy.CoverageIndex()

    XCTAssertThrowsError(try index.planAlbumSelection(
      for: album,
      selectedTrackIds: ["unknown-z", "track-1", "unknown-a", "unknown-z"],
    )) { error in
      expect(error as? Policy.AlbumSelectionError).toEqual(
        .unknownTrackIds(["unknown-a", "unknown-z"]),
      )
    }
  }

  func testArtistCoveredAlbumSelectionIsReadOnly() throws {
    let album = resolvedAlbum(
      id: "covered-album",
      tracks: [resolvedTrack(id: "track-1", albumId: "covered-album")],
    )
    let artistGrant = Policy.ArtistGrant(
      appleMusicArtistId: "artist-1",
      resolution: resolvedArtist(id: "artist-1", albums: [album]),
    )
    let index = try Policy.CoverageIndex(artistGrants: [artistGrant])

    expect(try index.planAlbumSelection(
      for: album,
      selectedTrackIds: [],
    )).toEqual(.coveredByArtist(artistGrant))
  }

  func testAlbumSelectionRejectsMismatchedTrackProvenance() throws {
    let malformed = resolvedAlbum(
      id: "album-1",
      tracks: [resolvedTrack(id: "track-1", albumId: "album-2")],
    )
    let index = try Policy.CoverageIndex()

    XCTAssertThrowsError(try index.planAlbumSelection(
      for: malformed,
      selectedTrackIds: [],
    )) { error in
      expect(error as? Policy.ValidationError).toEqual(
        .trackAlbumIdMismatch(track: "track-1", expected: "album-1", actual: "album-2"),
      )
    }
  }

  func testRejectsMismatchedResolutionIdentityAndProvenance() throws {
    XCTAssertThrowsError(try Policy.CoverageIndex(artistGrants: [.init(
      appleMusicArtistId: "artist-1",
      resolution: resolvedArtist(id: "artist-2", albums: []),
    )])) { error in
      expect(error as? Policy.ValidationError).toEqual(
        .artistResolutionIdMismatch(expected: "artist-1", actual: "artist-2"),
      )
    }

    let malformedAlbum = resolvedAlbum(
      id: "album-1",
      tracks: [resolvedTrack(id: "track-1", albumId: "album-2")],
    )
    XCTAssertThrowsError(try Policy.CoverageIndex(albumGrants: [.init(
      appleMusicAlbumId: "album-1",
      resolution: malformedAlbum,
    )])) { error in
      expect(error as? Policy.ValidationError).toEqual(
        .trackAlbumIdMismatch(track: "track-1", expected: "album-1", actual: "album-2"),
      )
    }

    let resolution = resolvedTrackGrant(
      id: "track-1",
      preferredAlbumId: "album-1",
    )
    XCTAssertThrowsError(try Policy.CoverageIndex(trackGrants: [.init(
      appleMusicTrackId: "track-1",
      preferredAlbumId: "album-2",
      resolution: resolution,
    )])) { error in
      expect(error as? Policy.ValidationError).toEqual(.invalidTrackResolution(
        .preferredAlbumIdMismatch(expected: "album-2", actual: "album-1"),
      ))
    }
  }
}

private typealias Policy = Music.CatalogPolicy

private func trackGrant(
  id: Music.TrackId,
  preferredAlbumId: Music.AlbumId,
  catalogPosition: Int = 0,
) -> Policy.TrackGrant {
  .init(
    appleMusicTrackId: id,
    preferredAlbumId: preferredAlbumId,
    resolution: resolvedTrackGrant(
      id: id,
      preferredAlbumId: preferredAlbumId,
      catalogPosition: catalogPosition,
    ),
  )
}
