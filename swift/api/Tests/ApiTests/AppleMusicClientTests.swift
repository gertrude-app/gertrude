import Foundation
import XCTest
import XExpect

@testable import Api

final class AppleMusicClientTests: XCTestCase {
  func testBuildsCatalogAlbumSearchURL() throws {
    let url = try appleMusicCatalogSearchURL(.init(
      term: "Lena Jonsson Trio",
      storefront: "us",
      limit: 25,
    ))

    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    expect(components.scheme).toEqual("https")
    expect(components.host).toEqual("api.music.apple.com")
    expect(components.path).toEqual("/v1/catalog/us/search")

    let queryItems = try XCTUnwrap(components.queryItems)
    expect(queryItems.first { $0.name == "term" }?.value).toEqual("Lena Jonsson Trio")
    expect(queryItems.first { $0.name == "types" }?.value).toEqual("albums")
    expect(queryItems.first { $0.name == "limit" }?.value).toEqual("25")
  }

  func testDecodesAlbumSearchResponse() throws {
    let data = try XCTUnwrap("""
    {
      "results": {
        "albums": {
          "data": [
            {
              "id": "1511628001",
              "type": "albums",
              "attributes": {
                "name": "Stories from the Outside",
                "artistName": "Lena Jonsson Trio",
                "artwork": {
                  "url": "https://example.com/art/{w}x{h}bb.jpg"
                },
                "trackCount": 12,
                "releaseDate": "2020-05-29",
                "url": "https://music.apple.com/us/album/stories-from-the-outside/1511628001"
              }
            }
          ]
        }
      }
    }
    """.data(using: .utf8))

    let albums = try decodeAppleMusicCatalogAlbums(from: data)

    expect(albums).toEqual([
      .init(
        id: .init(rawValue: "1511628001"),
        title: "Stories from the Outside",
        artistName: "Lena Jonsson Trio",
        artworkUrl: "https://example.com/art/600x600bb.jpg",
        trackCount: 12,
        releaseDate: "2020-05-29",
        appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
      ),
    ])
  }

  func testDecodesMissingAlbumsAsEmpty() throws {
    let data = try XCTUnwrap("""
    {
      "results": {}
    }
    """.data(using: .utf8))

    let albums = try decodeAppleMusicCatalogAlbums(from: data)

    expect(albums).toEqual([])
  }
}
