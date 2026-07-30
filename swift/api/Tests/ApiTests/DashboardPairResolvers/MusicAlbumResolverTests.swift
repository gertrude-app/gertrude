import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicAlbumResolverTests: ApiTestCase, @unchecked Sendable {
  func testApproveAndGetMusicCuration() async throws {
    let child = try await self.musicChild()

    let first = try await ApproveMusicAlbum_v2.resolve(
      with: self.input(child: child),
      in: child.parent.context,
    )
    _ = try await ApproveMusicAlbum_v2.resolve(
      with: self.input(child: child, albumId: "1733742320"),
      in: child.parent.context,
    )
    let curation = try await GetMusicCuration.resolve(
      with: .init(childId: child.id),
      in: child.parent.context,
    )

    expect(first.revision).toEqual(1)
    expect(curation.revision).toEqual(2)
    expect(curation.albums.map(\.id.rawValue).sorted()).toEqual([
      "1440935467",
      "1733742320",
    ])
    expect(curation.albums.map(\.scope)).toEqual([.wholeAlbum, .wholeAlbum])
    expect(curation.albums.first { $0.id == "1440935467" }?.title)
      .toEqual("Stories from the Outside")
    expect(curation.albums.first { $0.id == "1733742320" }?.title)
      .toEqual("Elements")
  }

  func testApproveMusicAlbumIsIdempotent() async throws {
    let child = try await self.musicChild()
    let input = self.input(child: child)

    let first = try await ApproveMusicAlbum_v2.resolve(
      with: input,
      in: child.parent.context,
    )
    let initiallyApproved = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == "1440935467")
      .first(in: self.db)
    let second = try await ApproveMusicAlbum_v2.resolve(
      with: input,
      in: child.parent.context,
    )
    let album = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == "1440935467")
      .first(in: self.db)

    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == "1440935467")
      .count(in: self.db)).toEqual(1)
    expect(second.revision).toEqual(first.revision)
    expect(album.id).toEqual(initiallyApproved.id)
    expect(album.createdAt).toEqual(initiallyApproved.createdAt)
    expect(album.resolvedAt).toEqual(initiallyApproved.resolvedAt)
  }

  func testIdempotentApprovalRepairsMissingSnapshotWithoutRewritingGrant() async throws {
    let child = try await self.musicChild()
    let input = self.input(child: child)
    _ = try await ApproveMusicAlbum_v2.resolve(with: input, in: child.parent.context)
    let initiallyApproved = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == "1440935467")
      .first(in: self.db)
    try await Music.LibrarySnapshot.query()
      .where(.childId == child.id)
      .delete(in: self.db)

    _ = try await ApproveMusicAlbum_v2.resolve(with: input, in: child.parent.context)

    let reloaded = try await self.db.find(initiallyApproved.id)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )
    expect(reloaded.resolvedAt).toEqual(initiallyApproved.resolvedAt)
    expect(snapshot?.payload.albums.map(\.id)).toEqual(["1440935467"])
  }

  func testApproveMusicAlbumUpdatesCachedMetadata() async throws {
    let child = try await self.musicChild()
    var oldAlbum = try AppleMusicClient.testResolvedAlbum("1440935467")
    oldAlbum.title = "Old Title"
    oldAlbum.artistName = "Old Artist"
    oldAlbum.artworkUrl = nil
    oldAlbum.artwork = nil
    oldAlbum.trackCount = nil
    let storedOldAlbum = oldAlbum

    _ = try await withDependencies {
      $0.appleMusic.resolveAlbum = { _ in storedOldAlbum }
    } operation: {
      try await ApproveMusicAlbum_v2.resolve(
        with: self.input(child: child),
        in: child.parent.context,
      )
    }
    _ = try await ApproveMusicAlbum_v2.resolve(
      with: self.input(child: child),
      in: child.parent.context,
    )
    let curation = try await GetMusicCuration.resolve(
      with: .init(childId: child.id),
      in: child.parent.context,
    )

    expect(curation.albums.map(\.title)).toEqual(["Stories from the Outside"])
    expect(curation.albums.map(\.artistName)).toEqual(["Lena Jonsson Trio"])
    expect(curation.albums.map(\.artworkUrl)).toEqual([
      "https://example.com/stories.jpg",
    ])
    expect(curation.albums.map(\.catalogTrackCount)).toEqual([1])
  }

  func testResolutionFailuresDoNotChangePolicyOrSnapshot() async throws {
    let child = try await self.musicChild()
    let input = self.input(child: child)

    do {
      _ = try await withDependencies {
        $0.appleMusic.resolveAlbum = { _ in throw MusicAlbumMutationTestError.unavailable }
      } operation: {
        try await ApproveMusicAlbum_v2.resolve(with: input, in: child.parent.context)
      }
      XCTFail("expected resolution failure")
    } catch MusicAlbumMutationTestError.unavailable {}

    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
    await expect(try Music.LibrarySnapshot.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)

    _ = try await ApproveMusicAlbum_v2.resolve(with: input, in: child.parent.context)
    let album = try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .first(in: self.db)
    let snapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )

    do {
      _ = try await withDependencies {
        $0.appleMusic.resolveAlbum = { _ in throw MusicAlbumMutationTestError.unavailable }
      } operation: {
        try await ApproveMusicAlbum_v2.resolve(with: input, in: child.parent.context)
      }
      XCTFail("expected resolution failure")
    } catch MusicAlbumMutationTestError.unavailable {}

    let reloadedAlbum = try await self.db.find(album.id)
    let reloadedSnapshot = try await Music.LibrarySnapshotRepository.snapshot(
      for: child.id,
      in: self.db,
    )
    expect(reloadedAlbum.resolution).toEqual(album.resolution)
    expect(reloadedAlbum.createdAt).toEqual(album.createdAt)
    expect(reloadedSnapshot?.payload).toEqual(snapshot?.payload)
  }

  func testSaveEmptySelectionRemovesAlbumAndMissingAlbumIsNoop() async throws {
    let child = try await self.musicChild()
    let input = self.input(child: child)
    let approved = try await ApproveMusicAlbum_v2.resolve(
      with: input,
      in: child.parent.context,
    )

    let removed = try await SaveMusicAlbumCuration.resolve(
      with: .init(
        childId: child.id,
        appleMusicAlbumId: input.appleMusicAlbumId,
        expectedRevision: approved.revision,
        selectedTrackIds: [],
      ),
      in: child.parent.context,
    )
    let missing = try await SaveMusicAlbumCuration.resolve(
      with: .init(
        childId: child.id,
        appleMusicAlbumId: input.appleMusicAlbumId,
        expectedRevision: removed.curation.revision,
        selectedTrackIds: [],
      ),
      in: child.parent.context,
    )

    expect(removed.album.scope).toEqual(.none)
    expect(removed.curation.albums).toEqual([])
    expect(missing.curation.revision).toEqual(removed.curation.revision)
    await expect(try Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .count(in: self.db)).toEqual(0)
  }

  func testRejectsCrossParentAccess() async throws {
    let child = try await self.musicChild()
    let otherParent = try await self.parent()

    do {
      _ = try await ApproveMusicAlbum_v2.resolve(
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
      _ = try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: "1440935467",
          expectedRevision: 0,
          selectedTrackIds: [],
        ),
        in: otherParent.context,
      )
      XCTFail("expected save to fail")
    } catch {}
  }

  func testRejectsMusicManagementWithoutConnectedMusic() async throws {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)

    do {
      _ = try await ApproveMusicAlbum_v2.resolve(
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
      _ = try await SaveMusicAlbumCuration.resolve(
        with: .init(
          childId: child.id,
          appleMusicAlbumId: "1440935467",
          expectedRevision: 0,
          selectedTrackIds: [],
        ),
        in: child.parent.context,
      )
      XCTFail("expected save to fail")
    } catch {}
  }

  private func musicChild() async throws -> ChildEntities {
    let child = try await self.child()
    try await self.connectMusicApp(for: child)
    return child
  }

  private func connectMusicApp(for child: ChildEntities) async throws {
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (_, install) = try await self.claimedMusicInstall(for: child)
    _ = try await self.db.create(MusicApp.Token(installId: install.id))
  }

  private func input(
    child: ChildEntities,
    albumId: Music.AlbumId = "1440935467",
  ) -> ApproveMusicAlbum_v2.Input {
    .init(childId: child.id, appleMusicAlbumId: albumId)
  }
}

private enum MusicAlbumMutationTestError: Error {
  case unavailable
}
