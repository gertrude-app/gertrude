import Dependencies
import PairQL
import XCTest
import XExpect

@testable import Api

final class SearchMusicCatalogResolverTests: ApiTestCase, @unchecked Sendable {
  func testSearchesAppleMusicAlbumsAndArtistsInMixedOrder() async throws {
    let child = try await self.musicChild()

    let output = try await withDependencies {
      $0.appleMusic.searchCatalog = { search in
        expect(search.term).toEqual("Lena")
        expect(search.limit).toEqual(10)
        let album = AppleMusicCatalogAlbum(
          id: "1511628001",
          title: search.term,
          artistName: "us",
          artworkUrl: "https://example.com/art.jpg",
          artwork: albumArtwork(),
          trackCount: search.limit,
          releaseDate: "2020-05-29",
          appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
        )
        let artist = AppleMusicCatalogArtist(
          id: "123456789",
          name: search.term,
          catalogMetadata: artistMetadata(genreNames: ["us"]),
        )
        return .init(
          items: [.init(artist: artist), .init(album: album)],
          albums: [album],
          artists: [artist],
        )
      }
    } operation: {
      try await SearchMusicCatalog_v2.resolve(
        with: .init(childId: child.id, query: "  Lena  ", limit: nil),
        in: child.parent.context,
      )
    }

    expect(output.revision).toEqual(0)
    expect(output.items.map(\.kind)).toEqual([.artist, .album])
    expect(output.items[0].artist?.name).toEqual("Lena")
    expect(output.items[0].artist?.status).toEqual(.available)
    expect(output.items[1].album?.title).toEqual("Lena")
    expect(output.items[1].album?.artistName).toEqual("us")
    expect(output.items[1].album?.artwork).toEqual(albumArtwork())
    expect(output.items[1].album?.trackCount).toEqual(10)
    expect(output.items[1].album?.status.kind).toEqual(.available)
  }

  func testClampsSearchLimit() async throws {
    let child = try await self.musicChild()

    func search(limit: Int) async throws -> SearchMusicCatalog_v2.Output {
      try await withDependencies {
        $0.appleMusic.searchCatalog = { search in
          let album = AppleMusicCatalogAlbum(
            id: "1",
            title: "Album \(search.limit)",
            artistName: "Artist",
            trackCount: search.limit,
          )
          let artist = AppleMusicCatalogArtist(
            id: "2",
            name: "Artist \(search.limit)",
          )
          return .init(
            items: [.init(album: album), .init(artist: artist)],
            albums: [album],
            artists: [artist],
          )
        }
      } operation: {
        try await SearchMusicCatalog_v2.resolve(
          with: .init(childId: child.id, query: "Album", limit: limit),
          in: child.parent.context,
        )
      }
    }

    let highLimit = try await search(limit: 100)
    let lowLimit = try await search(limit: -5)

    expect(highLimit.items.compactMap(\.album?.trackCount)).toEqual([25])
    expect(highLimit.items.compactMap(\.artist?.name)).toEqual(["Artist 25"])
    expect(lowLimit.items.compactMap(\.album?.trackCount)).toEqual([1])
    expect(lowLimit.items.compactMap(\.artist?.name)).toEqual(["Artist 1"])
  }

  func testBlankQueryReturnsNoResultsWithoutSearching() async throws {
    let child = try await self.musicChild()

    let output = try await withDependencies {
      $0.appleMusic
        .searchCatalog = { _ in throw SearchMusicCatalogResolverTestError.unexpectedSearch }
    } operation: {
      try await SearchMusicCatalog_v2.resolve(
        with: .init(childId: child.id, query: "   ", limit: 10),
        in: child.parent.context,
      )
    }

    expect(output.revision).toEqual(0)
    expect(output.items).toEqual([])
  }

  func testRequiresMusicAccess() async throws {
    let child = try await self.child()

    do {
      _ = try await SearchMusicCatalog_v2.resolve(
        with: .init(childId: child.id, query: "Lena", limit: nil),
        in: child.parent.context,
      )
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }
  }

  func testRejectsCrossParentAccess() async throws {
    let child = try await self.musicChild()
    let otherParent = try await self.parent()

    do {
      _ = try await SearchMusicCatalog_v2.resolve(
        with: .init(childId: child.id, query: "Lena", limit: nil),
        in: otherParent.context,
      )
      XCTFail("expected search to fail")
    } catch {}
  }

  private func musicChild() async throws -> ChildEntities {
    let child = try await self.child()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let (_, install) = try await self.claimedMusicInstall(for: child)
    _ = try await self.db.create(MusicApp.Token(installId: install.id))
    return child
  }
}

private func albumArtwork() -> Music.Artwork {
  .init(
    url: "https://example.com/art/{w}x{h}bb.jpg",
    width: 1200,
    height: 1200,
    bgColor: "102030",
    textColor1: "ffffff",
    textColor2: "eeeeee",
    textColor3: "dddddd",
    textColor4: "cccccc",
  )
}

private func artistMetadata(genreNames: [String] = ["Folk"]) -> Music.CatalogMetadata {
  .init(
    artwork: .init(
      url: "https://example.com/artist/{w}x{h}bb.jpg",
      width: 1200,
      height: 1200,
    ),
    editorialNotes: .init(tagline: "Modern Swedish folk"),
    appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
    genreNames: genreNames,
  )
}

private enum SearchMusicCatalogResolverTestError: Error {
  case unexpectedSearch
}
