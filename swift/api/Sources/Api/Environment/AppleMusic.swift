import Dependencies
import Foundation
import JWT
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct AppleMusicClient: Sendable {
  var searchCatalog:
    @Sendable (_ search: AppleMusicCatalogSearch) async throws -> AppleMusicCatalogSearchResults
  var albumTracks:
    @Sendable (_ lookup: AppleMusicAlbumTracksLookup) async throws -> [AppleMusicCatalogTrack]
  var resolveAlbum:
    @Sendable (_ albumId: Music.AlbumId) async throws -> Music.ResolvedAlbum
  var resolveTrack:
    @Sendable (_ lookup: AppleMusicTrackResolutionLookup) async throws -> AppleMusicTrackResolution
  var resolveArtist:
    @Sendable (_ artistId: Music.ArtistId) async throws -> Music.ResolvedArtist
}

struct AppleMusicCatalogSearch: Equatable, Sendable {
  var term: String
  var limit: Int

  init(term: String, limit: Int = 10) {
    self.term = term
    self.limit = limit
  }
}

struct AppleMusicAlbumTracksLookup: Equatable, Sendable {
  var albumId: Music.AlbumId
}

struct AppleMusicTrackResolutionLookup: Equatable, Sendable {
  var trackId: Music.TrackId
  var preferredAlbumId: Music.AlbumId
}

struct AppleMusicTrackResolution: Equatable, Sendable {
  var grant: Music.ResolvedTrackGrant
  var album: Music.ResolvedAlbum
}

struct AppleMusicCatalogAlbum: Codable, Equatable, Sendable {
  var id: Music.AlbumId
  var title: String
  var artistName: String
  var artworkUrl: String?
  var artwork: Music.Artwork?
  var trackCount: Int?
  var releaseDate: String?
  var releaseType: String?
  var appleMusicUrl: String?

  init(
    id: Music.AlbumId,
    title: String,
    artistName: String,
    artworkUrl: String? = nil,
    artwork: Music.Artwork? = nil,
    trackCount: Int? = nil,
    releaseDate: String? = nil,
    releaseType: String? = nil,
    appleMusicUrl: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkUrl = artworkUrl
    self.artwork = artwork
    self.trackCount = trackCount
    self.releaseDate = releaseDate
    self.releaseType = releaseType
    self.appleMusicUrl = appleMusicUrl
  }
}

struct AppleMusicCatalogArtist: Codable, Equatable, Sendable {
  var id: Music.ArtistId
  var name: String
  var catalogMetadata: Music.CatalogMetadata?

  init(
    id: Music.ArtistId,
    name: String,
    catalogMetadata: Music.CatalogMetadata? = nil,
  ) {
    self.id = id
    self.name = name
    self.catalogMetadata = catalogMetadata
  }
}

struct AppleMusicCatalogSearchTrack: Codable, Equatable, Sendable {
  var id: Music.TrackId
  var title: String
  var artistName: String
  var artistIds: [Music.ArtistId]
  var preferredAlbumId: Music.AlbumId
  var albumTitle: String
  var artworkUrl: String?
  var artwork: Music.Artwork?
  var durationInMillis: Int?
  var discNumber: Int?
  var trackNumber: Int?
  var contentRating: Music.ContentRating?
  var appleMusicUrl: String?

  init(
    id: Music.TrackId,
    title: String,
    artistName: String,
    artistIds: [Music.ArtistId],
    preferredAlbumId: Music.AlbumId,
    albumTitle: String,
    artworkUrl: String? = nil,
    artwork: Music.Artwork? = nil,
    durationInMillis: Int? = nil,
    discNumber: Int? = nil,
    trackNumber: Int? = nil,
    contentRating: Music.ContentRating? = nil,
    appleMusicUrl: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artistIds = artistIds
    self.preferredAlbumId = preferredAlbumId
    self.albumTitle = albumTitle
    self.artworkUrl = artworkUrl
    self.artwork = artwork
    self.durationInMillis = durationInMillis
    self.discNumber = discNumber
    self.trackNumber = trackNumber
    self.contentRating = contentRating
    self.appleMusicUrl = appleMusicUrl
  }
}

struct AppleMusicCatalogSearchResults: Codable, Equatable, Sendable {
  var items: [AppleMusicCatalogSearchItem]
  var albums: [AppleMusicCatalogAlbum]
  var artists: [AppleMusicCatalogArtist]
  var tracks: [AppleMusicCatalogSearchTrack]

  init(
    items: [AppleMusicCatalogSearchItem],
    albums: [AppleMusicCatalogAlbum],
    artists: [AppleMusicCatalogArtist],
    tracks: [AppleMusicCatalogSearchTrack] = [],
  ) {
    self.items = items
    self.albums = albums
    self.artists = artists
    self.tracks = tracks
  }
}

struct AppleMusicCatalogSearchItem: Codable, Equatable, Sendable {
  enum Kind: String, Codable, Sendable {
    case album
    case artist
    case track
  }

  var kind: Kind
  var album: AppleMusicCatalogAlbum?
  var artist: AppleMusicCatalogArtist?
  var track: AppleMusicCatalogSearchTrack?

  init(album: AppleMusicCatalogAlbum) {
    self.kind = .album
    self.album = album
    self.artist = nil
    self.track = nil
  }

  init(artist: AppleMusicCatalogArtist) {
    self.kind = .artist
    self.album = nil
    self.artist = artist
    self.track = nil
  }

  init(track: AppleMusicCatalogSearchTrack) {
    self.kind = .track
    self.album = nil
    self.artist = nil
    self.track = track
  }
}

struct AppleMusicCatalogTrack: Codable, Equatable, Sendable {
  var id: Music.TrackId
  var title: String
  var artistName: String
  var albumTitle: String?
  var artworkUrl: String?
  var durationInMillis: Int?

  init(
    id: Music.TrackId,
    title: String,
    artistName: String,
    albumTitle: String? = nil,
    artworkUrl: String? = nil,
    durationInMillis: Int? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.albumTitle = albumTitle
    self.artworkUrl = artworkUrl
    self.durationInMillis = durationInMillis
  }
}

extension AppleMusicClient: DependencyKey {
  static var liveValue: Self {
    Self(
      searchCatalog: { search in
        let token = try await generateAppleMusicDeveloperToken()
        return try await searchAppleMusicCatalog(search, developerToken: token)
      },
      albumTracks: { lookup in
        let token = try await generateAppleMusicDeveloperToken()
        return try await fetchAppleMusicCatalogAlbumTracks(lookup, developerToken: token)
      },
      resolveAlbum: { albumId in
        let token = try await generateAppleMusicDeveloperToken()
        return try await resolveAppleMusicCatalogAlbum(
          albumId,
          load: appleMusicDataLoader(developerToken: token),
        )
      },
      resolveTrack: { lookup in
        let token = try await generateAppleMusicDeveloperToken()
        return try await resolveAppleMusicCatalogTrack(
          lookup,
          load: appleMusicDataLoader(developerToken: token),
        )
      },
      resolveArtist: { artistId in
        let token = try await generateAppleMusicDeveloperToken()
        return try await resolveAppleMusicCatalogArtist(
          artistId,
          load: appleMusicDataLoader(developerToken: token),
        )
      },
    )
  }
}

extension AppleMusicClient: TestDependencyKey {
  static let testValue = Self(
    searchCatalog: unimplemented(
      "AppleMusicClient.searchCatalog()",
      placeholder: .init(items: [], albums: [], artists: []),
    ),
    albumTracks: unimplemented("AppleMusicClient.albumTracks()", placeholder: []),
    resolveAlbum: { try Self.testResolvedAlbum($0) },
    resolveTrack: { try Self.testResolvedTrack($0) },
    resolveArtist: { try Self.testResolvedArtist($0) },
  )
}

extension DependencyValues {
  var appleMusic: AppleMusicClient {
    get { self[AppleMusicClient.self] }
    set { self[AppleMusicClient.self] = newValue }
  }
}

func generateAppleMusicDeveloperToken(now: Date = Date()) async throws -> String {
  let keyId = try musicKitEnv("MUSICKIT_KEY_ID")
  let teamId = try musicKitEnv("MUSICKIT_TEAM_ID")
  let privateKeyPEM = try musicKitEnv("MUSICKIT_PRIVATE_KEY")
    .replacingOccurrences(of: "\\n", with: "\n")

  let payload = AppleMusicDeveloperTokenPayload(
    iss: .init(value: teamId),
    iat: .init(value: now),
    exp: .init(value: now.addingTimeInterval(6 * 60 * 60)),
  )

  let key = try ES256PrivateKey(pem: privateKeyPEM)
  let keyCollection = JWTKeyCollection()
  await keyCollection.add(ecdsa: key, kid: .init(string: keyId))
  return try await keyCollection.sign(payload, kid: .init(string: keyId))
}

private func musicKitEnv(_ key: String) throws -> String {
  guard let value = get(dependency: \.env).get(key), !value.isEmpty else {
    throw AppleMusicError.missingEnv(key)
  }
  return value
}

private struct AppleMusicDeveloperTokenPayload: JWTPayload {
  var iss: IssuerClaim
  var iat: IssuedAtClaim
  var exp: ExpirationClaim

  func verify(using _: some JWTAlgorithm) throws {
    try self.exp.verifyNotExpired()
  }
}

func searchAppleMusicCatalog(
  _ search: AppleMusicCatalogSearch,
  developerToken: String,
) async throws -> AppleMusicCatalogSearchResults {
  try await searchAppleMusicCatalog(
    search,
    load: appleMusicDataLoader(developerToken: developerToken),
  )
}

func appleMusicCatalogMixedSearchURL(_ search: AppleMusicCatalogSearch) throws -> URL {
  try appleMusicCatalogSearchURL(
    term: search.term,
    limit: search.limit,
    types: ["songs", "albums", "artists"],
    with: ["topResults"],
  )
}

private func appleMusicCatalogSearchURL(
  term: String,
  limit: Int,
  types: [String],
  with: [String] = [],
) throws -> URL {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.music.apple.com"
  components.path = "/v1/catalog/us/search"
  components.queryItems = [
    .init(name: "term", value: term),
    .init(name: "types", value: types.joined(separator: ",")),
    .init(name: "limit", value: String(limit)),
  ]
  if !with.isEmpty {
    components.queryItems?.append(.init(name: "with", value: with.joined(separator: ",")))
  }
  guard let url = components.url else {
    throw AppleMusicError.invalidSearchUrl
  }
  return url
}

func appleMusicCatalogURL(fromNext next: String) throws -> URL {
  guard var components = URLComponents(string: next) else {
    throw AppleMusicError.invalidCatalogPaginationUrl
  }
  if let scheme = components.scheme, scheme.lowercased() != "https" {
    throw AppleMusicError.invalidCatalogPaginationUrl
  }
  if let host = components.host, host.lowercased() != "api.music.apple.com" {
    throw AppleMusicError.invalidCatalogPaginationUrl
  }
  guard components.user == nil, components.password == nil, components.port == nil else {
    throw AppleMusicError.invalidCatalogPaginationUrl
  }
  components.scheme = "https"
  components.host = "api.music.apple.com"
  if !components.path.hasPrefix("/") {
    components.path = "/" + components.path
  }
  guard let url = components.url else {
    throw AppleMusicError.invalidCatalogPaginationUrl
  }
  return url
}

func fetchAppleMusicCatalogAlbumTracks(
  _ lookup: AppleMusicAlbumTracksLookup,
  developerToken: String,
) async throws -> [AppleMusicCatalogTrack] {
  let url = try appleMusicCatalogAlbumURL(lookup)
  var request = URLRequest(url: url)
  request.httpMethod = "GET"
  request.setValue("Bearer \(developerToken)", forHTTPHeaderField: "Authorization")
  request.setValue("application/json", forHTTPHeaderField: "Accept")

  let (data, response) = try await XHttp.data(for: request)
  guard let httpResponse = response as? HTTPURLResponse else {
    throw AppleMusicError.invalidResponseType
  }
  guard (200 ... 299).contains(httpResponse.statusCode) else {
    throw AppleMusicError.httpError(
      statusCode: httpResponse.statusCode,
      body: String(data: data, encoding: .utf8) ?? "<decode err>",
    )
  }

  return try decodeAppleMusicCatalogAlbumTracks(from: data)
}

func appleMusicCatalogAlbumURL(_ lookup: AppleMusicAlbumTracksLookup) throws -> URL {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.music.apple.com"
  components.path = "/v1/catalog/us/albums/\(lookup.albumId.rawValue)"
  components.queryItems = [
    .init(name: "include", value: "tracks"),
  ]
  guard let url = components.url else {
    throw AppleMusicError.invalidAlbumUrl
  }
  return url
}

func decodeAppleMusicCatalogSearchResults(
  from data: Data,
) throws -> AppleMusicCatalogSearchResults {
  let response = try JSONDecoder().decode(AppleMusicCatalogSearchResponse.self, from: data)
  return catalogSearchResults(
    from: response,
    tracks: [],
    defaultOrder: ["artists", "albums"],
  )
}

func searchAppleMusicCatalog(
  _ search: AppleMusicCatalogSearch,
  load: AppleMusicDataLoader,
) async throws -> AppleMusicCatalogSearchResults {
  let url = try appleMusicCatalogMixedSearchURL(search)
  let data = try await load(url)
  let response = try JSONDecoder().decode(AppleMusicCatalogSearchResponse.self, from: data)
  let hydratedSongs = try await hydratedAppleMusicCatalogSongsForSearch(
    catalogSearchSongIds(from: response),
    load: load,
  )
  return catalogSearchResults(
    from: response,
    tracks: hydratedSongs.compactMap(catalogSearchTrack(from:)),
    defaultOrder: ["songs", "albums", "artists"],
  )
}

private func catalogSearchResults(
  from response: AppleMusicCatalogSearchResponse,
  tracks: [AppleMusicCatalogSearchTrack],
  defaultOrder: [String],
) -> AppleMusicCatalogSearchResults {
  let albums = response.results?.albums?.data.map(catalogAlbum(from:)) ?? []
  let artists = response.results?.artists?.data.map(catalogArtist(from:)) ?? []
  let tracksById = Dictionary(uniqueKeysWithValues: tracks.map { ($0.id, $0) })
  let topItems = response.results?.topResults?.data.compactMap {
    catalogSearchItem(from: $0, tracksById: tracksById)
  } ?? []
  return .init(
    items: topItems.isEmpty
      ? fallbackCatalogSearchItems(
        albums: albums,
        artists: artists,
        tracks: tracks,
        order: response.meta?.results.order,
        defaultOrder: defaultOrder,
      )
      : topItems,
    albums: albums,
    artists: artists,
    tracks: tracks,
  )
}

private func catalogSearchSongIds(
  from response: AppleMusicCatalogSearchResponse,
) -> [Music.TrackId] {
  let collectionSongs = response.results?.songs?.data ?? []
  let topSongs = response.results?.topResults?.data.compactMap(\.song) ?? []
  var seen = Set<Music.TrackId>()
  return (collectionSongs + topSongs).compactMap { song in
    let id = Music.TrackId(rawValue: song.id)
    guard song.type == "songs", seen.insert(id).inserted else { return nil }
    return id
  }
}

private func catalogSearchTrack(
  from song: AppleMusicHydratedCatalogSong,
) -> AppleMusicCatalogSearchTrack? {
  guard
    let preferredAlbumId = preferredAppleMusicAlbumId(
      among: song.albumIds,
      appleMusicUrl: song.appleMusicUrl,
    ),
    let albumTitle = song.albumTitle,
    !albumTitle.isEmpty
  else {
    return nil
  }
  return .init(
    id: song.id,
    title: song.title,
    artistName: song.artistName,
    artistIds: song.artistIds,
    preferredAlbumId: preferredAlbumId,
    albumTitle: albumTitle,
    artworkUrl: song.artworkUrl,
    artwork: song.artwork,
    durationInMillis: song.durationInMillis,
    discNumber: song.discNumber,
    trackNumber: song.trackNumber,
    contentRating: song.contentRating,
    appleMusicUrl: song.appleMusicUrl,
  )
}

func preferredAppleMusicAlbumId(
  among albumIds: [Music.AlbumId],
  appleMusicUrl: String?,
) -> Music.AlbumId? {
  var seen = Set<Music.AlbumId>()
  let relatedAlbumIds = albumIds.filter {
    !$0.rawValue.isEmpty && seen.insert($0).inserted
  }
  guard !relatedAlbumIds.isEmpty else { return nil }
  if
    let appleMusicUrl,
    let components = URLComponents(string: appleMusicUrl),
    components.scheme?.lowercased() == "https",
    components.host?.lowercased() == "music.apple.com",
    components.path.split(separator: "/").contains("album"),
    let rawAlbumId = components.path.split(separator: "/").last,
    let officialAlbumId = relatedAlbumIds.first(where: {
      $0.rawValue == String(rawAlbumId)
    }) {
    return officialAlbumId
  }
  return relatedAlbumIds.min { $0.rawValue < $1.rawValue }
}

private func catalogAlbum(
  from album: AppleMusicCatalogSearchResponse.Album,
) -> AppleMusicCatalogAlbum {
  .init(
    id: .init(rawValue: album.id),
    title: album.attributes.name,
    artistName: album.attributes.artistName,
    artworkUrl: sizedAppleMusicArtworkUrl(album.attributes.artwork?.url),
    artwork: album.attributes.artwork.map(catalogArtwork(from:)),
    trackCount: album.attributes.trackCount,
    releaseDate: album.attributes.releaseDate,
    releaseType: album.attributes.releaseType,
    appleMusicUrl: album.attributes.url,
  )
}

private func catalogArtist(
  from artist: AppleMusicCatalogSearchResponse.Artist,
) -> AppleMusicCatalogArtist {
  .init(
    id: .init(rawValue: artist.id),
    name: artist.attributes.name,
    catalogMetadata: catalogMetadata(from: artist.attributes),
  )
}

private func catalogSearchItem(
  from topResult: AppleMusicCatalogSearchResponse.TopResult,
  tracksById: [Music.TrackId: AppleMusicCatalogSearchTrack],
) -> AppleMusicCatalogSearchItem? {
  if let album = topResult.album {
    .init(album: catalogAlbum(from: album))
  } else if let artist = topResult.artist {
    .init(artist: catalogArtist(from: artist))
  } else if let song = topResult.song,
            let track = tracksById[Music.TrackId(rawValue: song.id)] {
    .init(track: track)
  } else {
    nil
  }
}

private func fallbackCatalogSearchItems(
  albums: [AppleMusicCatalogAlbum],
  artists: [AppleMusicCatalogArtist],
  tracks: [AppleMusicCatalogSearchTrack],
  order: [String]?,
  defaultOrder: [String],
) -> [AppleMusicCatalogSearchItem] {
  let orderedKinds = order ?? defaultOrder
  var items: [AppleMusicCatalogSearchItem] = []
  for kind in orderedKinds {
    switch kind {
    case "albums":
      items.append(contentsOf: albums.map(AppleMusicCatalogSearchItem.init(album:)))
    case "artists":
      items.append(contentsOf: artists.map(AppleMusicCatalogSearchItem.init(artist:)))
    case "songs":
      items.append(contentsOf: tracks.map(AppleMusicCatalogSearchItem.init(track:)))
    default:
      break
    }
  }
  return items.isEmpty
    ? tracks.map(AppleMusicCatalogSearchItem.init(track:))
    + albums.map(AppleMusicCatalogSearchItem.init(album:))
    + artists.map(AppleMusicCatalogSearchItem.init(artist:))
    : items
}

private func catalogMetadata(
  from attributes: AppleMusicCatalogSearchResponse.ArtistAttributes,
) -> Music.CatalogMetadata {
  .init(
    artwork: attributes.artwork.map(catalogArtwork(from:)),
    editorialNotes: attributes.editorialNotes.map {
      .init(tagline: $0.tagline, short: $0.short, standard: $0.standard, name: $0.name)
    },
    appleMusicUrl: attributes.url,
    genreNames: attributes.genreNames ?? [],
  )
}

private func catalogArtwork(
  from artwork: AppleMusicCatalogSearchResponse.Artwork,
) -> Music.Artwork {
  .init(
    url: artwork.url,
    width: artwork.width,
    height: artwork.height,
    bgColor: artwork.bgColor,
    textColor1: artwork.textColor1,
    textColor2: artwork.textColor2,
    textColor3: artwork.textColor3,
    textColor4: artwork.textColor4,
  )
}

func decodeAppleMusicCatalogAlbumTracks(from data: Data) throws -> [AppleMusicCatalogTrack] {
  let response = try JSONDecoder().decode(AppleMusicCatalogAlbumResponse.self, from: data)
  guard let album = response.data.first else { return [] }
  return album.relationships?.tracks?.data.compactMap { track in
    guard track.type == "songs", let attributes = track.attributes else { return nil }
    return .init(
      id: .init(rawValue: track.id),
      title: attributes.name,
      artistName: attributes.artistName,
      albumTitle: attributes.albumName,
      artworkUrl: sizedAppleMusicArtworkUrl(attributes.artwork?.url),
      durationInMillis: attributes.durationInMillis,
    )
  } ?? []
}

private func sizedAppleMusicArtworkUrl(_ url: String?) -> String? {
  url?
    .replacingOccurrences(of: "{w}", with: "600")
    .replacingOccurrences(of: "{h}", with: "600")
}

private struct AppleMusicCatalogSearchResponse: Decodable {
  var results: Results?
  var meta: Meta?

  struct Results: Decodable {
    var albums: AlbumCollection?
    var artists: ArtistCollection?
    var songs: SongCollection?
    var topResults: TopResultCollection?
  }

  struct AlbumCollection: Decodable {
    var data: [Album]
  }

  struct Album: Decodable {
    var id: String
    var attributes: Attributes
  }

  struct Attributes: Decodable {
    var name: String
    var artistName: String
    var artwork: Artwork?
    var trackCount: Int?
    var releaseDate: String?
    var isSingle: Bool?
    var url: String?

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

  struct ArtistCollection: Decodable {
    var data: [Artist]
  }

  struct Artist: Decodable {
    var id: String
    var attributes: ArtistAttributes
  }

  struct SongCollection: Decodable {
    var data: [Song]
  }

  struct Song: Decodable {
    var id: String
    var type: String
  }

  struct TopResultCollection: Decodable {
    var data: [TopResult]
  }

  struct TopResult: Decodable {
    var album: Album?
    var artist: Artist?
    var song: Song?

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      self.album = nil
      self.artist = nil
      self.song = nil
      switch type {
      case "albums":
        self.album = try? Album(from: decoder)
      case "artists":
        self.artist = try? Artist(from: decoder)
      case "songs":
        self.song = try? Song(from: decoder)
      default:
        break
      }
    }

    enum CodingKeys: String, CodingKey {
      case type
    }
  }

  struct ArtistAttributes: Decodable {
    var name: String
    var artwork: Artwork?
    var editorialNotes: EditorialNotes?
    var genreNames: [String]?
    var url: String?
  }

  struct Artwork: Decodable {
    var url: String?
    var width: Int?
    var height: Int?
    var bgColor: String?
    var textColor1: String?
    var textColor2: String?
    var textColor3: String?
    var textColor4: String?
  }

  struct EditorialNotes: Decodable {
    var tagline: String?
    var short: String?
    var standard: String?
    var name: String?
  }

  struct Meta: Decodable {
    var results: ResultsMeta
  }

  struct ResultsMeta: Decodable {
    var order: [String]?
  }
}

private struct AppleMusicCatalogAlbumResponse: Decodable {
  var data: [Album]

  struct Album: Decodable {
    var relationships: Relationships?
  }

  struct Relationships: Decodable {
    var tracks: TrackCollection?
  }

  struct TrackCollection: Decodable {
    var data: [Track]
  }

  struct Track: Decodable {
    var id: String
    var type: String
    var attributes: Attributes?
  }

  struct Attributes: Decodable {
    var name: String
    var artistName: String
    var albumName: String?
    var artwork: Artwork?
    var durationInMillis: Int?
  }

  struct Artwork: Decodable {
    var url: String?
  }
}

enum AppleMusicError: Error, CustomStringConvertible {
  case missingEnv(String)
  case invalidSearchUrl
  case invalidCatalogPaginationUrl
  case invalidAlbumUrl
  case invalidResponseType
  case httpError(statusCode: Int, body: String)

  var description: String {
    switch self {
    case .missingEnv(let key):
      "Missing required environment variable: `\(key)`"
    case .invalidSearchUrl:
      "Invalid Apple Music search URL"
    case .invalidCatalogPaginationUrl:
      "Invalid Apple Music catalog pagination URL"
    case .invalidAlbumUrl:
      "Invalid Apple Music album URL"
    case .invalidResponseType:
      "Invalid Apple Music response type"
    case .httpError(let statusCode, let body):
      "Apple Music error (status \(statusCode)): \(body)"
    }
  }
}

extension AppleMusicClient {
  static let mockAlbums: [AppleMusicCatalogAlbum] = [
    .init(
      id: "1511628001",
      title: "Stories from the Outside",
      artistName: "Lena Jonsson Trio",
      artworkUrl:
      "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
      trackCount: 12,
      releaseDate: "2020-05-29",
      appleMusicUrl: "https://music.apple.com/us/album/stories-from-the-outside/1511628001",
    ),
    .init(
      id: "1682152618",
      title: "Elements",
      artistName: "Lena Jonsson Trio",
      artworkUrl:
      "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg",
      trackCount: 12,
      releaseDate: "2023-04-28",
      appleMusicUrl: "https://music.apple.com/us/album/elements/1682152618",
    ),
    .init(
      id: "1641791000",
      title: "Rule of 3",
      artistName: "Väsen",
      artworkUrl:
      "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/98/f3/0c/98f30cf6-2c93-e325-47de-be6a693aad8a/00b970d0-6ad6-4a55-a6d1-9ea83844ee99.jpg/600x600bb.jpg",
      trackCount: 12,
      releaseDate: "2022-09-16",
      appleMusicUrl: "https://music.apple.com/us/album/rule-of-3/1641791000",
    ),
    .init(
      id: "1641851258",
      title: "Brewed",
      artistName: "Väsen",
      artworkUrl:
      "https://is1-ssl.mzstatic.com/image/thumb/Music112/v4/b0/b9/5c/b0b95c7d-732e-dd4c-facc-4132de44d3a4/9ec6d7b8-2049-4a53-92cd-4f19acdd8968.jpg/600x600bb.jpg",
      trackCount: 12,
      releaseDate: "2022-09-16",
      appleMusicUrl: "https://music.apple.com/us/album/brewed/1641851258",
    ),
  ]

  static let mockArtists: [AppleMusicCatalogArtist] = [
    .init(
      id: "123456789",
      name: "Lena Jonsson Trio",
      catalogMetadata: .init(
        artwork: .init(
          url: "https://is1-ssl.mzstatic.com/image/thumb/Features116/v4/artist-lena/{w}x{h}bb.jpg",
          width: 1200,
          height: 1200,
          bgColor: "19160f",
          textColor1: "f3949b",
          textColor2: "b08ff2",
          textColor3: "c77b7f",
          textColor4: "9277c5",
        ),
        editorialNotes: .init(tagline: "Modern Swedish folk"),
        appleMusicUrl: "https://music.apple.com/us/artist/lena-jonsson-trio/123456789",
        genreNames: ["Folk", "Worldwide"],
      ),
    ),
    .init(
      id: "555555555",
      name: "Väsen",
      catalogMetadata: .init(
        artwork: .init(
          url: "https://is1-ssl.mzstatic.com/image/thumb/Features116/v4/artist-vasen/{w}x{h}bb.jpg",
          width: 1200,
          height: 1200,
        ),
        editorialNotes: .init(tagline: "Strings and grooves"),
        appleMusicUrl: "https://music.apple.com/us/artist/vasen/555555555",
        genreNames: ["Folk"],
      ),
    ),
  ]

  static let mockTracksByAlbum: [String: [AppleMusicCatalogTrack]] = [
    "1511628001": [
      .init(
        id: "1511628002",
        title: "Sommarsvärta",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
        artworkUrl:
        "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
      ),
      .init(
        id: "1511628003",
        title: "Snowstorm",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Stories from the Outside",
        artworkUrl:
        "https://is1-ssl.mzstatic.com/image/thumb/Music114/v4/7b/8d/ee/7b8dee33-82f2-ec13-fa92-d5904e9915b8/194152231037.png/600x600bb.jpg",
      ),
    ],
    "1682152618": [
      .init(
        id: "1682152620",
        title: "Elements",
        artistName: "Lena Jonsson Trio",
        albumTitle: "Elements",
        artworkUrl:
        "https://is1-ssl.mzstatic.com/image/thumb/Music116/v4/8d/2a/de/8d2aded7-6ff7-0f92-8005-085449f4586e/cover.jpg/600x600bb.jpg",
      ),
    ],
  ]
}
