import Dependencies
import DuetSQL
import PairQL
import XCTest
import XExpect

@testable import Api

final class MusicArtistResolverTests: ApiTestCase, @unchecked Sendable {
  func testApproveAndGetApprovedMusicArtists() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)
    let metadata = self.metadata(tagline: "Modern Swedish folk")

    let output = try await ApproveMusicArtist.resolve(
      with: self.input(child: child, catalogMetadata: metadata),
      in: child.parent.context,
    )
    _ = try await ApproveMusicArtist.resolve(
      with: self.input(
        child: child,
        artistId: "555555555",
        name: "Väsen",
        catalogMetadata: self.metadata(tagline: "Strings and grooves"),
      ),
      in: child.parent.context,
    )

    let artists = try await GetApprovedMusicArtists.resolve(
      with: child.id,
      in: child.parent.context,
    )

    expect(output).toEqual(.success)
    expect(artists.artists).toEqual([
      .init(
        id: .init(rawValue: "123456789"),
        name: "Lena Jonsson Trio",
        catalogMetadata: self.metadata(),
        createdAt: artists.artists[0].createdAt,
      ),
      .init(
        id: .init(rawValue: "555555555"),
        name: "Väsen",
        catalogMetadata: self.metadata(tagline: "Strings and grooves"),
        createdAt: artists.artists[1].createdAt,
      ),
    ])
  }

  func testApproveMusicArtistIsIdempotent() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)
    let input = self.input(child: child)

    _ = try await ApproveMusicArtist.resolve(with: input, in: child.parent.context)
    let initiallyApproved = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == "123456789")
      .first(in: self.db)
    _ = try await ApproveMusicArtist.resolve(with: input, in: child.parent.context)

    let count = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == "123456789")
      .count(in: self.db)

    let artist = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == "123456789")
      .first(in: self.db)

    expect(count).toEqual(1)
    expect(artist.id).toEqual(initiallyApproved.id)
    expect(artist.createdAt).toEqual(initiallyApproved.createdAt)
    expect(artist.name).toEqual("Lena Jonsson Trio")
    expect(artist.catalogMetadata).toEqual(self.metadata())
  }

  func testApproveMusicArtistUpdatesCachedMetadata() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)

    _ = try await ApproveMusicArtist.resolve(
      with: .init(
        childId: child.id,
        appleMusicArtistId: .init(rawValue: "123456789"),
        name: "Old Name",
        catalogMetadata: nil,
      ),
      in: child.parent.context,
    )
    _ = try await ApproveMusicArtist.resolve(
      with: self.input(child: child),
      in: child.parent.context,
    )

    let artists = try await GetApprovedMusicArtists.resolve(
      with: child.id,
      in: child.parent.context,
    )

    expect(artists.artists).toEqual([
      .init(
        id: .init(rawValue: "123456789"),
        name: "Lena Jonsson Trio",
        catalogMetadata: self.metadata(),
        createdAt: artists.artists[0].createdAt,
      ),
    ])
  }

  func testApproveMusicArtistIgnoresBrowserMetadataAndPublishesSnapshot() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)

    _ = try await ApproveMusicArtist.resolve(
      with: .init(
        childId: child.id,
        appleMusicArtistId: "123456789",
        name: "Forged artist",
        catalogMetadata: .init(genreNames: ["Forged"]),
      ),
      in: child.parent.context,
    )

    let artist = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .first(in: self.db)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )
    expect(artist.name).toEqual("Lena Jonsson Trio")
    expect(artist.catalogMetadata).toEqual(self.metadata())
    expect(artist.resolution?.name).toEqual("Lena Jonsson Trio")
    expect(snapshot?.revision).toEqual(1)
    expect(snapshot?.payload.artists.map(\.name)).toEqual(["Lena Jonsson Trio"])
  }

  func testInitialArtistResolutionFailureWritesNothing() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)

    do {
      _ = try await withDependencies {
        $0.appleMusic.resolveArtist = { _ in throw MusicArtistMutationTestError.unavailable }
      } operation: {
        try await ApproveMusicArtist.resolve(
          with: self.input(child: child),
          in: child.parent.context,
        )
      }
      XCTFail("expected resolution failure")
    } catch MusicArtistMutationTestError.unavailable {}

    let artistCount = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .count(in: self.db)
    let snapshotCount = try await Music.LibrarySnapshot.query()
      .where(.childId == child.id)
      .count(in: self.db)
    expect(artistCount).toEqual(0)
    expect(snapshotCount).toEqual(0)
  }

  func testRemoveApprovedMusicArtist() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)
    let input = self.input(child: child)
    _ = try await ApproveMusicArtist.resolve(with: input, in: child.parent.context)

    let output = try await RemoveApprovedMusicArtist.resolve(
      with: .init(childId: child.id, appleMusicArtistId: .init(rawValue: "123456789")),
      in: child.parent.context,
    )
    let artists = try await GetApprovedMusicArtists.resolve(
      with: child.id,
      in: child.parent.context,
    )

    expect(output).toEqual(.success)
    expect(artists.artists).toEqual([])
  }

  func testRemoveMissingApprovedMusicArtistIsNoop() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)

    let output = try await RemoveApprovedMusicArtist.resolve(
      with: .init(childId: child.id, appleMusicArtistId: .init(rawValue: "123456789")),
      in: child.parent.context,
    )

    expect(output).toEqual(.success)
  }

  func testRejectsCrossParentAccess() async throws {
    let child = try await self.child()
    let otherParent = try await self.parent()

    do {
      _ = try await ApproveMusicArtist.resolve(
        with: self.input(child: child),
        in: otherParent.context,
      )
      XCTFail("expected approval to fail")
    } catch {}

    do {
      _ = try await GetApprovedMusicArtists.resolve(with: child.id, in: otherParent.context)
      XCTFail("expected list to fail")
    } catch {}

    do {
      _ = try await RemoveApprovedMusicArtist.resolve(
        with: .init(childId: child.id, appleMusicArtistId: .init(rawValue: "123456789")),
        in: otherParent.context,
      )
      XCTFail("expected removal to fail")
    } catch {}

    let count = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .count(in: self.db)

    expect(count).toEqual(0)
  }

  func testRejectsMusicArtistManagementWithoutConnectedMusic() async throws {
    let child = try await self.child()
    try await self.addLightPaidSubscription(for: child.parent.model.id)

    do {
      _ = try await ApproveMusicArtist.resolve(
        with: self.input(child: child),
        in: child.parent.context,
      )
      XCTFail("expected approval to fail")
    } catch {}

    do {
      _ = try await GetApprovedMusicArtists.resolve(with: child.id, in: child.parent.context)
      XCTFail("expected list to fail")
    } catch {}

    do {
      _ = try await RemoveApprovedMusicArtist.resolve(
        with: .init(childId: child.id, appleMusicArtistId: .init(rawValue: "123456789")),
        in: child.parent.context,
      )
      XCTFail("expected removal to fail")
    } catch {}
  }

  func testRejectsMusicArtistManagementWithoutMusicAccess() async throws {
    let child = try await self.child()

    do {
      _ = try await ApproveMusicArtist.resolve(
        with: self.input(child: child),
        in: child.parent.context,
      )
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }
  }

  private func connectMusicApp(for child: ChildEntities) async throws {
    try await self.addLightPaidSubscription(for: child.parent.model.id)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
    })
    try await self.createClaim(
      .music,
      device.id,
      child.id,
      code: Int.random(in: 100_000 ... 999_999),
      claimedAt: .reference,
    )
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: install.id))
  }

  private func input(
    child: ChildEntities,
    artistId: String = "123456789",
    name: String = "Lena Jonsson Trio",
    catalogMetadata: Music.CatalogMetadata? = nil,
  ) -> ApproveMusicArtist.Input {
    .init(
      childId: child.id,
      appleMusicArtistId: .init(rawValue: artistId),
      name: name,
      catalogMetadata: catalogMetadata ?? self.metadata(),
    )
  }

  private func metadata(tagline: String = "Swedish folk trio") -> Music.CatalogMetadata {
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
        tagline: tagline,
        short: "Modern fiddle music.",
        standard: "A longer <b>Apple Music</b> artist note.",
        name: "Apple Music Folk",
      ),
      appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
      genreNames: ["Folk", "Worldwide"],
    )
  }
}

private enum MusicArtistMutationTestError: Error {
  case unavailable
}
