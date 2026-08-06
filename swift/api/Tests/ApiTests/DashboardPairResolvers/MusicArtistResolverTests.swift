import Dependencies
import DuetSQL
import PairQL
import XCTest
import XExpect

@testable import Api

final class MusicArtistResolverTests: ApiTestCase, @unchecked Sendable {
  func testApproveAndGetMusicCuration() async throws {
    let child = try await self.musicChild()

    let first = try await ApproveMusicArtist_v2.resolve(
      with: self.input(child: child),
      in: child.parent.context,
    )
    _ = try await ApproveMusicArtist_v2.resolve(
      with: self.input(child: child, artistId: "555555555"),
      in: child.parent.context,
    )
    let curation = try await GetMusicCuration.resolve(
      with: .init(childId: child.id),
      in: child.parent.context,
    )

    expect(first.status).toEqual(.updated)
    expect(first.curation.revision).toEqual(1)
    expect(curation.revision).toEqual(2)
    expect(curation.artists.map(\.id.rawValue).sorted()).toEqual([
      "123456789",
      "555555555",
    ])
    expect(curation.artists.first { $0.id == "123456789" }?.name)
      .toEqual("Lena Jonsson Trio")
    expect(curation.artists.first { $0.id == "555555555" }?.name).toEqual("Väsen")
  }

  func testApproveMusicArtistIsIdempotent() async throws {
    let child = try await self.musicChild()
    let input = self.input(child: child)

    let first = try await ApproveMusicArtist_v2.resolve(
      with: input,
      in: child.parent.context,
    )
    let initiallyApproved = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == "123456789")
      .first(in: self.db)
    let second = try await ApproveMusicArtist_v2.resolve(
      with: input,
      in: child.parent.context,
    )
    let artist = try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == "123456789")
      .first(in: self.db)

    await expect(try Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == "123456789")
      .count(in: self.db)).toEqual(1)
    expect(second.status).toEqual(.updated)
    expect(second.curation.revision).toEqual(first.curation.revision)
    expect(artist.id).toEqual(initiallyApproved.id)
    expect(artist.createdAt).toEqual(initiallyApproved.createdAt)
    expect(artist.resolvedAt).toEqual(initiallyApproved.resolvedAt)
  }

  func testApproveMusicArtistUpdatesCachedMetadata() async throws {
    let child = try await self.musicChild()
    var oldArtist = try AppleMusicClient.testResolvedArtist("123456789")
    oldArtist.name = "Old Name"
    oldArtist.catalogMetadata = nil
    let storedOldArtist = oldArtist

    _ = try await withDependencies {
      $0.appleMusic.resolveArtist = { _ in storedOldArtist }
    } operation: {
      try await ApproveMusicArtist_v2.resolve(
        with: self.input(child: child),
        in: child.parent.context,
      )
    }
    _ = try await ApproveMusicArtist_v2.resolve(
      with: self.input(child: child),
      in: child.parent.context,
    )
    let curation = try await GetMusicCuration.resolve(
      with: .init(childId: child.id),
      in: child.parent.context,
    )

    expect(curation.artists.map(\.name)).toEqual(["Lena Jonsson Trio"])
    expect(curation.artists[0].catalogMetadata).toEqual(self.metadata())
  }

  func testInitialArtistResolutionFailureWritesNothing() async throws {
    let child = try await self.musicChild()

    do {
      _ = try await withDependencies {
        $0.appleMusic.resolveArtist = { _ in throw MusicArtistMutationTestError.unavailable }
      } operation: {
        try await ApproveMusicArtist_v2.resolve(
          with: self.input(child: child),
          in: child.parent.context,
        )
      }
      XCTFail("expected resolution failure")
    } catch MusicArtistMutationTestError.unavailable {}

    await expect(try Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
    await expect(try Music.LibrarySnapshot.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testRemoveApprovedMusicArtistAndMissingArtistIsNoop() async throws {
    let child = try await self.musicChild()
    let input = self.input(child: child)
    _ = try await ApproveMusicArtist_v2.resolve(with: input, in: child.parent.context)

    let removed = try await RemoveApprovedMusicArtist.resolve(
      with: .init(childId: child.id, appleMusicArtistId: input.appleMusicArtistId),
      in: child.parent.context,
    )
    let missing = try await RemoveApprovedMusicArtist.resolve(
      with: .init(childId: child.id, appleMusicArtistId: input.appleMusicArtistId),
      in: child.parent.context,
    )
    let curation = try await GetMusicCuration.resolve(
      with: .init(childId: child.id),
      in: child.parent.context,
    )

    expect(removed).toEqual(.success)
    expect(missing).toEqual(.success)
    expect(curation.artists).toEqual([])
  }

  func testRejectsCrossParentAccess() async throws {
    let child = try await self.musicChild()
    let otherParent = try await self.parent()

    do {
      _ = try await ApproveMusicArtist_v2.resolve(
        with: self.input(child: child),
        in: otherParent.context,
      )
      XCTFail("expected approval to fail")
    } catch {}

    do {
      _ = try await GetMusicCuration.resolve(
        with: .init(childId: child.id),
        in: otherParent.context,
      )
      XCTFail("expected curation to fail")
    } catch {}

    do {
      _ = try await RemoveApprovedMusicArtist.resolve(
        with: .init(childId: child.id, appleMusicArtistId: "123456789"),
        in: otherParent.context,
      )
      XCTFail("expected removal to fail")
    } catch {}

    await expect(try Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testRejectsMusicArtistManagementWithoutConnectedMusic() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)

    do {
      _ = try await ApproveMusicArtist_v2.resolve(
        with: self.input(child: child),
        in: child.parent.context,
      )
      XCTFail("expected approval to fail")
    } catch {}

    do {
      _ = try await GetMusicCuration.resolve(
        with: .init(childId: child.id),
        in: child.parent.context,
      )
      XCTFail("expected curation to fail")
    } catch {}

    do {
      _ = try await RemoveApprovedMusicArtist.resolve(
        with: .init(childId: child.id, appleMusicArtistId: "123456789"),
        in: child.parent.context,
      )
      XCTFail("expected removal to fail")
    } catch {}
  }

  func testRejectsMusicArtistManagementWithoutMusicAccess() async throws {
    let child = try await self.child()

    do {
      _ = try await ApproveMusicArtist_v2.resolve(
        with: self.input(child: child),
        in: child.parent.context,
      )
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }
  }

  private func musicChild() async throws -> ChildEntities {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (_, install) = try await self.claimedMusicInstall(for: child)
    _ = try await self.db.create(MusicApp.Token(installId: install.id))
    return child
  }

  private func input(
    child: ChildEntities,
    artistId: Music.ArtistId = "123456789",
  ) -> ApproveMusicArtist_v2.Input {
    .init(childId: child.id, appleMusicArtistId: artistId)
  }

  private func metadata() -> Music.CatalogMetadata {
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
}

private enum MusicArtistMutationTestError: Error {
  case unavailable
}
