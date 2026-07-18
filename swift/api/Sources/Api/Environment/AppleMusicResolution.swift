import Foundation
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

typealias AppleMusicDataLoader = @Sendable (URL) async throws -> Data

enum AppleMusicResolutionError: Error, Equatable, CustomStringConvertible {
  case invalidURL
  case missingResource(type: String, id: String)
  case incompleteResource(type: String, id: String, relationship: String)
  case paginationCycle(String)

  var description: String {
    switch self {
    case .invalidURL:
      "Invalid Apple Music catalog resolution URL"
    case .missingResource(let type, let id):
      "Apple Music \(type) `\(id)` was not found"
    case .incompleteResource(let type, let id, let relationship):
      "Apple Music \(type) `\(id)` has no complete `\(relationship)` relationship"
    case .paginationCycle(let next):
      "Apple Music pagination repeated `\(next)`"
    }
  }
}

func appleMusicDataLoader(developerToken: String) -> AppleMusicDataLoader {
  { url in
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await XHttp.data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw AppleMusicError.invalidResponseType
    }
    guard (200 ... 299).contains(response.statusCode) else {
      throw AppleMusicError.httpError(
        statusCode: response.statusCode,
        body: String(data: data, encoding: .utf8) ?? "<decode err>",
      )
    }
    return data
  }
}

func appleMusicCatalogArtistResolutionURL(_ artistId: Music.ArtistId) throws -> URL {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.music.apple.com"
  components.path = "/v1/catalog/us/artists/\(artistId.rawValue)"
  components.queryItems = [
    .init(
      name: "views",
      value: "full-albums,singles,live-albums,compilation-albums,top-songs",
    ),
  ]
  guard let url = components.url else {
    throw AppleMusicResolutionError.invalidURL
  }
  return url
}

func appleMusicCatalogAlbumResolutionURL(_ albumIds: [Music.AlbumId]) throws -> URL {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.music.apple.com"
  components.path = "/v1/catalog/us/albums"
  components.queryItems = [
    .init(name: "ids", value: albumIds.map(\.rawValue).joined(separator: ",")),
    .init(name: "include", value: "artists,tracks"),
  ]
  guard !albumIds.isEmpty, let url = components.url else {
    throw AppleMusicResolutionError.invalidURL
  }
  return url
}

func appleMusicCatalogSongsURL(_ songIds: [Music.TrackId]) throws -> URL {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.music.apple.com"
  components.path = "/v1/catalog/us/songs"
  components.queryItems = [
    .init(name: "ids", value: songIds.map(\.rawValue).joined(separator: ",")),
    .init(name: "include", value: "albums,artists"),
  ]
  guard !songIds.isEmpty, let url = components.url else {
    throw AppleMusicResolutionError.invalidURL
  }
  return url
}

func resolveAppleMusicCatalogAlbum(
  _ albumId: Music.AlbumId,
  load: AppleMusicDataLoader,
) async throws -> Music.ResolvedAlbum {
  let albums = try await resolvedAppleMusicAlbums([albumId], load: load)
  guard let album = albums.first, album.id == albumId else {
    throw AppleMusicResolutionError.missingResource(type: "album", id: albumId.rawValue)
  }
  return album
}

func resolveAppleMusicCatalogArtist(
  _ artistId: Music.ArtistId,
  load: AppleMusicDataLoader,
) async throws -> Music.ResolvedArtist {
  let url = try appleMusicCatalogArtistResolutionURL(artistId)
  let response = try await JSONDecoder().decode(
    AppleMusicArtistResolutionResponse.self,
    from: load(url),
  )
  guard let artist = response.data.first(where: { $0.id == artistId.rawValue }) else {
    throw AppleMusicResolutionError.missingResource(type: "artist", id: artistId.rawValue)
  }

  let views = artist.views
  var releaseIds: [Music.AlbumId] = []
  var seenReleaseIds = Set<Music.AlbumId>()
  for view in [
    views.fullAlbums,
    views.singles,
    views.liveAlbums,
    views.compilationAlbums,
  ] {
    let ids = try await completeReferenceIds(
      in: view,
      type: "albums",
      limit: nil,
      load: load,
    ).map(Music.AlbumId.init(rawValue:))
    for id in ids where seenReleaseIds.insert(id).inserted {
      releaseIds.append(id)
    }
  }

  let topSongReferences = try await completeReferenceIds(
    in: views.topSongs,
    type: "songs",
    limit: 12,
    load: load,
  ).map(Music.TrackId.init(rawValue:))
  var seenTopSongIds = Set<Music.TrackId>()
  let topSongIds = topSongReferences.filter { seenTopSongIds.insert($0).inserted }
  let hydratedAlbums = try await resolvedAppleMusicAlbums(releaseIds, load: load)
  let qualifyingAlbums = hydratedAlbums.filter { album in
    Set(album.artistIds) == [artistId]
  }
  let qualifyingAlbumsById = Dictionary(
    uniqueKeysWithValues: qualifyingAlbums.map { ($0.id, $0) },
  )
  let hydratedTopSongs = try await resolvedAppleMusicSongs(topSongIds, load: load)
  var topSongs: [Music.ResolvedTrack] = []
  for song in hydratedTopSongs {
    guard Set(song.artistIds) == [artistId] else { continue }
    guard song.albumIds.count == 1, let albumId = song.albumIds.first else { continue }
    guard let album = qualifyingAlbumsById[albumId] else { continue }
    guard album.tracks.contains(where: { $0.id == song.typedId }) else { continue }
    topSongs.append(song.resolvedTrack(album: album))
  }

  return .init(
    id: artistId,
    name: artist.attributes.name,
    catalogMetadata: artist.attributes.catalogMetadata,
    topSongs: topSongs,
    albums: qualifyingAlbums,
  )
}

private func resolvedAppleMusicAlbums(
  _ albumIds: [Music.AlbumId],
  load: AppleMusicDataLoader,
) async throws -> [Music.ResolvedAlbum] {
  guard !albumIds.isEmpty else { return [] }
  var rawAlbumsById: [Music.AlbumId: AppleMusicRawAlbum] = [:]
  for start in stride(from: 0, to: albumIds.count, by: 100) {
    let end = min(start + 100, albumIds.count)
    let batch = Array(albumIds[start ..< end])
    let url = try appleMusicCatalogAlbumResolutionURL(batch)
    let response = try await JSONDecoder().decode(
      AppleMusicAlbumResolutionResponse.self,
      from: load(url),
    )
    for album in response.data where album.type == "albums" {
      rawAlbumsById[album.typedId] = album
    }
  }

  var resolved: [Music.ResolvedAlbum] = []
  for albumId in albumIds {
    guard let album = rawAlbumsById[albumId] else {
      throw AppleMusicResolutionError.missingResource(type: "album", id: albumId.rawValue)
    }
    try await resolved.append(album.resolved(load: load))
  }
  return resolved
}

private func resolvedAppleMusicSongs(
  _ songIds: [Music.TrackId],
  load: AppleMusicDataLoader,
) async throws -> [AppleMusicRawSong] {
  guard !songIds.isEmpty else { return [] }
  var songsById: [Music.TrackId: AppleMusicRawSong] = [:]
  for start in stride(from: 0, to: songIds.count, by: 300) {
    let end = min(start + 300, songIds.count)
    let batch = Array(songIds[start ..< end])
    let url = try appleMusicCatalogSongsURL(batch)
    let response = try await JSONDecoder().decode(
      AppleMusicSongResolutionResponse.self,
      from: load(url),
    )
    for song in response.data where song.type == "songs" {
      songsById[song.typedId] = song
    }
  }

  var resolved: [AppleMusicRawSong] = []
  for songId in songIds {
    guard var song = songsById[songId] else {
      throw AppleMusicResolutionError.missingResource(type: "song", id: songId.rawValue)
    }
    guard song.attributes != nil else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "song",
        id: songId.rawValue,
        relationship: "attributes",
      )
    }
    guard let albums = song.relationships?.albums else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "song",
        id: songId.rawValue,
        relationship: "albums",
      )
    }
    guard let artists = song.relationships?.artists else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "song",
        id: songId.rawValue,
        relationship: "artists",
      )
    }
    let albumIds = try await completeReferenceIds(
      in: albums,
      type: "albums",
      limit: nil,
      load: load,
    )
    let artistIds = try await completeReferenceIds(
      in: artists,
      type: "artists",
      limit: nil,
      load: load,
    )
    guard !albumIds.isEmpty else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "song",
        id: songId.rawValue,
        relationship: "albums",
      )
    }
    guard !artistIds.isEmpty else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "song",
        id: songId.rawValue,
        relationship: "artists",
      )
    }
    song.relationships?.albums = .init(
      data: albumIds.map { .init(id: $0, type: "albums") },
      next: nil,
    )
    song.relationships?.artists = .init(
      data: artistIds.map { .init(id: $0, type: "artists") },
      next: nil,
    )
    resolved.append(song)
  }
  return resolved
}

private func completeReferenceIds(
  in firstPage: AppleMusicReferencePage,
  type: String,
  limit: Int?,
  load: AppleMusicDataLoader,
) async throws -> [String] {
  var seenIds = Set<String>()
  var ids: [String] = firstPage.data.compactMap { reference in
    guard reference.type == type, seenIds.insert(reference.id).inserted else { return nil }
    return reference.id
  }
  var next = firstPage.next
  var visited = Set<String>()
  while limit == nil || ids.count < limit!, let nextPath = next {
    guard visited.insert(nextPath).inserted else {
      throw AppleMusicResolutionError.paginationCycle(nextPath)
    }
    let url = try appleMusicCatalogURL(fromNext: nextPath)
    let page = try await JSONDecoder().decode(
      AppleMusicReferencePage.self,
      from: load(url),
    )
    for reference in page.data where reference.type == type {
      if seenIds.insert(reference.id).inserted {
        ids.append(reference.id)
      }
    }
    next = page.next
  }
  if let limit {
    return Array(ids.prefix(limit))
  }
  return ids
}

private struct AppleMusicArtistResolutionResponse: Decodable {
  var data: [Artist]

  struct Artist: Decodable {
    var id: String
    var attributes: Attributes
    var views: Views
  }

  struct Attributes: Decodable {
    var name: String
    var artwork: Artwork?
    var editorialNotes: EditorialNotes?
    var genreNames: [String]?
    var url: String?

    var catalogMetadata: Music.CatalogMetadata {
      .init(
        artwork: self.artwork?.catalogArtwork,
        editorialNotes: self.editorialNotes.map {
          .init(tagline: $0.tagline, short: $0.short, standard: $0.standard, name: $0.name)
        },
        appleMusicUrl: self.url,
        genreNames: self.genreNames ?? [],
      )
    }
  }

  struct Views: Decodable {
    var fullAlbums: AppleMusicReferencePage
    var singles: AppleMusicReferencePage
    var liveAlbums: AppleMusicReferencePage
    var compilationAlbums: AppleMusicReferencePage
    var topSongs: AppleMusicReferencePage

    enum CodingKeys: String, CodingKey {
      case fullAlbums = "full-albums"
      case singles
      case liveAlbums = "live-albums"
      case compilationAlbums = "compilation-albums"
      case topSongs = "top-songs"
    }
  }
}

private struct AppleMusicAlbumResolutionResponse: Decodable {
  var data: [AppleMusicRawAlbum]
}

private struct AppleMusicSongResolutionResponse: Decodable {
  var data: [AppleMusicRawSong]
}

private struct AppleMusicReferencePage: Decodable {
  var data: [AppleMusicReference]
  var next: String?
}

private struct AppleMusicReference: Decodable {
  var id: String
  var type: String
}

private struct AppleMusicRawAlbum: Decodable {
  var id: String
  var type: String
  var attributes: Attributes
  var relationships: Relationships?

  var typedId: Music.AlbumId { .init(rawValue: self.id) }

  struct Attributes: Decodable {
    var name: String
    var artistName: String
    var artwork: Artwork?
    var trackCount: Int?
    var releaseDate: String?
    var isSingle: Bool?

    var releaseType: String? {
      if self.name.lowercased().hasSuffix(" - ep") {
        "EP"
      } else if let isSingle = self.isSingle {
        isSingle ? "Single" : "Album"
      } else {
        nil
      }
    }
  }

  struct Relationships: Decodable {
    var artists: AppleMusicReferencePage?
    var tracks: AppleMusicRawTrackPage?
  }

  func resolved(load: AppleMusicDataLoader) async throws -> Music.ResolvedAlbum {
    guard let artists = self.relationships?.artists else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "album",
        id: self.id,
        relationship: "artists",
      )
    }
    let artistIds = try await completeReferenceIds(
      in: artists,
      type: "artists",
      limit: nil,
      load: load,
    )
    guard !artistIds.isEmpty else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "album",
        id: self.id,
        relationship: "artists",
      )
    }
    guard let firstTracksPage = self.relationships?.tracks else {
      throw AppleMusicResolutionError.incompleteResource(
        type: "album",
        id: self.id,
        relationship: "tracks",
      )
    }

    var rawTracks = firstTracksPage.data
    var next = firstTracksPage.next
    var visited = Set<String>()
    while let nextPath = next {
      guard visited.insert(nextPath).inserted else {
        throw AppleMusicResolutionError.paginationCycle(nextPath)
      }
      let url = try appleMusicCatalogURL(fromNext: nextPath)
      let page = try await JSONDecoder().decode(
        AppleMusicRawTrackPage.self,
        from: load(url),
      )
      rawTracks.append(contentsOf: page.data)
      next = page.next
    }

    let albumId = self.typedId
    var seenTrackIds = Set<Music.TrackId>()
    var tracks: [Music.ResolvedTrack] = []
    for track in rawTracks where track.type == "songs" {
      guard let attributes = track.attributes else {
        throw AppleMusicResolutionError.incompleteResource(
          type: "song",
          id: track.id,
          relationship: "attributes",
        )
      }
      guard seenTrackIds.insert(track.typedId).inserted else { continue }
      tracks.append(.init(
        id: track.typedId,
        title: attributes.name,
        artistName: attributes.artistName,
        artistIds: [],
        albumId: albumId,
        albumTitle: attributes.albumName ?? self.attributes.name,
        artworkUrl: sizedAppleMusicResolutionArtworkUrl(attributes.artwork?.url),
        durationInMillis: attributes.durationInMillis,
      ))
    }

    return .init(
      id: albumId,
      title: self.attributes.name,
      artistName: self.attributes.artistName,
      artistIds: artistIds.map(Music.ArtistId.init(rawValue:)),
      artworkUrl: sizedAppleMusicResolutionArtworkUrl(self.attributes.artwork?.url),
      artwork: self.attributes.artwork?.catalogArtwork,
      trackCount: self.attributes.trackCount,
      releaseDate: self.attributes.releaseDate,
      releaseType: self.attributes.releaseType,
      tracks: tracks,
    )
  }
}

private struct AppleMusicRawSong: Decodable {
  var id: String
  var type: String
  var attributes: Attributes?
  var relationships: Relationships?

  var typedId: Music.TrackId { .init(rawValue: self.id) }

  var artistIds: [Music.ArtistId] {
    self.relationships?.artists?.data
      .filter { $0.type == "artists" }
      .map { Music.ArtistId(rawValue: $0.id) } ?? []
  }

  var albumIds: [Music.AlbumId] {
    self.relationships?.albums?.data
      .filter { $0.type == "albums" }
      .map { Music.AlbumId(rawValue: $0.id) } ?? []
  }

  struct Attributes: Decodable {
    var name: String
    var artistName: String
    var albumName: String?
    var artwork: Artwork?
    var durationInMillis: Int?
  }

  struct Relationships: Decodable {
    var albums: AppleMusicReferencePage?
    var artists: AppleMusicReferencePage?
  }

  func resolvedTrack(album: Music.ResolvedAlbum) -> Music.ResolvedTrack {
    let attributes = self.attributes!
    return .init(
      id: self.typedId,
      title: attributes.name,
      artistName: attributes.artistName,
      artistIds: self.artistIds,
      albumId: album.id,
      albumTitle: attributes.albumName ?? album.title,
      artworkUrl: sizedAppleMusicResolutionArtworkUrl(attributes.artwork?.url),
      durationInMillis: attributes.durationInMillis,
    )
  }
}

private struct AppleMusicRawTrackPage: Decodable {
  var data: [AppleMusicRawTrack]
  var next: String?
}

private struct AppleMusicRawTrack: Decodable {
  var id: String
  var type: String
  var attributes: AppleMusicRawSong.Attributes?

  var typedId: Music.TrackId { .init(rawValue: self.id) }
}

private struct Artwork: Decodable {
  var url: String?
  var width: Int?
  var height: Int?
  var bgColor: String?
  var textColor1: String?
  var textColor2: String?
  var textColor3: String?
  var textColor4: String?

  var catalogArtwork: Music.Artwork {
    .init(
      url: self.url,
      width: self.width,
      height: self.height,
      bgColor: self.bgColor,
      textColor1: self.textColor1,
      textColor2: self.textColor2,
      textColor3: self.textColor3,
      textColor4: self.textColor4,
    )
  }
}

private struct EditorialNotes: Decodable {
  var tagline: String?
  var short: String?
  var standard: String?
  var name: String?
}

private func sizedAppleMusicResolutionArtworkUrl(_ url: String?) -> String? {
  url?
    .replacingOccurrences(of: "{w}", with: "600")
    .replacingOccurrences(of: "{h}", with: "600")
}

extension AppleMusicClient {
  static func testResolvedAlbum(
    _ albumId: Music.AlbumId,
  ) throws -> Music.ResolvedAlbum {
    let title: String
    let artworkUrl: String
    let trackCount: Int
    switch albumId.rawValue {
    case "1440935467":
      title = "Stories from the Outside"
      artworkUrl = "https://example.com/stories.jpg"
      trackCount = 12
    case "1733742320":
      title = "Elements"
      artworkUrl = "https://example.com/elements.jpg"
      trackCount = 6
    default:
      return try self.mockResolvedAlbum(albumId)
    }
    return .init(
      id: albumId,
      title: title,
      artistName: "Lena Jonsson Trio",
      artistIds: ["123456789"],
      artworkUrl: artworkUrl,
      artwork: .init(
        url: artworkUrl,
        width: 1200,
        height: 1200,
        bgColor: "102030",
        textColor1: "ffffff",
        textColor2: "eeeeee",
        textColor3: "dddddd",
        textColor4: "cccccc",
      ),
      trackCount: trackCount,
      releaseType: "Album",
      tracks: [
        .init(
          id: .init(rawValue: "\(albumId.rawValue)-track"),
          title: "Track",
          artistName: "Lena Jonsson Trio",
          artistIds: ["123456789"],
          albumId: albumId,
          albumTitle: title,
        ),
      ],
    )
  }

  static func testResolvedArtist(
    _ artistId: Music.ArtistId,
  ) throws -> Music.ResolvedArtist {
    let name: String
    let tagline: String
    switch artistId.rawValue {
    case "123456789":
      name = "Lena Jonsson Trio"
      tagline = "Swedish folk trio"
    case "555555555":
      name = "Väsen"
      tagline = "Strings and grooves"
    default:
      return try self.mockResolvedArtist(artistId)
    }
    return .init(
      id: artistId,
      name: name,
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
          tagline: tagline,
          short: "Modern fiddle music.",
          standard: "A longer <b>Apple Music</b> artist note.",
          name: "Apple Music Folk",
        ),
        appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
        genreNames: ["Folk", "Worldwide"],
      ),
      topSongs: [],
      albums: [],
    )
  }

  static func mockResolvedAlbum(
    _ albumId: Music.AlbumId,
  ) throws -> Music.ResolvedAlbum {
    guard let album = self.mockAlbums.first(where: { $0.id == albumId }) else {
      throw AppleMusicResolutionError.missingResource(type: "album", id: albumId.rawValue)
    }
    return .init(
      id: album.id,
      title: album.title,
      artistName: album.artistName,
      artistIds: self.mockArtists
        .filter { $0.name == album.artistName }
        .map(\.id),
      artworkUrl: album.artworkUrl,
      artwork: album.artwork,
      trackCount: album.trackCount,
      releaseDate: album.releaseDate,
      releaseType: album.releaseType,
      tracks: (self.mockTracksByAlbum[albumId.rawValue] ?? []).map { track in
        .init(
          id: track.id,
          title: track.title,
          artistName: track.artistName,
          artistIds: [],
          albumId: album.id,
          albumTitle: track.albumTitle ?? album.title,
          artworkUrl: track.artworkUrl,
          durationInMillis: track.durationInMillis,
        )
      },
    )
  }

  static func mockResolvedArtist(
    _ artistId: Music.ArtistId,
  ) throws -> Music.ResolvedArtist {
    guard let artist = self.mockArtists.first(where: { $0.id == artistId }) else {
      throw AppleMusicResolutionError.missingResource(type: "artist", id: artistId.rawValue)
    }
    let albums = try self.mockAlbums
      .filter { $0.artistName == artist.name }
      .map { try self.mockResolvedAlbum($0.id) }
    return .init(
      id: artist.id,
      name: artist.name,
      catalogMetadata: artist.catalogMetadata,
      topSongs: Array(albums.flatMap(\.tracks).prefix(12)),
      albums: albums,
    )
  }
}
