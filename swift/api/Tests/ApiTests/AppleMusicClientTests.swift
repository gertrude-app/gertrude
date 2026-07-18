import Foundation
import XCTest
import XExpect

@testable import Api

final class AppleMusicClientTests: XCTestCase {
  func testBuildsCatalogAlbumSearchURL() throws {
    let url = try appleMusicCatalogSearchURL(.init(
      term: "Lena Jonsson Trio",
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

  func testBuildsCatalogAlbumsURL() throws {
    let url = try appleMusicCatalogAlbumsURL(.init(
      albumIds: ["1511628001", "1682152618"],
    ))

    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    expect(components.scheme).toEqual("https")
    expect(components.host).toEqual("api.music.apple.com")
    expect(components.path).toEqual("/v1/catalog/us/albums")
    expect(components.queryItems?.first { $0.name == "ids" }?.value)
      .toEqual("1511628001,1682152618")
  }

  func testBuildsCatalogAlbumURL() throws {
    let url = try appleMusicCatalogAlbumURL(.init(
      albumId: .init(rawValue: "1511628001"),
    ))

    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    expect(components.scheme).toEqual("https")
    expect(components.host).toEqual("api.music.apple.com")
    expect(components.path).toEqual("/v1/catalog/us/albums/1511628001")

    let queryItems = try XCTUnwrap(components.queryItems)
    expect(queryItems.first { $0.name == "include" }?.value).toEqual("tracks")
  }

  func testBuildsCatalogArtistAlbumsURL() throws {
    let url = try appleMusicCatalogArtistAlbumsURL(.init(
      artistId: .init(rawValue: "123456789"),
      artistName: "Lena Jonsson Trio",
    ), view: .fullAlbums)

    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    expect(components.scheme).toEqual("https")
    expect(components.host).toEqual("api.music.apple.com")
    expect(components.path).toEqual("/v1/catalog/us/artists/123456789/view/full-albums")

    let queryItems = try XCTUnwrap(components.queryItems)
    expect(queryItems.first { $0.name == "limit" }?.value).toEqual("100")
  }

  func testBuildsCatalogArtistTopSongsURL() throws {
    let url = try appleMusicCatalogArtistTopSongsURL(.init(
      artistId: .init(rawValue: "123456789"),
      artistName: "Lena Jonsson Trio",
    ))

    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    expect(components.scheme).toEqual("https")
    expect(components.host).toEqual("api.music.apple.com")
    expect(components.path).toEqual("/v1/catalog/us/artists/123456789/view/top-songs")
    expect(components.queryItems?.first { $0.name == "limit" }?.value).toEqual("12")
  }

  func testBuildsCatalogURLFromRelativeNextPath() throws {
    let url = try appleMusicCatalogURL(
      fromNext: "/v1/catalog/us/artists/123456789/view/full-albums?offset=100",
    )

    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
    expect(components.scheme).toEqual("https")
    expect(components.host).toEqual("api.music.apple.com")
    expect(components.path).toEqual("/v1/catalog/us/artists/123456789/view/full-albums")
    expect(components.queryItems?.first { $0.name == "offset" }?.value).toEqual("100")
  }

  func testRejectsUntrustedCatalogPaginationURL() throws {
    XCTAssertThrowsError(
      try appleMusicCatalogURL(fromNext: "https://example.com/steal-token"),
    )
    XCTAssertThrowsError(
      try appleMusicCatalogURL(fromNext: "http://api.music.apple.com/insecure"),
    )
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
                  "url": "https://example.com/art/{w}x{h}bb.jpg",
                  "width": 1200,
                  "height": 1200,
                  "bgColor": "102030",
                  "textColor1": "ffffff",
                  "textColor2": "eeeeee",
                  "textColor3": "dddddd",
                  "textColor4": "cccccc"
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
        artwork: .init(
          url: "https://example.com/art/{w}x{h}bb.jpg",
          width: 1200,
          height: 1200,
          bgColor: "102030",
          textColor1: "ffffff",
          textColor2: "eeeeee",
          textColor3: "dddddd",
          textColor4: "cccccc",
        ),
        trackCount: 12,
        releaseDate: "2020-05-29",
        appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
      ),
    ])
  }

  func testDecodesArtistAlbumsResponse() throws {
    let data = try XCTUnwrap("""
    {
      "next": "/v1/catalog/us/artists/123456789/view/full-albums?offset=100",
      "data": [
        {
          "id": "1511628001",
          "type": "albums",
          "attributes": {
            "name": "Stories from the Outside",
            "artistName": "Lena Jonsson Trio",
            "artwork": {
              "url": "https://example.com/art/{w}x{h}bb.jpg",
              "width": 1200,
              "height": 1200,
              "bgColor": "102030",
              "textColor1": "ffffff",
              "textColor2": "eeeeee",
              "textColor3": "dddddd",
              "textColor4": "cccccc"
            },
            "trackCount": 12,
            "releaseDate": "2020-05-29",
            "url": "https://music.apple.com/us/album/stories-from-the-outside/1511628001"
          }
        }
      ]
    }
    """.data(using: .utf8))

    let page = try decodeAppleMusicCatalogArtistAlbums(from: data)

    expect(page).toEqual(.init(
      albums: [
        .init(
          id: .init(rawValue: "1511628001"),
          title: "Stories from the Outside",
          artistName: "Lena Jonsson Trio",
          artworkUrl: "https://example.com/art/600x600bb.jpg",
          artwork: .init(
            url: "https://example.com/art/{w}x{h}bb.jpg",
            width: 1200,
            height: 1200,
            bgColor: "102030",
            textColor1: "ffffff",
            textColor2: "eeeeee",
            textColor3: "dddddd",
            textColor4: "cccccc",
          ),
          trackCount: 12,
          releaseDate: "2020-05-29",
          appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
        ),
      ],
      next: "/v1/catalog/us/artists/123456789/view/full-albums?offset=100",
    ))
  }

  func testDecodesArtistTopSongsResponse() throws {
    let data = try XCTUnwrap("""
    {
      "data": [
        {
          "id": "123456790",
          "type": "songs",
          "attributes": {
            "name": "Sommarsvärta",
            "artistName": "Lena Jonsson Trio",
            "albumName": "Stories from the Outside",
            "durationInMillis": 200000,
            "artwork": {
              "url": "https://example.com/song/{w}x{h}bb.jpg"
            }
          }
        }
      ]
    }
    """.data(using: .utf8))

    let songs = try decodeAppleMusicCatalogArtistTopSongs(from: data)

    expect(songs).toEqual([
      .init(
        id: .init(rawValue: "123456790"),
        title: "Sommarsvärta",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
        artworkUrl: "https://example.com/song/600x600bb.jpg",
        durationInMillis: 200_000,
      ),
    ])
  }

  func testDecodesAlbumReleaseTypes() throws {
    let data = try XCTUnwrap("""
    {
      "results": {
        "albums": {
          "data": [
            {
              "id": "1",
              "attributes": {
                "name": "Full Album",
                "artistName": "Artist",
                "isSingle": false
              }
            },
            {
              "id": "2",
              "attributes": {
                "name": "New Song - Single",
                "artistName": "Artist",
                "isSingle": true
              }
            },
            {
              "id": "3",
              "attributes": {
                "name": "Short Release - EP",
                "artistName": "Artist",
                "isSingle": true
              }
            }
          ]
        }
      }
    }
    """.data(using: .utf8))

    let albums = try decodeAppleMusicCatalogAlbums(from: data)

    expect(albums.map(\.releaseType)).toEqual(["Album", "Single", "EP"])
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
      artwork: .init(url: "https://example.com/art/{w}x{h}bb.jpg"),
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
