import Dependencies
import PairQL
import XCTest
import XExpect

@testable import Api

final class SearchMusicCatalogResolverTests: ApiTestCase, @unchecked Sendable {
  func testSearchesAppleMusicAlbumsAndArtistsInMixedOrder() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)

    let output = try await withDependencies {
      $0.appleMusic.searchCatalog = { search in
        let album = AppleMusicCatalogAlbum(
          id: .init(rawValue: "1511628001"),
          title: search.term,
          artistName: search.storefront,
          artworkUrl: "https://example.com/art.jpg",
          trackCount: search.limit,
          releaseDate: "2020-05-29",
          appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
        )
        let artist = AppleMusicCatalogArtist(
          id: .init(rawValue: "123456789"),
          name: search.term,
          catalogMetadata: artistMetadata(genreNames: [search.storefront]),
        )
        return .init(
          items: [.init(artist: artist), .init(album: album)],
          albums: [album],
          artists: [artist],
        )
      }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "  Lena  ", limit: nil),
        in: parent.context,
      )
    }

    let album = SearchMusicCatalog.Output.Album(
      id: .init(rawValue: "1511628001"),
      title: "Lena",
      artistName: "us",
      artworkUrl: "https://example.com/art.jpg",
      trackCount: 10,
      releaseDate: "2020-05-29",
      appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
    )
    let artist = SearchMusicCatalog.Output.Artist(
      id: .init(rawValue: "123456789"),
      name: "Lena",
      catalogMetadata: artistMetadata(genreNames: ["us"]),
    )

    expect(output.items).toEqual([
      .init(kind: .artist, album: nil, artist: artist),
      .init(kind: .album, album: album, artist: nil),
    ])
    expect(output.albums).toEqual([album])
    expect(output.artists).toEqual([artist])
  }

  func testClampsSearchLimit() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)

    let highLimit = try await withDependencies {
      $0.appleMusic.searchCatalog = { search in
        .init(
          items: [.init(artist: .init(id: .init(rawValue: "2"), name: "Artist \(search.limit)"))],
          albums: [.init(
            id: .init(rawValue: "1"),
            title: "Album",
            artistName: "Artist",
            trackCount: search.limit,
          )],
          artists: [.init(id: .init(rawValue: "2"), name: "Artist \(search.limit)")],
        )
      }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "Album", limit: 100),
        in: parent.context,
      )
    }

    let lowLimit = try await withDependencies {
      $0.appleMusic.searchCatalog = { search in
        .init(
          items: [.init(artist: .init(id: .init(rawValue: "2"), name: "Artist \(search.limit)"))],
          albums: [.init(
            id: .init(rawValue: "1"),
            title: "Album",
            artistName: "Artist",
            trackCount: search.limit,
          )],
          artists: [.init(id: .init(rawValue: "2"), name: "Artist \(search.limit)")],
        )
      }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "Album", limit: -5),
        in: parent.context,
      )
    }

    expect(highLimit.albums[0].trackCount).toEqual(25)
    expect(highLimit.artists[0].name).toEqual("Artist 25")
    expect(lowLimit.albums[0].trackCount).toEqual(1)
    expect(lowLimit.artists[0].name).toEqual("Artist 1")
  }

  func testBlankQueryReturnsNoResultsWithoutSearching() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .medium)

    let output = try await withDependencies {
      $0.appleMusic
        .searchCatalog = { _ in throw SearchMusicCatalogResolverTestError.unexpectedSearch }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "   ", limit: 10),
        in: parent.context,
      )
    }

    expect(output.items).toEqual([])
    expect(output.albums).toEqual([])
    expect(output.artists).toEqual([])
  }

  func testRequiresMusicAccess() async throws {
    let parent = try await self.parent()

    do {
      _ = try await SearchMusicCatalog.resolve(
        with: .init(query: "Lena", limit: nil),
        in: parent.context,
      )
      XCTFail("expected payment required")
    } catch let error as PqlError {
      expect(error.type).toEqual(.paymentRequired)
    }
  }
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

enum SearchMusicCatalogResolverTestError: Error {
  case unexpectedSearch
}
