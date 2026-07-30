import Foundation
import XCTest
import XExpect

@testable import Api

final class AppleMusicClientTests: XCTestCase {
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
    expect(queryItems.first { $0.name == "types" }?.value).toEqual("songs,albums,artists")
    expect(queryItems.first { $0.name == "limit" }?.value).toEqual("25")
    expect(queryItems.first { $0.name == "with" }?.value).toEqual("topResults")
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

  func testDecodesMixedSearchAlbumResponse() throws {
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

    let results = try decodeAppleMusicCatalogSearchResults(from: data)

    expect(results.albums).toEqual([
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

    let results = try decodeAppleMusicCatalogSearchResults(from: data)

    expect(results.albums.map(\.releaseType)).toEqual(["Album", "Single", "EP"])
  }

  func testDecodesMixedSearchArtistResponse() throws {
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

    let results = try decodeAppleMusicCatalogSearchResults(from: data)

    expect(results.artists).toEqual([
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
        "songs": {
          "data": [{"id": "song-collection", "type": "songs"}]
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
    expect(results.tracks).toBeEmpty()
  }

  func testSearchHydratesCollectionAndTopResultSongs() async throws {
    let loader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/search":
        Data("""
        {
          "results": {
            "songs": {
              "data": [{"id": "song-collection", "type": "songs"}]
            },
            "albums": {
              "data": [{
                "id": "album-result",
                "type": "albums",
                "attributes": {
                  "name": "Album Result",
                  "artistName": "Result Artist"
                }
              }]
            },
            "artists": {
              "data": [{
                "id": "artist-result",
                "type": "artists",
                "attributes": {"name": "Result Artist"}
              }]
            },
            "topResults": {
              "data": [
                {"id": "song-top", "type": "songs"},
                {
                  "id": "album-result",
                  "type": "albums",
                  "attributes": {
                    "name": "Album Result",
                    "artistName": "Result Artist"
                  }
                },
                {
                  "id": "artist-result",
                  "type": "artists",
                  "attributes": {"name": "Result Artist"}
                }
              ]
            }
          }
        }
        """.utf8)
      case "/v1/catalog/us/songs":
        Data("""
        {
          "data": [
            {
              "id": "song-collection",
              "type": "songs",
              "attributes": {
                "name": "Collection Track",
                "artistName": "Collection Artist",
                "albumName": "Version B",
                "artwork": {
                  "url": "https://example.com/collection/{w}x{h}.jpg",
                  "width": 1200,
                  "height": 1200,
                  "bgColor": "102030"
                },
                "durationInMillis": 123000,
                "discNumber": 2,
                "trackNumber": 4,
                "contentRating": "explicit",
                "url": "https://music.apple.com/us/album/version-b/album-b?i=song-collection"
              },
              "relationships": {
                "albums": {
                  "data": [
                    {"id": "album-a", "type": "albums"},
                    {"id": "album-b", "type": "albums"}
                  ]
                },
                "artists": {
                  "data": [{"id": "artist-collection", "type": "artists"}]
                }
              }
            },
            {
              "id": "song-top",
              "type": "songs",
              "attributes": {
                "name": "Top Track",
                "artistName": "Top Artist",
                "albumName": "Top Album",
                "durationInMillis": 234000
              },
              "relationships": {
                "albums": {
                  "data": [{"id": "album-top", "type": "albums"}]
                },
                "artists": {
                  "data": [{"id": "artist-top", "type": "artists"}]
                }
              }
            }
          ]
        }
        """.utf8)
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    let results = try await searchAppleMusicCatalog(
      .init(term: "track search", limit: 10),
      load: loader.dataLoader,
    )

    expect(results.tracks).toEqual([
      .init(
        id: "song-collection",
        title: "Collection Track",
        artistName: "Collection Artist",
        artistIds: ["artist-collection"],
        preferredAlbumId: "album-b",
        albumTitle: "Version B",
        artworkUrl: "https://example.com/collection/600x600.jpg",
        artwork: .init(
          url: "https://example.com/collection/{w}x{h}.jpg",
          width: 1200,
          height: 1200,
          bgColor: "102030",
        ),
        durationInMillis: 123_000,
        discNumber: 2,
        trackNumber: 4,
        contentRating: .explicit,
        appleMusicUrl:
        "https://music.apple.com/us/album/version-b/album-b?i=song-collection",
      ),
      .init(
        id: "song-top",
        title: "Top Track",
        artistName: "Top Artist",
        artistIds: ["artist-top"],
        preferredAlbumId: "album-top",
        albumTitle: "Top Album",
        durationInMillis: 234_000,
      ),
    ])
    expect(results.items.map(\.kind)).toEqual([.track, .album, .artist])
    expect(results.items.first?.track).toEqual(results.tracks[1])
    expect(results.albums.map(\.id)).toEqual(["album-result"])
    expect(results.artists.map(\.id)).toEqual(["artist-result"])

    let requests = await loader.requestURLs()
    expect(requests.map(\.path)).toEqual([
      "/v1/catalog/us/search",
      "/v1/catalog/us/songs",
    ])
    let hydrationComponents = try XCTUnwrap(
      URLComponents(url: requests[1], resolvingAgainstBaseURL: false),
    )
    expect(hydrationComponents.queryItems?.first { $0.name == "ids" }?.value)
      .toEqual("song-collection,song-top")
    expect(hydrationComponents.queryItems?.first { $0.name == "include" }?.value)
      .toEqual("albums,artists")
  }

  func testSearchOmitsSongWithoutExactAlbumRelationship() async throws {
    let loader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/search":
        Data("""
        {
          "results": {
            "songs": {
              "data": [
                {"id": "orphan", "type": "songs"},
                {"id": "usable", "type": "songs"}
              ]
            },
            "topResults": {
              "data": [
                {"id": "orphan", "type": "songs"},
                {"id": "usable", "type": "songs"}
              ]
            }
          }
        }
        """.utf8)
      case "/v1/catalog/us/songs":
        Data("""
        {
          "data": [
            {
              "id": "orphan",
              "type": "songs",
              "attributes": {
                "name": "Orphan",
                "artistName": "Artist",
                "albumName": "Unrelated Text"
              },
              "relationships": {
                "albums": {"data": []},
                "artists": {"data": [{"id": "artist-1", "type": "artists"}]}
              }
            },
            {
              "id": "usable",
              "type": "songs",
              "attributes": {
                "name": "Usable",
                "artistName": "Artist",
                "albumName": "Exact Album"
              },
              "relationships": {
                "albums": {"data": [{"id": "album-1", "type": "albums"}]},
                "artists": {"data": [{"id": "artist-1", "type": "artists"}]}
              }
            }
          ]
        }
        """.utf8)
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    let results = try await searchAppleMusicCatalog(
      .init(term: "tracks"),
      load: loader.dataLoader,
    )

    expect(results.tracks.map(\.id)).toEqual(["usable"])
    expect(results.items.map(\.track?.id)).toEqual(["usable"])
  }

  func testPreferredAlbumUsesOfficialURLOnlyForExactRelationship() {
    expect(preferredAppleMusicAlbumId(
      among: ["album-a", "album-b"],
      appleMusicUrl: "https://music.apple.com/us/album/version/album-b?i=song-1",
    )).toEqual("album-b")

    expect(preferredAppleMusicAlbumId(
      among: ["album-b", "album-a"],
      appleMusicUrl: "https://music.apple.com/us/album/unrelated/album-z?i=song-1",
    )).toEqual("album-a")

    expect(preferredAppleMusicAlbumId(
      among: [],
      appleMusicUrl: "https://music.apple.com/us/album/version/album-a?i=song-1",
    )).toBeNil()
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

  func testDefaultTestClientResolvesKnownTrack() async throws {
    let resolution = try await AppleMusicClient.testValue.resolveTrack(.init(
      trackId: "1511628002",
      preferredAlbumId: "1511628001",
    ))

    expect(resolution.grant.track.id).toEqual("1511628002")
    expect(resolution.grant.preferredAlbum.id).toEqual("1511628001")
    expect(resolution.grant.catalogPosition).toEqual(0)
    expect(resolution.album.tracks.map(\.id)).toEqual(["1511628002", "1511628003"])
  }

  func testDecodesMissingAlbumsAsEmpty() throws {
    let data = try XCTUnwrap("""
    {
      "results": {}
    }
    """.data(using: .utf8))

    let results = try decodeAppleMusicCatalogSearchResults(from: data)

    expect(results.albums).toEqual([])
    expect(results.artists).toEqual([])
  }
}
