import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicTrackModelTests: ApiTestCase, @unchecked Sendable {
  func testCreateAndListApprovedTrack() async throws {
    let child = try await self.child()
    let inserted = try await self.db.create(approvedTrack(
      childId: child.id,
      showsArtwork: false,
    ))

    let tracks = try await child.model.approvedMusicTracks(in: self.db)
    let stored = try XCTUnwrap(tracks.first)

    expect(tracks.count).toEqual(1)
    expect(stored.id).toEqual(inserted.id)
    expect(stored.childId).toEqual(child.id)
    expect(stored.appleMusicTrackId).toEqual("track-1")
    expect(stored.preferredAlbumId).toEqual("album-1")
    expect(stored.resolution).toEqual(inserted.resolution)
    expect(stored.showsArtwork).toEqual(false)
    expect(stored.resolvedAt).toEqual(.reference)
    await expect(try stored.child(in: self.db).id).toEqual(child.id)
  }

  func testTrackIdIsUniqueWithinChild() async throws {
    let child = try await self.child()
    let otherChild = try await self.child()
    try await self.db.create(approvedTrack(childId: child.id))

    var rejectedDuplicate = false
    do {
      try await self.db.create(approvedTrack(
        childId: child.id,
        albumId: "album-2",
      ))
    } catch {
      rejectedDuplicate = true
    }

    try await self.db.create(approvedTrack(childId: otherChild.id))
    let childCount = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)
    let otherChildCount = try await Music.ApprovedTrack.query()
      .where(.childId == otherChild.id)
      .count(in: self.db)

    expect(rejectedDuplicate).toEqual(true)
    expect(childCount).toEqual(1)
    expect(otherChildCount).toEqual(1)
  }

  func testEmptyAppleIdsAreRejected() async throws {
    let child = try await self.child()
    let invalidTracks = [
      approvedTrack(childId: child.id, trackId: ""),
      approvedTrack(childId: child.id, albumId: ""),
    ]

    for track in invalidTracks {
      var rejected = false
      do {
        try await self.db.create(track)
      } catch {
        rejected = true
      }
      expect(rejected).toEqual(true)
    }

    let count = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)
    expect(count).toEqual(0)
  }

  func testDeletingChildCascadesToApprovedTracks() async throws {
    let child = try await self.child()
    try await self.db.create(approvedTrack(childId: child.id))

    try await Child.query()
      .where(.id == child.id)
      .delete(in: self.db)

    let count = try await Music.ApprovedTrack.query()
      .where(.childId == child.id)
      .count(in: self.db)
    expect(count).toEqual(0)
  }
}

private func approvedTrack(
  childId: Child.Id,
  trackId: Music.TrackId = "track-1",
  albumId: Music.AlbumId = "album-1",
  showsArtwork: Bool = true,
) -> Music.ApprovedTrack {
  .init(
    childId: childId,
    appleMusicTrackId: trackId,
    preferredAlbumId: albumId,
    resolution: .init(
      track: .init(
        id: trackId,
        title: "Track",
        artistName: "Artist",
        artistIds: ["artist-1"],
        albumId: albumId,
        albumTitle: "Album",
        artworkUrl: "https://example.com/track.jpg",
        durationInMillis: 180_000,
        discNumber: 1,
        trackNumber: 1,
        contentRating: .clean,
        appleMusicUrl: "https://music.apple.com/us/album/album/1?i=2",
      ),
      preferredAlbum: .init(
        id: albumId,
        title: "Album",
        artistName: "Artist",
        artistIds: ["artist-1"],
        artworkUrl: "https://example.com/album.jpg",
        trackCount: 10,
        releaseDate: "2026-01-02",
        releaseType: "Album",
        appleMusicUrl: "https://music.apple.com/us/album/album/1",
      ),
      catalogPosition: 0,
    ),
    showsArtwork: showsArtwork,
    resolvedAt: .reference,
  )
}
