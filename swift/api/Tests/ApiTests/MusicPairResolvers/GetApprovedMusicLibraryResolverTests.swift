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
    let input = GetApprovedMusicLibrary_v2.Input(knownRevision: 42)
    var request = URLRequest(url: URL(string: "gertrude-music/GetApprovedMusicLibrary_v2")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-MusicToken")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.music(.authed(token, .getApprovedMusicLibrary_v2(input))))
  }

  func testV1ReturnsApprovedAlbumsForAuthedChild() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
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
      resolution: resolvedAlbum(id: "1440935467"),
      resolvedAt: .reference,
    ))
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1733742320",
      title: "Elements",
      artistName: "Lena Jonsson Trio",
      artworkUrl: nil,
      trackCount: nil,
      showsArtwork: false,
      resolution: resolvedAlbum(id: "1733742320"),
      resolvedAt: .reference,
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

  func testV1ProjectsArtistAlbumsThroughV02ClientModel() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Artist",
      resolution: libraryResolverResolvedArtist(),
      resolvedAt: .reference,
    ))
    _ = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await GetApprovedMusicLibrary.resolve(in: ctx)
    let encoded = try JSONEncoder().encode(output)
    let decoded = try JSONDecoder().decode(GetApprovedMusicLibrary.Output.self, from: encoded)
    let library = MusicV02ApprovedMusicLibrary(remote: decoded)
    let album = try XCTUnwrap(library.albums.first)
    let track = try XCTUnwrap(album.tracks.first)

    expect(output.albums.map(\.showsArtwork)).toEqual([true])
    expect(library.albums.count).toEqual(1)
    expect(album.id).toEqual("artist-album")
    expect(album.title).toEqual("Artist Album")
    expect(album.artistName).toEqual("Artist")
    expect(album.artworkURL?.absoluteString).toEqual("https://example.com/artist-album.jpg")
    expect(album.tracks.count).toEqual(1)
    expect(track.id).toEqual("artist-track")
    expect(track.title).toEqual("Artist Track")
    expect(track.artistName).toEqual("Artist")
    expect(track.artworkURL?.absoluteString).toEqual("https://example.com/artist-album.jpg")
  }

  func testV1DeduplicatesOverlapAndRetainsArtistCoverageAfterDirectRemoval() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    let albumResolution = libraryResolverResolvedAlbum()
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy",
      artistName: "Legacy",
      showsArtwork: false,
      resolution: albumResolution,
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
        albums: [albumResolution],
      ),
      resolvedAt: .reference,
    ))
    _ = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let overlapped = try await GetApprovedMusicLibrary.resolve(in: ctx)

    expect(overlapped.albums.map(\.id)).toEqual(["album-1"])
    expect(overlapped.albums.map(\.showsArtwork)).toEqual([true])

    let childId = child.id
    try await self.db.withTransaction { db in
      try await Music.LibrarySnapshotRepository.lock(childId: childId, in: db)
      _ = try await Music.ApprovedAlbum.query()
        .where(.childId == childId)
        .delete(in: db)
      _ = try await Music.LibrarySnapshotRepository.publish(
        childId: childId,
        generatedAt: .reference + 1,
        in: db,
      )
    }

    let artistOnly = try await GetApprovedMusicLibrary.resolve(in: ctx)

    expect(artistOnly.albums.map(\.id)).toEqual(["album-1"])
    expect(artistOnly.albums.map(\.showsArtwork)).toEqual([true])
    expect(artistOnly.albums.first?.tracks.map(\.id)).toEqual(["track-1"])
  }

  func testV1AuthedRouteResolvesTokenAndReturnsApprovedLibrary() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (_, install) = try await self.claimedMusicInstall(for: child)
    let token = try await self.db.create(MusicApp.Token(installId: install.id))
    try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "1440935467",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/stories.jpg",
      trackCount: 12,
      showsArtwork: true,
      resolution: resolvedAlbum(id: "1440935467"),
      resolvedAt: .reference,
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

  func testV2RequiresMusicAccess() async throws {
    let child = try await self.child()
    let (_, install) = try await self.claimedMusicInstall(for: child)
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
      _ = try await GetApprovedMusicLibrary_v2.resolve(with: .init(), in: ctx)
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }
  }

  func testV1ProjectsPublishedSnapshotWithoutAppleRequests() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy",
      artistName: "Legacy",
      resolution: libraryResolverResolvedAlbum(),
      resolvedAt: .reference,
    ))
    _ = try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "artist-1",
      name: "Legacy",
      resolution: libraryResolverResolvedArtist(),
      resolvedAt: .reference,
    ))
    _ = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await GetApprovedMusicLibrary.resolve(in: ctx)

    expect(output.albums.map(\.id)).toEqual(["album-1", "artist-album"])
    expect(output.albums.map { $0.tracks.map(\.id) }).toEqual([
      ["track-1"],
      ["artist-track"],
    ])
  }

  func testV2ReturnsRevisionZeroEmptySnapshotAndThenUnchanged() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )

    let initial = try await GetApprovedMusicLibrary_v2.resolve(
      with: .init(),
      in: ctx,
    )
    let unchanged = try await GetApprovedMusicLibrary_v2.resolve(
      with: .init(knownRevision: 0),
      in: ctx,
    )

    expect(initial).toEqual(.snapshot(.init(
      revision: 0,
      generatedAt: .init(timeIntervalSince1970: 0),
      albums: [],
      artists: [],
    )))
    expect(unchanged).toEqual(.unchanged(revision: 0))
  }

  func testV2ReadsPublishedSnapshotWithoutAppleRequests() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy",
      artistName: "Legacy",
      resolution: libraryResolverResolvedAlbum(),
      resolvedAt: .reference,
    ))
    let published = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await GetApprovedMusicLibrary_v2.resolve(
      with: .init(),
      in: ctx,
    )
    let unchanged = try await GetApprovedMusicLibrary_v2.resolve(
      with: .init(knownRevision: published.revision),
      in: ctx,
    )

    expect(output).toEqual(.snapshot(published.payload))
    expect(unchanged).toEqual(.unchanged(revision: published.revision))
  }

  func testV2ReadsAndVerifiesPublishedTrackGrantSnapshot() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    var trackGrant = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "selected-track",
      preferredAlbumId: "partial-album",
      resolution: resolvedTrackGrant(
        id: "selected-track",
        preferredAlbumId: "partial-album",
        albumTitle: "Partial Album",
        albumTrackCount: 3,
      ),
      resolvedAt: .reference,
    ))
    let published = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )

    let output = try await GetApprovedMusicLibrary_v2.resolve(
      with: .init(),
      in: ctx,
    )

    expect(output).toEqual(.snapshot(published.payload))
    expect(published.payload.albums[0].tracks.map(\.id)).toEqual(["selected-track"])

    trackGrant.resolution.track.title = "Changed without publication"
    try await self.db.update(trackGrant)

    do {
      _ = try await GetApprovedMusicLibrary_v2.resolve(with: .init(), in: ctx)
      XCTFail("expected inconsistent snapshot error")
    } catch let error as PqlError {
      expect(error.type).toEqual(.serverError)
    }
  }

  func testV2RejectsSnapshotThatDoesNotMatchCurrentGrants() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    var album = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy",
      artistName: "Legacy",
      resolution: libraryResolverResolvedAlbum(),
      resolvedAt: .reference,
    ))
    _ = try await Music.LibrarySnapshotRepository.publish(
      childId: child.id,
      generatedAt: .reference,
      in: self.db,
    )
    album.resolution.title = "Changed without publication"
    try await self.db.update(album)

    do {
      _ = try await GetApprovedMusicLibrary_v2.resolve(with: .init(), in: ctx)
      XCTFail("expected inconsistent snapshot error")
    } catch let error as PqlError {
      expect(error.type).toEqual(.serverError)
    }
  }

  func testV2RejectsGrantWithoutPublishedSnapshot() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    _ = try await self.db.create(Music.ApprovedAlbum(
      childId: child.id,
      appleMusicAlbumId: "album-1",
      title: "Legacy",
      artistName: "Legacy",
      resolution: resolvedAlbum(id: "album-1"),
      resolvedAt: .reference,
    ))

    do {
      _ = try await GetApprovedMusicLibrary_v2.resolve(with: .init(), in: ctx)
      XCTFail("expected incomplete library error")
    } catch let error as PqlError {
      expect(error.type).toEqual(.serverError)
    }
  }

  func testV2RejectsTrackGrantWithoutPublishedSnapshot() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (device, install) = try await self.claimedMusicInstall(for: child)
    let ctx = MusicApp.InstallContext(
      requestId: "mock-req-id",
      dashboardUrl: "/",
      install: install,
      device: device,
      child: child.model,
      telemetry: TelemetryBag(),
    )
    _ = try await self.db.create(Music.ApprovedTrack(
      childId: child.id,
      appleMusicTrackId: "selected-track",
      preferredAlbumId: "partial-album",
      resolution: resolvedTrackGrant(
        id: "selected-track",
        preferredAlbumId: "partial-album",
      ),
      resolvedAt: .reference,
    ))

    do {
      _ = try await GetApprovedMusicLibrary_v2.resolve(with: .init(), in: ctx)
      XCTFail("expected incomplete library error")
    } catch let error as PqlError {
      expect(error.type).toEqual(.serverError)
    }
  }

  func testUnauthorizedAfterTokenRowDeleted() async throws {
    let child = try await self.child()
    let (_, install) = try await self.claimedMusicInstall(for: child)
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
}

private struct MusicV02ApprovedMusicLibrary {
  var albums: [MusicV02ApprovedAlbum]

  init(remote output: GetApprovedMusicLibrary.Output) {
    self.albums = output.albums.map(MusicV02ApprovedAlbum.init)
  }
}

private struct MusicV02ApprovedAlbum {
  var id: String
  var title: String
  var artistName: String
  var artworkURL: URL?
  var tracks: [MusicV02ApprovedTrack]

  init(remote album: GetApprovedMusicLibrary.Output.Album) {
    self.id = album.id
    self.title = album.title
    self.artistName = album.artistName
    self.artworkURL = album.artworkUrl.flatMap(URL.init(string:))
    self.tracks = album.tracks.map(MusicV02ApprovedTrack.init)
  }
}

private struct MusicV02ApprovedTrack {
  var id: String
  var title: String
  var artistName: String
  var artworkURL: URL?

  init(remote track: GetApprovedMusicLibrary.Output.Track) {
    self.id = track.id
    self.title = track.title
    self.artistName = track.artistName
    self.artworkURL = track.artworkUrl.flatMap(URL.init(string:))
  }
}

private func libraryResolverResolvedAlbum() -> Music.ResolvedAlbum {
  .init(
    id: "album-1",
    title: "Trusted",
    artistName: "Artist",
    artistIds: ["artist-1"],
    trackCount: 1,
    tracks: [
      .init(
        id: "track-1",
        title: "Track",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: "album-1",
        albumTitle: "Trusted",
      ),
    ],
  )
}

private func libraryResolverResolvedArtist() -> Music.ResolvedArtist {
  .init(
    id: "artist-1",
    name: "Artist",
    topSongs: [],
    albums: [
      .init(
        id: "artist-album",
        title: "Artist Album",
        artistName: "Artist",
        artistIds: ["artist-1"],
        artworkUrl: "https://example.com/artist-album.jpg",
        trackCount: 1,
        tracks: [
          .init(
            id: "artist-track",
            title: "Artist Track",
            artistName: "Artist",
            artistIds: ["artist-1"],
            albumId: "artist-album",
            albumTitle: "Artist Album",
          ),
        ],
      ),
    ],
  )
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
