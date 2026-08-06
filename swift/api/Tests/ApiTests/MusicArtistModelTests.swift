import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MusicArtistModelTests: ApiTestCase, @unchecked Sendable {
  func testCreateListAndRemoveApprovedArtist() async throws {
    let child = try await self.child()
    let metadata = Music.CatalogMetadata(
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

    try await self.db.create(Music.ApprovedArtist(
      childId: child.id,
      appleMusicArtistId: "123456789",
      name: "Lena Jonsson Trio",
      catalogMetadata: metadata,
      resolution: resolvedArtist(id: "123456789", albums: []),
      resolvedAt: .reference,
    ))

    var artists = try await child.model.approvedMusicArtists(in: self.db)

    expect(artists.count).toEqual(1)
    expect(artists[0].childId).toEqual(child.id)
    expect(artists[0].appleMusicArtistId.rawValue).toEqual("123456789")
    expect(artists[0].name).toEqual("Lena Jonsson Trio")
    expect(artists[0].catalogMetadata).toEqual(metadata)

    try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == "123456789")
      .delete(in: self.db)

    artists = try await child.model.approvedMusicArtists(in: self.db)

    expect(artists.count).toEqual(0)
  }
}
