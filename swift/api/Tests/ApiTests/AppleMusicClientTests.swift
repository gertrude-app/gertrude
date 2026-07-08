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

  func testBuildsCatalogArtistSearchURL() throws {
    let url = try appleMusicCatalogArtistSearchURL(.init(
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
    expect(queryItems.first { $0.name == "types" }?.value).toEqual("artists")
    expect(queryItems.first { $0.name == "limit" }?.value).toEqual("25")
  }

  func testBuildsCatalogMixedSearchURL() throws {
    let url = try appleMusicCatalogMixedSearchURL(.init(
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
    expect(queryItems.first { $0.name == "types" }?.value).toEqual("albums,artists")
    expect(queryItems.first { $0.name == "limit" }?.value).toEqual("25")
    expect(queryItems.first { $0.name == "with" }?.value).toEqual("topResults")
  }

  func testBuildsCatalogAlbumURL() throws {
    let url = try appleMusicCatalogAlbumURL(.init(
      albumId: .init(rawValue: "1511628001"),
      storefront: "us",
    ))

    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    expect(components.scheme).toEqual("https")
    expect(components.host).toEqual("api.music.apple.com")
    expect(components.path).toEqual("/v1/catalog/us/albums/1511628001")

    let queryItems = try XCTUnwrap(components.queryItems)
    expect(queryItems.first { $0.name == "include" }?.value).toEqual("tracks")
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

  func testDecodesArtistSearchResponse() throws {
    let data = try XCTUnwrap("""
    {
      "results": {
        "artists": {
          "data": [
            {
              "id": "123456789",
              "type": "artists",
              "attributes": {
                "name": "Lena Jonsson Trio",
                "artwork": {
                  "url": "https://example.com/artist/{w}x{h}bb.jpg",
                  "width": 1200,
                  "height": 1200,
                  "bgColor": "19160f",
                  "textColor1": "f3949b",
                  "textColor2": "b08ff2",
                  "textColor3": "c77b7f",
                  "textColor4": "9277c5"
                },
                "editorialNotes": {
                  "tagline": "Modern Swedish folk",
                  "short": "Modern fiddle music.",
                  "standard": "A longer <b>Apple Music</b> artist note.",
                  "name": "Apple Music Folk"
                },
                "genreNames": ["Folk", "Worldwide"],
                "url": "https://music.apple.com/us/artist/lena-jonsson-trio/123456789"
              }
            }
          ]
        }
      }
    }
    """.data(using: .utf8))

    let artists = try decodeAppleMusicCatalogArtists(from: data)

    expect(artists).toEqual([
      .init(
        id: .init(rawValue: "123456789"),
        name: "Lena Jonsson Trio",
        catalogMetadata: .init(
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
            tagline: "Modern Swedish folk",
            short: "Modern fiddle music.",
            standard: "A longer <b>Apple Music</b> artist note.",
            name: "Apple Music Folk",
          ),
          appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
          genreNames: ["Folk", "Worldwide"],
        ),
      ),
    ])
  }

  func testDecodesMixedSearchResponseUsingTopResultsOrder() throws {
    let data = try XCTUnwrap("""
    {
      "results": {
        "topResults": {
          "data": [
            {
              "id": "123456789",
              "type": "artists",
              "attributes": {
                "name": "Lena Jonsson Trio",
                "genreNames": ["Folk"],
                "url": "https://music.apple.com/us/artist/lena-jonsson-trio/123456789"
              }
            },
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
            },
            {
              "id": "song-1",
              "type": "songs",
              "attributes": {
                "name": "Ignored song"
              }
            }
          ]
        },
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
        },
        "artists": {
          "data": [
            {
              "id": "123456789",
              "type": "artists",
              "attributes": {
                "name": "Lena Jonsson Trio",
                "genreNames": ["Folk"],
                "url": "https://music.apple.com/us/artist/lena-jonsson-trio/123456789"
              }
            }
          ]
        }
      }
    }
    """.data(using: .utf8))

    let results = try decodeAppleMusicCatalogSearchResults(from: data)
    let album = AppleMusicCatalogAlbum(
      id: .init(rawValue: "1511628001"),
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl: "https://example.com/art/600x600bb.jpg",
      trackCount: 12,
      releaseDate: "2020-05-29",
      appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
    )
    let artist = AppleMusicCatalogArtist(
      id: .init(rawValue: "123456789"),
      name: "Lena Jonsson Trio",
      catalogMetadata: .init(
        appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
        genreNames: ["Folk"],
      ),
    )

    expect(results.items).toEqual([.init(artist: artist), .init(album: album)])
    expect(results.albums).toEqual([album])
    expect(results.artists).toEqual([artist])
  }

  func testDecodesMixedSearchResponseFallsBackToMetaOrder() throws {
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
                "artistName": "Lena Jonsson Trio"
              }
            }
          ]
        },
        "artists": {
          "data": [
            {
              "id": "123456789",
              "type": "artists",
              "attributes": {
                "name": "Lena Jonsson Trio"
              }
            }
          ]
        }
      },
      "meta": {
        "results": {
          "order": ["albums", "artists"]
        }
      }
    }
    """.data(using: .utf8))

    let results = try decodeAppleMusicCatalogSearchResults(from: data)
    let album = AppleMusicCatalogAlbum(
      id: .init(rawValue: "1511628001"),
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
    )
    let artist = AppleMusicCatalogArtist(
      id: .init(rawValue: "123456789"),
      name: "Lena Jonsson Trio",
      catalogMetadata: .init(),
    )

    expect(results.items).toEqual([.init(album: album), .init(artist: artist)])
  }

  func testDecodesAlbumTracksResponse() throws {
    let data = try XCTUnwrap("""
    {
      "data": [
        {
          "id": "1511628001",
          "type": "albums",
          "relationships": {
            "tracks": {
              "data": [
                {
                  "id": "1511628002",
                  "type": "songs",
                  "attributes": {
                    "name": "Sommarsvärta",
                    "artistName": "Lena Jonsson Trio",
                    "albumName": "Stories from the Outside",
                    "artwork": {
                      "url": "https://example.com/track/{w}x{h}bb.jpg"
                    }
                  }
                },
                {
                  "id": "music-video-1",
                  "type": "music-videos",
                  "attributes": {
                    "name": "Video",
                    "artistName": "Lena Jonsson Trio"
                  }
                },
                {
                  "id": "1511628003",
                  "type": "songs",
                  "attributes": {
                    "name": "Snowstorm",
                    "artistName": "Lena Jonsson Trio",
                    "albumName": "Stories from the Outside"
                  }
                }
              ]
            }
          }
        }
      ]
    }
    """.data(using: .utf8))

    let tracks = try decodeAppleMusicCatalogAlbumTracks(from: data)

    expect(tracks).toEqual([
      .init(
        id: .init(rawValue: "1511628002"),
        title: "Sommarsvärta",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
        artworkUrl: "https://example.com/track/600x600bb.jpg",
      ),
      .init(
        id: .init(rawValue: "1511628003"),
        title: "Snowstorm",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
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
    let artists = try decodeAppleMusicCatalogArtists(from: data)

    expect(albums).toEqual([])
    expect(artists).toEqual([])
  }
}
