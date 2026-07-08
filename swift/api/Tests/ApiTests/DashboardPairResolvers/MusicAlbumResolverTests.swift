import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicAlbumResolverTests: ApiTestCase, @unchecked Sendable {
  func testApproveAndGetApprovedMusicAlbums() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)

    let output = try await ApproveMusicAlbum.resolve(
      with: self.input(child: child),
      in: child.parent.context,
    )
    _ = try await ApproveMusicAlbum.resolve(
      with: self.input(
        child: child,
        albumId: "1733742320",
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/elements.jpg",
        trackCount: 6,
        showsArtwork: false,
      ),
      in: child.parent.context,
    )

    let albums = try await GetApprovedMusicAlbums.resolve(with: child.id, in: child.parent.context)

    expect(output).toEqual(.success)
    expect(albums.albums).toEqual([
      .init(
        id: .init(rawValue: "1440935467"),
        title: "Stories from the Outside",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/stories.jpg",
        trackCount: 12,
        showsArtwork: true,
        createdAt: albums.albums[0].createdAt,
      ),
      .init(
        id: .init(rawValue: "1733742320"),
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/elements.jpg",
        trackCount: 6,
        showsArtwork: false,
        createdAt: albums.albums[1].createdAt,
      ),
    ])
  }

  func testApproveMusicAlbumIsIdempotent() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)
    let input = self.input(child: child)

    _ = try await ApproveMusicAlbum.resolve(with: input, in: child.parent.context)
    _ = try await ApproveMusicAlbum.resolve(with: input, in: child.parent.context)

    let count = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == "1440935467")
      .count(in: self.db)

    let album = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == "1440935467")
      .first(in: self.db)

    expect(count).toEqual(1)
    expect(album.title).toEqual("Stories from the Outside")
    expect(album.artistName).toEqual("Lena Jonsson Trio")
    expect(album.artworkUrl).toEqual("https://example.com/stories.jpg")
    expect(album.trackCount).toEqual(12)
    expect(album.showsArtwork).toEqual(true)
  }

  func testApproveMusicAlbumUpdatesCachedMetadata() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)

    _ = try await ApproveMusicAlbum.resolve(
      with: self.input(
        child: child,
        title: "Old Title",
        artistName: "Old Artist",
        artworkUrl: nil,
        trackCount: nil,
        showsArtwork: false,
      ),
      in: child.parent.context,
    )
    _ = try await ApproveMusicAlbum.resolve(
      with: self.input(child: child),
      in: child.parent.context,
    )

    let albums = try await GetApprovedMusicAlbums.resolve(with: child.id, in: child.parent.context)

    expect(albums.albums).toEqual([
      .init(
        id: .init(rawValue: "1440935467"),
        title: "Stories from the Outside",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/stories.jpg",
        trackCount: 12,
        showsArtwork: true,
        createdAt: albums.albums[0].createdAt,
      ),
    ])
  }

  func testRemoveApprovedMusicAlbum() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)
    let input = self.input(child: child)
    _ = try await ApproveMusicAlbum.resolve(with: input, in: child.parent.context)

    let output = try await RemoveApprovedMusicAlbum.resolve(
      with: .init(childId: child.id, appleMusicAlbumId: .init(rawValue: "1440935467")),
      in: child.parent.context,
    )
    let albums = try await GetApprovedMusicAlbums.resolve(with: child.id, in: child.parent.context)

    expect(output).toEqual(.success)
    expect(albums.albums).toEqual([])
  }

  func testRemoveMissingApprovedMusicAlbumIsNoop() async throws {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)

    let output = try await RemoveApprovedMusicAlbum.resolve(
      with: .init(childId: child.id, appleMusicAlbumId: .init(rawValue: "1440935467")),
      in: child.parent.context,
    )

    expect(output).toEqual(.success)
  }

  func testRejectsCrossParentAccess() async throws {
    let child = try await self.child()
    let otherParent = try await self.parent()

    do {
      _ = try await ApproveMusicAlbum.resolve(
        with: self.input(child: child),
        in: otherParent.context,
      )
      XCTFail("expected approval to fail")
    } catch {}

    do {
      _ = try await GetApprovedMusicAlbums.resolve(with: child.id, in: otherParent.context)
      XCTFail("expected list to fail")
    } catch {}

    do {
      _ = try await RemoveApprovedMusicAlbum.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: .init(rawValue: "1440935467")),
        in: otherParent.context,
      )
      XCTFail("expected removal to fail")
    } catch {}

    let count = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)

    expect(count).toEqual(0)
  }

  func testRejectsMusicManagementWithoutConnectedMusic() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)

    do {
      _ = try await ApproveMusicAlbum.resolve(
        with: self.input(child: child),
        in: child.parent.context,
      )
      XCTFail("expected approval to fail")
    } catch {}

    do {
      _ = try await GetApprovedMusicAlbums.resolve(with: child.id, in: child.parent.context)
      XCTFail("expected list to fail")
    } catch {}

    do {
      _ = try await RemoveApprovedMusicAlbum.resolve(
        with: .init(childId: child.id, appleMusicAlbumId: .init(rawValue: "1440935467")),
        in: child.parent.context,
      )
      XCTFail("expected removal to fail")
    } catch {}
  }

  private func connectMusicApp(for child: ChildEntities) async throws {
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
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
    albumId: String = "1440935467",
    title: String = "Stories from the Outside",
    artistName: String = "Lena Jonsson Trio",
    artworkUrl: String? = "https://example.com/stories.jpg",
    trackCount: Int? = 12,
    showsArtwork: Bool = true,
  ) -> ApproveMusicAlbum.Input {
    .init(
      childId: child.id,
      appleMusicAlbumId: .init(rawValue: albumId),
      title: title,
      artistName: artistName,
      artworkUrl: artworkUrl,
      trackCount: trackCount,
      showsArtwork: showsArtwork,
    )
  }
}
