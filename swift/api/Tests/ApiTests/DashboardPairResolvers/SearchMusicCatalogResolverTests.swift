import Dependencies
import XCTest
import XExpect

@testable import Api

final class SearchMusicCatalogResolverTests: ApiTestCase, @unchecked Sendable {
  func testSearchesAppleMusicAlbums() async throws {
    let parent = try await self.parent()

    let output = try await withDependencies {
      $0.appleMusic.searchAlbums = { search in
        [
          .init(
            id: .init(rawValue: "1511628001"),
            title: search.term,
            artistName: search.storefront,
            artworkUrl: "https://example.com/art.jpg",
            trackCount: search.limit,
            releaseDate: "2020-05-29",
            appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
          ),
        ]
      }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "  Lena  ", limit: nil),
        in: parent.context,
      )
    }

    expect(output.albums).toEqual([
      .init(
        id: .init(rawValue: "1511628001"),
        title: "Lena",
        artistName: "us",
        artworkUrl: "https://example.com/art.jpg",
        trackCount: 10,
        releaseDate: "2020-05-29",
        appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
      ),
    ])
  }

  func testClampsSearchLimit() async throws {
    let parent = try await self.parent()

    let highLimit = try await withDependencies {
      $0.appleMusic.searchAlbums = { search in
        [.init(id: .init(rawValue: "1"), title: "Album", artistName: "Artist", trackCount: search.limit)]
      }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "Album", limit: 100),
        in: parent.context,
      )
    }

    let lowLimit = try await withDependencies {
      $0.appleMusic.searchAlbums = { search in
        [.init(id: .init(rawValue: "1"), title: "Album", artistName: "Artist", trackCount: search.limit)]
      }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "Album", limit: -5),
        in: parent.context,
      )
    }

    expect(highLimit.albums[0].trackCount).toEqual(25)
    expect(lowLimit.albums[0].trackCount).toEqual(1)
  }

  func testBlankQueryReturnsNoAlbumsWithoutSearching() async throws {
    let parent = try await self.parent()

    let output = try await withDependencies {
      $0.appleMusic.searchAlbums = { _ in throw SearchMusicCatalogResolverTestError.unexpectedSearch }
    } operation: {
      try await SearchMusicCatalog.resolve(
        with: .init(query: "   ", limit: 10),
        in: parent.context,
      )
    }

    expect(output.albums).toEqual([])
  }
}

enum SearchMusicCatalogResolverTestError: Error {
  case unexpectedSearch
}
