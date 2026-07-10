import Dependencies
import DuetSQL
import Foundation
import MusicRoute
import PairQL
import Vapor
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class GetApprovedMusicLibraryResolverTests: ApiTestCase, @unchecked Sendable {
  func testRouteMatches() throws {
    let token = UUID()
    var request = URLRequest(url: URL(string: "gertrude-music/GetApprovedMusicLibrary")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-MusicToken")

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.music(.authed(token, .getApprovedMusicLibrary)))
  }

  func testV2RouteMatches() throws {
    let token = UUID()
    var request = URLRequest(url: URL(string: "gertrude-music/GetApprovedMusicLibrary_v2")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-MusicToken")

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.music(.authed(token, .getApprovedMusicLibrary_v2)))
  }

  func testAlbumTracksRouteMatches() throws {
    let token = UUID()
    let input = GetApprovedMusicAlbumTracks.Input(albumId: "1440935467")
    var request = URLRequest(url: URL(string: "gertrude-music/GetApprovedMusicAlbumTracks")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-MusicToken")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.music(.authed(token, .getApprovedMusicAlbumTracks(input))))
  }

  func testReturnsApprovedAlbumsForAuthedChild() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1440935467",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/stories.jpg",
      trackCount: 12,
      showsArtwork: true,
    ))
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1733742320",
      title: "Elements",
      artistName: "Lena Jonsson Trio",
      artworkUrl: nil,
      trackCount: nil,
      showsArtwork: false,
    ))

    let output = try await withDependencies {
      $0.appleMusic.albumTracks = { lookup in mockTracks(for: lookup) }
    } operation: {
      try await GetApprovedMusicLibrary.resolve(in: ctx)
    }

    expect(output.albums).toEqual([
      .init(
        id: "1440935467",
        title: "Stories from the Outside",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/stories.jpg",
        trackCount: 12,
        showsArtwork: true,
        tracks: [
          .init(
            id: "1440935468",
            title: "Sommarsvärta",
            artistName: "Lena Jonsson Trio",
            artworkUrl: "https://example.com/stories.jpg",
          ),
          .init(
            id: "1440935469",
            title: "Snowstorm",
            artistName: "Lena Jonsson Trio",
            artworkUrl: "https://example.com/snowstorm.jpg",
          ),
        ],
      ),
      .init(
        id: "1733742320",
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        artworkUrl: nil,
        trackCount: nil,
        showsArtwork: false,
        tracks: [
          .init(
            id: "1733742321",
            title: "Elements",
            artistName: "Lena Jonsson Trio",
            artworkUrl: "https://example.com/elements.jpg",
          ),
        ],
      ),
    ])
  }

  func testV2ReturnsApprovedAlbumsAndArtistsForAuthedChild() async throws {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let (device, install) = try await self.claimedInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1440935467",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/stories.jpg",
      trackCount: 12,
      showsArtwork: true,
    ))
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1733742320",
      title: "Elements",
      artistName: "Lena Jonsson Trio",
      artworkUrl: nil,
      trackCount: nil,
      showsArtwork: false,
    ))
    try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "123456789",
      name: "Lena Jonsson Trio",
      catalogMetadata: approvedArtistMetadata(),
    ))

    let output = try await withDependencies {
      $0.appleMusic.albums = { lookup in
        expect(lookup.albumIds.map(\.rawValue)).toEqual(["1440935467", "1733742320"])
        return mockExplicitAlbums(for: lookup)
      }
      $0.appleMusic.artistAlbums = { lookup in mockArtistAlbums(for: lookup) }
      $0.appleMusic.artistTopSongs = { lookup in mockArtistTopSongs(for: lookup) }
    } operation: {
      try await GetApprovedMusicLibrary_v2.resolve(in: ctx)
    }

    expect(output).toEqual(.init(
      albums: [
        .init(
          id: "1440935467",
          title: "Stories from the Outside",
          artistName: "Lena Jonsson Trio",
          artworkUrl: "https://example.com/stories.jpg",
          artwork: mockAlbumOutputArtwork(url: "https://example.com/stories/{w}x{h}bb.jpg"),
          trackCount: 12,
          showsArtwork: true,
        ),
        .init(
          id: "1733742320",
          title: "Elements",
          artistName: "Lena Jonsson Trio",
          artworkUrl: "https://example.com/elements.jpg",
          artwork: mockAlbumOutputArtwork(url: "https://example.com/elements/{w}x{h}bb.jpg"),
          trackCount: 12,
          releaseDate: "2024-04-12",
          releaseType: "Album",
          showsArtwork: false,
        ),
        .init(
          id: "2250000001",
          title: "Artist Grant Release",
          artistName: "Lena Jonsson Trio",
          artworkUrl: "https://example.com/artist-release.jpg",
          artwork: .init(
            url: "https://example.com/artist-release/{w}x{h}bb.jpg",
            width: 1200,
            height: 1200,
            bgColor: "102030",
            textColor1: "ffffff",
            textColor2: "eeeeee",
            textColor3: "dddddd",
            textColor4: "cccccc",
          ),
          trackCount: 8,
          releaseDate: "2025-06-06",
          releaseType: "Album",
          showsArtwork: true,
        ),
      ],
      artists: [
        .init(
          id: "123456789",
          name: "Lena Jonsson Trio",
          catalogMetadata: approvedArtistOutputMetadata(),
          releaseAlbumIds: ["1733742320", "2250000001"],
          topSongs: [
            .init(
              id: "123456790",
              title: "Sommarsvärta",
              artistName: "Lena Jonsson Trio",
              albumTitle: "Stories from the Outside",
              artworkUrl: "https://example.com/song.jpg",
              durationInMillis: 200_000,
            ),
          ],
        ),
      ],
    ))

    let hydratedAlbums = try await ctx.child.approvedMusicAlbums(in: self.db)
    expect(hydratedAlbums.map(\.artwork)).toEqual([
      mockAlbumArtwork(url: "https://example.com/stories/{w}x{h}bb.jpg"),
      mockAlbumArtwork(url: "https://example.com/elements/{w}x{h}bb.jpg"),
    ])

    let reloadedOutput = try await withDependencies {
      $0.appleMusic.albums = { _ in
        XCTFail("expected persisted artwork to prevent another album lookup")
        return []
      }
      $0.appleMusic.artistAlbums = { lookup in mockArtistAlbums(for: lookup) }
      $0.appleMusic.artistTopSongs = { lookup in mockArtistTopSongs(for: lookup) }
    } operation: {
      try await GetApprovedMusicLibrary_v2.resolve(in: ctx)
    }
    expect(reloadedOutput).toEqual(output)
  }

  func testV2ReturnsExplicitAlbumsWhenArtworkHydrationFails() async throws {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let (device, install) = try await self.claimedInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1440935467",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/stories.jpg",
      trackCount: 12,
      showsArtwork: true,
    ))

    let output = try await withDependencies {
      $0.appleMusic.albums = { _ in
        throw AppleMusicError.httpError(statusCode: 500, body: "unavailable")
      }
    } operation: {
      try await GetApprovedMusicLibrary_v2.resolve(in: ctx)
    }

    expect(output).toEqual(.init(
      albums: [
        .init(
          id: "1440935467",
          title: "Stories from the Outside",
          artistName: "Lena Jonsson Trio",
          artworkUrl: "https://example.com/stories.jpg",
          trackCount: 12,
          showsArtwork: true,
        ),
      ],
      artists: [],
    ))
    let album = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .first(in: self.db)
    expect(album.artwork).toBeNil()
  }

  func testReturnsApprovedAlbumTracksForArtistCoveredAlbum() async throws {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let (device, install) = try await self.claimedInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "123456789",
      name: "Lena Jonsson Trio",
      catalogMetadata: approvedArtistMetadata(),
    ))

    let output = try await withDependencies {
      $0.appleMusic.artistAlbums = { lookup in mockArtistAlbums(for: lookup) }
      $0.appleMusic.albumTracks = { lookup in mockTracks(for: lookup) }
    } operation: {
      try await GetApprovedMusicAlbumTracks.resolve(
        with: .init(albumId: "2250000001"),
        in: ctx,
      )
    }

    expect(output).toEqual([
      .init(
        id: "2250000002",
        title: "Artist Grant Track",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/artist-release.jpg",
      ),
    ])
  }

  func testReturnsApprovedAlbumTracksForExplicitAlbum() async throws {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let (device, install) = try await self.claimedInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1440935467",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/stories.jpg",
      trackCount: 12,
      showsArtwork: true,
    ))

    let output = try await withDependencies {
      $0.appleMusic.albumTracks = { lookup in mockTracks(for: lookup) }
    } operation: {
      try await GetApprovedMusicAlbumTracks.resolve(
        with: .init(albumId: "1440935467"),
        in: ctx,
      )
    }

    expect(output).toEqual([
      .init(
        id: "1440935468",
        title: "Sommarsvärta",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/stories.jpg",
      ),
      .init(
        id: "1440935469",
        title: "Snowstorm",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/snowstorm.jpg",
      ),
    ])
  }

  func testRejectsUnapprovedAlbumTracks() async throws {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let (device, install) = try await self.claimedInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )

    do {
      _ = try await GetApprovedMusicAlbumTracks.resolve(
        with: .init(albumId: "1440935467"),
        in: ctx,
      )
      XCTFail("expected unauthorized error for unapproved album")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }
  }

  func testV1IgnoresApprovedArtists() async throws {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let (device, install) = try await self.claimedInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "123456789",
      name: "Lena Jonsson Trio",
      catalogMetadata: approvedArtistMetadata(),
    ))

    let output = try await GetApprovedMusicLibrary.resolve(in: ctx)

    expect(output.albums).toEqual([])
  }

  func testAuthedRouteResolvesTokenAndReturnsApprovedLibrary() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (_, install) = try await self.claimedInstall(for: child)
    let token = try await self.db.create(MusicApp.Token(installId: install.id))
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1440935467",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/stories.jpg",
      trackCount: 12,
      showsArtwork: true,
    ))

    let response = try await withDependencies {
      $0.appleMusic.albumTracks = { lookup in mockTracks(for: lookup) }
    } operation: {
      try await PairQLRoute.respond(
        to: .music(.authed(token.value.rawValue, .getApprovedMusicLibrary)),
        in: .mock,
      )
    }

    expect(response.status).toEqual(.ok)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let output = try decoder.decode(
      GetApprovedMusicLibrary.Output.self,
      from: response.body.data!,
    )
    expect(output.albums.map(\.id)).toEqual(["1440935467"])
    expect(output.albums.map { $0.tracks.map(\.id) }).toEqual([["1440935468", "1440935469"]])
  }

  func testRequiresMusicAccess() async throws {
    let child = try await self.child()
    let (_, install) = try await self.claimedInstall(for: child)
    _ = try await self.db.create(MusicApp.Token(installId: install.id))
    let ctx = try await MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: install.device(in: self.db),
      child: child.model,
      telemetry: TelemetryBag(),
    )

    do {
      _ = try await GetApprovedMusicLibrary.resolve(in: ctx)
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }
  }

  func testUnauthorizedAfterTokenRowDeleted() async throws {
    let child = try await self.child()
    let (_, install) = try await self.claimedInstall(for: child)
    let token = try await self.db.create(MusicApp.Token(installId: install.id))
    let tokenValue = token.value.rawValue

    try await MusicApp.Token.query()
      .where(.installId == install.id)
      .delete(in: self.db)

    do {
      _ = try await PairQLRoute.respond(
        to: .music(.authed(tokenValue, .getApprovedMusicLibrary)),
        in: .mock,
      )
      XCTFail("expected unauthorized error after token row deleted")
    } catch let error as PqlError {
      expect(error.type).toEqual(.unauthorized)
    }
  }

  private func claimedInstall(for child: ChildEntities) async throws
    -> (IOSDevice, MusicApp.Install) {
    let device = try await self.db.create(IOSDevice(
      id: .init(UUID()),
      childId: child.model.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(
      .music,
      device.id,
      child.model.id,
      code: Int.random(in: 100_000 ... 999_999),
      claimedAt: .reference,
    )
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    return (device, install)
  }
}

private func approvedArtistMetadata() -> Music.CatalogMetadata {
  .init(
    artwork: .init(
      url: "https://example.com/artist/{w}x{h}bb.jpg",
      width: 1200,
      height: 1200,
      bgColor: "19160f",
      textColor1: "f3949b",
      textColor2: "b08ff2",
      textColor3: "c77b7f",
      textColor4: "9277c5",
    ),
    editorialNotes: .init(
      tagline: "Swedish folk trio",
      short: "Modern fiddle music.",
      standard: "A longer <b>Apple Music</b> artist note.",
      name: "Apple Music Folk",
    ),
    appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
    genreNames: ["Folk", "Worldwide"],
  )
}

private func approvedArtistOutputMetadata() -> MusicCatalogMetadata {
  .init(
    artwork: .init(
      url: "https://example.com/artist/{w}x{h}bb.jpg",
      width: 1200,
      height: 1200,
      bgColor: "19160f",
      textColor1: "f3949b",
      textColor2: "b08ff2",
      textColor3: "c77b7f",
      textColor4: "9277c5",
    ),
    editorialNotes: .init(
      tagline: "Swedish folk trio",
      short: "Modern fiddle music.",
      standard: "A longer <b>Apple Music</b> artist note.",
      name: "Apple Music Folk",
    ),
    appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
    genreNames: ["Folk", "Worldwide"],
  )
}

private func mockExplicitAlbums(for lookup: AppleMusicAlbumsLookup)
  -> [AppleMusicCatalogAlbum] {
  let albums: [AppleMusicCatalogAlbum] = [
    .init(
      id: "1440935467",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/stories.jpg",
      artwork: mockAlbumArtwork(url: "https://example.com/stories/{w}x{h}bb.jpg"),
      trackCount: 12,
    ),
    .init(
      id: "1733742320",
      title: "Elements",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/elements.jpg",
      artwork: mockAlbumArtwork(url: "https://example.com/elements/{w}x{h}bb.jpg"),
      trackCount: 6,
    ),
  ]
  let albumIds = Set(lookup.albumIds)
  return albums.filter { albumIds.contains($0.id) }
}

private func mockAlbumArtwork(url: String) -> Music.Artwork {
  .init(
    url: url,
    width: 1200,
    height: 1200,
    bgColor: "102030",
    textColor1: "ffffff",
    textColor2: "eeeeee",
    textColor3: "dddddd",
    textColor4: "cccccc",
  )
}

private func mockAlbumOutputArtwork(url: String) -> MusicArtwork {
  .init(
    url: url,
    width: 1200,
    height: 1200,
    bgColor: "102030",
    textColor1: "ffffff",
    textColor2: "eeeeee",
    textColor3: "dddddd",
    textColor4: "cccccc",
  )
}

private func mockArtistAlbums(for lookup: AppleMusicArtistAlbumsLookup)
  -> [AppleMusicCatalogAlbum] {
  switch lookup.artistId.rawValue {
  case "123456789":
    [
      .init(
        id: "1733742320",
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/elements.jpg",
        trackCount: 12,
        releaseDate: "2024-04-12",
        releaseType: "Album",
      ),
      .init(
        id: "2250000001",
        title: "Artist Grant Release",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/artist-release.jpg",
        artwork: .init(
          url: "https://example.com/artist-release/{w}x{h}bb.jpg",
          width: 1200,
          height: 1200,
          bgColor: "102030",
          textColor1: "ffffff",
          textColor2: "eeeeee",
          textColor3: "dddddd",
          textColor4: "cccccc",
        ),
        trackCount: 8,
        releaseDate: "2025-06-06",
        releaseType: "Album",
      ),
    ]
  default:
    []
  }
}

private func mockArtistTopSongs(
  for lookup: AppleMusicArtistTopSongsLookup,
) -> [AppleMusicCatalogTrack] {
  switch lookup.artistId.rawValue {
  case "123456789":
    [
      .init(
        id: "123456790",
        title: "Sommarsvärta",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
        artworkUrl: "https://example.com/song.jpg",
        durationInMillis: 200_000,
      ),
    ]
  default:
    []
  }
}

private func mockTracks(for lookup: AppleMusicAlbumTracksLookup) -> [AppleMusicCatalogTrack] {
  switch lookup.albumId.rawValue {
  case "1440935467":
    [
      .init(
        id: "1440935468",
        title: "Sommarsvärta",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
      ),
      .init(
        id: "1440935469",
        title: "Snowstorm",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
        artworkUrl: "https://example.com/snowstorm.jpg",
      ),
    ]
  case "1733742320":
    [
      .init(
        id: "1733742321",
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        artworkUrl: "https://example.com/elements.jpg",
      ),
    ]
  case "2250000001":
    [
      .init(
        id: "2250000002",
        title: "Artist Grant Track",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Artist Grant Release",
      ),
    ]
  default:
    []
  }
}
