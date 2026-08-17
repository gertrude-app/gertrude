import Foundation
import XCTest
import XExpect

@testable import Api

final class AppleMusicResolutionTests: XCTestCase {
  func testArtistResolutionURLUsesUSAndAllViews() throws {
    let url = try appleMusicCatalogArtistResolutionURL("artist-1", storefront: .default)
    let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))

    expect(components.path).toEqual("/v1/catalog/us/artists/artist-1")
    expect(components.queryItems?.first { $0.name == "views" }?.value)
      .toEqual("full-albums,singles,live-albums,compilation-albums,top-songs")
    expect(components.queryItems?.map(\.name)).toEqual(["views"])
  }

  func testResolutionURLsRequestRequiredRelationships() throws {
    let directAlbumURL = try appleMusicCatalogAlbumResolutionURL(
      ["album-1"],
      storefront: .default,
      requiringArtistRelationship: false,
    )
    let directAlbumComponents = try XCTUnwrap(
      URLComponents(url: directAlbumURL, resolvingAgainstBaseURL: false),
    )
    expect(directAlbumComponents.queryItems?.first { $0.name == "include" }?.value)
      .toEqual("tracks")
    expect(directAlbumComponents.queryItems?.map(\.name)).toEqual(["ids", "include"])

    let artistAlbumURL = try appleMusicCatalogAlbumResolutionURL(
      ["album-1"],
      storefront: .default,
      requiringArtistRelationship: true,
    )
    let artistAlbumComponents = try XCTUnwrap(
      URLComponents(url: artistAlbumURL, resolvingAgainstBaseURL: false),
    )
    expect(artistAlbumComponents.queryItems?.first { $0.name == "include" }?.value)
      .toEqual("artists,tracks")
    expect(artistAlbumComponents.queryItems?.map(\.name)).toEqual(["ids", "include"])

    let songsURL = try appleMusicCatalogSongsURL(["song-1"], storefront: .default)
    let songComponents = try XCTUnwrap(
      URLComponents(url: songsURL, resolvingAgainstBaseURL: false),
    )
    expect(songComponents.queryItems?.first { $0.name == "include" }?.value)
      .toEqual("albums,artists")
    expect(songComponents.queryItems?.map(\.name)).toEqual(["ids", "include"])
  }

  func testResolvesCompleteDirectAlbumAndFollowsTrackPagination() async throws {
    let loader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/albums":
        albumCollection([
          albumJson(
            id: "album-1",
            title: "Album",
            artistIds: nil,
            tracks: [
              songJson(id: "song-1", title: "First", artistName: "Artist"),
              songJson(id: "video-1", title: "Video", artistName: "Artist", type: "music-videos"),
            ],
            tracksNext: "/v1/catalog/us/albums/album-1/tracks?offset=2",
          ),
        ])
      case "/v1/catalog/us/albums/album-1/tracks":
        data("""
        {
          "data": [
            \(songJson(id: "song-2", title: "Second", artistName: "Guest"))
          ]
        }
        """)
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    let album = try await resolveAppleMusicCatalogAlbum(
      "album-1",
      storefront: .default,
      load: loader.dataLoader,
    )

    expect(album.id).toEqual("album-1")
    expect(album.artistIds).toBeEmpty()
    expect(album.tracks.map(\.id)).toEqual(["song-1", "song-2"])
    expect(album.tracks.map(\.artistName)).toEqual(["Artist", "Guest"])
    expect(album.tracks.map(\.albumId)).toEqual(["album-1", "album-1"])
    let requestPaths = await loader.requestPaths()
    expect(requestPaths).toEqual([
      "/v1/catalog/us/albums",
      "/v1/catalog/us/albums/album-1/tracks",
    ])
  }

  func testResolvesTrustedTrackUsingExactPreferredAlbumMetadata() async throws {
    let loader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/songs":
        data("""
        {
          "data": [{
            "id": "song-2",
            "type": "songs",
            "attributes": {
              "name": "Hydrated Track",
              "artistName": "Track Artist",
              "albumName": "Other Association",
              "artwork": {"url": "https://example.com/track/{w}x{h}.jpg"},
              "durationInMillis": 222000,
              "discNumber": 2,
              "trackNumber": 3,
              "contentRating": "explicit",
              "url": "https://music.apple.com/us/album/preferred/album-1?i=song-2"
            },
            "relationships": {
              "albums": {
                "data": [
                  {"id": "album-2", "type": "albums"},
                  {"id": "album-1", "type": "albums"}
                ]
              },
              "artists": {
                "data": [
                  {"id": "artist-1", "type": "artists"},
                  {"id": "artist-2", "type": "artists"}
                ]
              }
            }
          }]
        }
        """)
      case "/v1/catalog/us/albums":
        data("""
        {
          "data": [{
            "id": "album-1",
            "type": "albums",
            "attributes": {
              "name": "Preferred Album",
              "artistName": "Album Artist",
              "artwork": {
                "url": "https://example.com/album/{w}x{h}.jpg",
                "width": 1200,
                "height": 1200
              },
              "trackCount": 2,
              "releaseDate": "2026-01-02",
              "isSingle": false,
              "url": "https://music.apple.com/us/album/preferred/album-1"
            },
            "relationships": {
              "artists": {
                "data": [{"id": "artist-1", "type": "artists"}]
              },
              "tracks": {
                "data": [
                  \(songJson(id: "song-1", title: "First", artistName: "Album Artist")),
                  \(songJson(id: "song-2", title: "Album Track", artistName: "Album Artist"))
                ]
              }
            }
          }]
        }
        """)
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    let resolution = try await resolveAppleMusicCatalogTrack(
      .init(storefront: .default, trackId: "song-2", preferredAlbumId: "album-1"),
      load: loader.dataLoader,
    )

    expect(resolution.grant.track).toEqual(.init(
      id: "song-2",
      title: "Album Track",
      artistName: "Album Artist",
      artistIds: [],
      albumId: "album-1",
      albumTitle: "Album",
      durationInMillis: 180_000,
    ))
    expect(resolution.grant.track).toEqual(resolution.album.tracks[1])
    expect(resolution.grant.preferredAlbum).toEqual(.init(
      id: "album-1",
      title: "Preferred Album",
      artistName: "Album Artist",
      artistIds: ["artist-1"],
      artworkUrl: "https://example.com/album/600x600.jpg",
      artwork: .init(
        url: "https://example.com/album/{w}x{h}.jpg",
        width: 1200,
        height: 1200,
      ),
      trackCount: 2,
      releaseDate: "2026-01-02",
      releaseType: "Album",
      appleMusicUrl: "https://music.apple.com/us/album/preferred/album-1",
    ))
    expect(resolution.grant.catalogPosition).toEqual(1)
    expect(resolution.album.tracks.map(\.id)).toEqual(["song-1", "song-2"])
    expect(resolution.album.appleMusicUrl)
      .toEqual("https://music.apple.com/us/album/preferred/album-1")
    XCTAssertNoThrow(try resolution.grant.validate(
      appleMusicTrackId: "song-2",
      preferredAlbumId: "album-1",
    ))
    let requestPaths = await loader.requestPaths()
    expect(requestPaths).toEqual([
      "/v1/catalog/us/songs",
      "/v1/catalog/us/albums",
    ])
  }

  func testRejectsPreferredAlbumOutsideTrackRelationships() async throws {
    let loader = StubAppleMusicLoader { url in
      guard url.path == "/v1/catalog/us/songs" else {
        throw StubError.unexpectedURL(url.absoluteString)
      }
      return data("""
      {
        "data": [
          \(hydratedSongJson(id: "song-1", artistIds: ["artist-1"], albumId: "album-2"))
        ]
      }
      """)
    }

    do {
      _ = try await resolveAppleMusicCatalogTrack(
        .init(storefront: .default, trackId: "song-1", preferredAlbumId: "album-1"),
        load: loader.dataLoader,
      )
      XCTFail("expected preferred album mismatch")
    } catch let error as AppleMusicResolutionError {
      expect(error).toEqual(.trackNotAssociatedWithAlbum(
        track: "song-1",
        album: "album-1",
      ))
    }

    let requestPaths = await loader.requestPaths()
    expect(requestPaths).toEqual(["/v1/catalog/us/songs"])
  }

  func testRejectsTrackMissingFromPreferredAlbum() async throws {
    let loader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/songs":
        data("""
        {
          "data": [
            \(hydratedSongJson(id: "song-1", artistIds: ["artist-1"], albumId: "album-1"))
          ]
        }
        """)
      case "/v1/catalog/us/albums":
        albumCollection([
          albumJson(
            id: "album-1",
            title: "Album",
            artistIds: ["artist-1"],
            tracks: [songJson(id: "song-2", title: "Other", artistName: "Artist")],
          ),
        ])
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    do {
      _ = try await resolveAppleMusicCatalogTrack(
        .init(storefront: .default, trackId: "song-1", preferredAlbumId: "album-1"),
        load: loader.dataLoader,
      )
      XCTFail("expected preferred album to contain track")
    } catch let error as AppleMusicResolutionError {
      expect(error).toEqual(.albumMissingTrack(album: "album-1", track: "song-1"))
    }
  }

  func testResolvesVariousArtistsAlbumWithEmptyArtistsRelationship() async throws {
    let loader = StubAppleMusicLoader { url in
      guard url.path == "/v1/catalog/us/albums" else {
        throw StubError.unexpectedURL(url.absoluteString)
      }
      return albumCollection([
        albumJson(
          id: "album-1",
          title: "Soundtrack",
          artistName: "Various Artists",
          artistIds: [],
          tracks: [songJson(id: "song-1", title: "Song", artistName: "Artist")],
        ),
      ])
    }

    let album = try await resolveAppleMusicCatalogAlbum(
      "album-1",
      storefront: .default,
      load: loader.dataLoader,
    )

    expect(album.artistName).toEqual("Various Artists")
    expect(album.artistIds).toBeEmpty()
    expect(album.tracks.map(\.id)).toEqual(["song-1"])
  }

  func testResolvesArtistUsingExactRelationshipsAndCompleteReleasePages() async throws {
    let loader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/artists/artist-1":
        data("""
        {
          "data": [{
            "id": "artist-1",
            "type": "artists",
            "attributes": {
              "name": "Artist",
              "genreNames": ["Folk"],
              "url": "https://music.apple.com/us/artist/artist/artist-1"
            },
            "views": {
              "full-albums": {
                "data": [
                  {"id": "own-a", "type": "albums"},
                  {"id": "collab", "type": "albums"},
                  {"id": "paged-collab", "type": "albums"}
                ],
                "next": "/v1/catalog/us/artists/artist-1/view/full-albums?offset=2"
              },
              "singles": {"data": [{"id": "own-single", "type": "albums"}]},
              "live-albums": {"data": []},
              "compilation-albums": {
                "data": [
                  {"id": "one-artist-comp", "type": "albums"},
                  {"id": "various", "type": "albums"}
                ]
              },
              "top-songs": {
                "data": [
                  {"id": "top-own", "type": "songs"},
                  {"id": "top-feature", "type": "songs"},
                  {"id": "top-collab-album", "type": "songs"},
                  {"id": "top-paged-feature", "type": "songs"}
                ],
                "next": "/v1/catalog/us/artists/artist-1/view/top-songs?offset=3"
              }
            }
          }]
        }
        """)
      case "/v1/catalog/us/artists/artist-1/view/full-albums":
        data("""
        {
          "data": [
            {"id": "own-b", "type": "albums"},
            {"id": "own-a", "type": "albums"}
          ]
        }
        """)
      case "/v1/catalog/us/artists/artist-1/view/top-songs":
        data("""
        {"data": [{"id": "top-own-b", "type": "songs"}]}
        """)
      case "/album-artists-page", "/song-artists-page":
        data("""
        {"data": [{"id": "artist-2", "type": "artists"}]}
        """)
      case "/v1/catalog/us/albums":
        albumCollection([
          albumJson(id: "own-a", title: "Own A", artistIds: ["artist-1"], tracks: [
            songJson(id: "top-own", title: "Top Own", artistName: "Artist"),
            songJson(id: "guest-track", title: "Guest Track", artistName: "Artist feat. Guest"),
          ]),
          albumJson(id: "collab", title: "Collaboration", artistIds: ["artist-1", "artist-2"]),
          albumJson(
            id: "paged-collab",
            title: "Paged Collaboration",
            artistIds: ["artist-1"],
            artistsNext: "/album-artists-page",
          ),
          albumJson(
            id: "own-b",
            title: "Own B",
            artistIds: ["artist-1"],
            tracks: [songJson(id: "top-own-b", title: "Top Own B", artistName: "Artist")],
          ),
          albumJson(
            id: "own-single",
            title: "Single - Single",
            artistIds: ["artist-1"],
            isSingle: true,
          ),
          albumJson(id: "one-artist-comp", title: "Greatest Hits", artistIds: ["artist-1"]),
          albumJson(id: "various", title: "Various", artistIds: []),
        ])
      case "/v1/catalog/us/songs":
        data("""
        {
          "data": [
            \(hydratedSongJson(id: "top-own", artistIds: ["artist-1"], albumId: "own-a")),
            \(hydratedSongJson(
              id: "top-feature",
              artistIds: ["artist-1", "artist-2"],
              albumId: "own-a",
            )),
            \(hydratedSongJson(id: "top-collab-album", artistIds: ["artist-1"], albumId: "collab")),
            \(hydratedSongJson(
              id: "top-paged-feature",
              artistIds: ["artist-1"],
              artistsNext: "/song-artists-page",
              albumId: "own-a",
            )),
            \(hydratedSongJson(id: "top-own-b", artistIds: ["artist-1"], albumId: "own-b"))
          ]
        }
        """)
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    let artist = try await resolveAppleMusicCatalogArtist(
      "artist-1",
      storefront: .default,
      load: loader.dataLoader,
    )

    expect(artist.name).toEqual("Artist")
    expect(artist.catalogMetadata?.genreNames).toEqual(["Folk"])
    expect(artist.albums.map(\.id)).toEqual([
      "own-a",
      "own-b",
      "own-single",
      "one-artist-comp",
    ])
    expect(artist.albums.first?.tracks.map(\.id)).toEqual(["top-own", "guest-track"])
    expect(artist.topSongs.map(\.id)).toEqual(["top-own", "top-own-b"])
    expect(artist.topSongs.map(\.albumId)).toEqual(["own-a", "own-b"])
  }

  func testAlbumHydrationBatchesAtOneHundred() async throws {
    let ids = (0 ... 100).map { "album-\($0)" }
    let references = ids.map { "{\"id\":\"\($0)\",\"type\":\"albums\"}" }
      .joined(separator: ",")
    let loader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/artists/artist-1":
        return data("""
        {
          "data": [{
            "id": "artist-1",
            "attributes": {"name": "Artist"},
            "views": {
              "full-albums": {"data": [\(references)]},
              "singles": {"data": []},
              "live-albums": {"data": []},
              "compilation-albums": {"data": []},
              "top-songs": {"data": []}
            }
          }]
        }
        """)
      case "/v1/catalog/us/albums":
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let batch = components?.queryItems?.first { $0.name == "ids" }?.value?
          .split(separator: ",").map(String.init) ?? []
        return albumCollection(batch.map {
          albumJson(id: $0, title: $0, artistIds: ["artist-1"])
        })
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    let artist = try await resolveAppleMusicCatalogArtist(
      "artist-1",
      storefront: .default,
      load: loader.dataLoader,
    )

    expect(artist.albums).toHaveCount(101)
    let albumBatchSizes = await loader.albumBatchSizes()
    expect(albumBatchSizes).toEqual([100, 1])
  }

  func testMissingAlbumAndPartialPaginationFailTheWholeResolution() async throws {
    let missingLoader = StubAppleMusicLoader { url in
      guard url.path == "/v1/catalog/us/albums" else {
        throw StubError.unexpectedURL(url.absoluteString)
      }
      return data("{\"data\":[]}")
    }

    do {
      _ = try await resolveAppleMusicCatalogAlbum(
        "missing",
        storefront: .default,
        load: missingLoader.dataLoader,
      )
      XCTFail("expected missing album error")
    } catch let error as AppleMusicResolutionError {
      expect(error).toEqual(.missingResource(type: "album", id: "missing"))
    }

    let partialLoader = StubAppleMusicLoader { url in
      switch url.path {
      case "/v1/catalog/us/artists/artist-1":
        data("""
        {
          "data": [{
            "id": "artist-1",
            "attributes": {"name": "Artist"},
            "views": {
              "full-albums": {
                "data": [{"id": "album-1", "type": "albums"}],
                "next": "/failed-page"
              },
              "singles": {"data": []},
              "live-albums": {"data": []},
              "compilation-albums": {"data": []},
              "top-songs": {"data": []}
            }
          }]
        }
        """)
      case "/failed-page":
        throw StubError.pageFailed
      default:
        throw StubError.unexpectedURL(url.absoluteString)
      }
    }

    do {
      _ = try await resolveAppleMusicCatalogArtist(
        "artist-1",
        storefront: .default,
        load: partialLoader.dataLoader,
      )
      XCTFail("expected pagination error")
    } catch let error as StubError {
      expect(error).toEqual(.pageFailed)
    }
  }
}

actor StubAppleMusicLoader {
  private let response: @Sendable (URL) throws -> Data
  private var requests: [URL] = []

  init(response: @escaping @Sendable (URL) throws -> Data) {
    self.response = response
  }

  nonisolated var dataLoader: AppleMusicDataLoader {
    { url in try await self.load(url) }
  }

  func load(_ url: URL) throws -> Data {
    self.requests.append(url)
    return try self.response(url)
  }

  func requestPaths() -> [String] {
    self.requests.map(\.path)
  }

  func requestURLs() -> [URL] {
    self.requests
  }

  func albumBatchSizes() -> [Int] {
    self.requests.compactMap { url in
      guard url.path == "/v1/catalog/us/albums" else { return nil }
      let ids = URLComponents(url: url, resolvingAgainstBaseURL: false)?
        .queryItems?.first { $0.name == "ids" }?.value
      return ids?.split(separator: ",").count
    }
  }
}

enum StubError: Error, Equatable {
  case pageFailed
  case unexpectedURL(String)
}

private func albumCollection(_ albums: [String]) -> Data {
  data("{\"data\":[\(albums.joined(separator: ","))]}")
}

private func albumJson(
  id: String,
  title: String,
  artistName: String = "Artist",
  artistIds: [String]?,
  tracks: [String] = [],
  tracksNext: String? = nil,
  artistsNext: String? = nil,
  isSingle: Bool = false,
) -> String {
  let artistsRelationship = artistIds.map { artistIds in
    let artists = artistIds.map { "{\"id\":\"\($0)\",\"type\":\"artists\"}" }
      .joined(separator: ",")
    let next = artistsNext.map { ",\"next\":\"\($0)\"" } ?? ""
    return "\"artists\": {\"data\": [\(artists)]\(next)},"
  } ?? ""
  let tracksNext = tracksNext.map { ",\"next\":\"\($0)\"" } ?? ""
  return """
  {
    "id": "\(id)",
    "type": "albums",
    "attributes": {
      "name": "\(title)",
      "artistName": "\(artistName)",
      "trackCount": \(tracks.count),
      "isSingle": \(isSingle)
    },
    "relationships": {
      \(artistsRelationship)
      "tracks": {"data": [\(tracks.joined(separator: ","))]\(tracksNext)}
    }
  }
  """
}

private func songJson(
  id: String,
  title: String,
  artistName: String,
  type: String = "songs",
) -> String {
  """
  {
    "id": "\(id)",
    "type": "\(type)",
    "attributes": {
      "name": "\(title)",
      "artistName": "\(artistName)",
      "albumName": "Album",
      "durationInMillis": 180000
    }
  }
  """
}

private func hydratedSongJson(
  id: String,
  artistIds: [String],
  artistsNext: String? = nil,
  albumId: String,
) -> String {
  let artists = artistIds.map { "{\"id\":\"\($0)\",\"type\":\"artists\"}" }
    .joined(separator: ",")
  let artistsNext = artistsNext.map { ",\"next\":\"\($0)\"" } ?? ""
  return """
  {
    "id": "\(id)",
    "type": "songs",
    "attributes": {
      "name": "\(id)",
      "artistName": "Artist",
      "albumName": "Album"
    },
    "relationships": {
      "artists": {"data": [\(artists)]\(artistsNext)},
      "albums": {"data": [{"id": "\(albumId)", "type": "albums"}]}
    }
  }
  """
}

private func data(_ json: String) -> Data {
  Data(json.utf8)
}
