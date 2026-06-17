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

  func testReturnsApprovedAlbumsForAuthedChild() async throws {
    let child = try await self.child()
    try await self.grantMusicAccess(to: child.parent.model.id)
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

  func testAuthedRouteResolvesTokenAndReturnsApprovedLibrary() async throws {
    let child = try await self.child()
    try await self.grantMusicAccess(to: child.parent.model.id)
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

  private func grantMusicAccess(to parentId: Parent.Id) async throws {
    try await self.db.create(BillingIdentity(parentId: parentId))
    try await self.db.create(StripeSubscription(
      parentId: parentId,
      tier: .light,
      stripeId: .init("sub_\(parentId.rawValue.uuidString.prefix(8))"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(30),
    ))
  }

  private func claimedInstall(for child: ChildEntities) async throws
    -> (IOSDevice, MusicApp.Install) {
    let device = try await self.db.create(IOSDevice(
      id: .init(UUID()),
      childId: child.model.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      claimedAt: .reference,
    ))
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    return (device, install)
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
  default:
    []
  }
}
