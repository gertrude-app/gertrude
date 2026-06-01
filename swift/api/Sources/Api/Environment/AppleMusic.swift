import Dependencies
import Foundation
import JWT
import XHttp

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct AppleMusicClient: Sendable {
  var searchAlbums:
    @Sendable (_ search: AppleMusicAlbumSearch) async throws -> [AppleMusicCatalogAlbum]
}

struct AppleMusicAlbumSearch: Equatable, Sendable {
  var term: String
  var storefront: String
  var limit: Int

  init(
    term: String,
    storefront: String = "us",
    limit: Int = 10,
  ) {
    self.term = term
    self.storefront = storefront
    self.limit = limit
  }
}

struct AppleMusicCatalogAlbum: Codable, Equatable, Sendable {
  var id: Music.AlbumId
  var title: String
  var artistName: String
  var artworkUrl: String?
  var trackCount: Int?
  var releaseDate: String?
  var appleMusicUrl: String?

  init(
    id: Music.AlbumId,
    title: String,
    artistName: String,
    artworkUrl: String? = nil,
    trackCount: Int? = nil,
    releaseDate: String? = nil,
    appleMusicUrl: String? = nil,
  ) {
    self.id = id
    self.title = title
    self.artistName = artistName
    self.artworkUrl = artworkUrl
    self.trackCount = trackCount
    self.releaseDate = releaseDate
    self.appleMusicUrl = appleMusicUrl
  }
}

extension AppleMusicClient: DependencyKey {
  static var liveValue: Self {
    Self(searchAlbums: { search in
      let token = try await generateAppleMusicDeveloperToken()
      return try await searchAppleMusicCatalogAlbums(search, developerToken: token)
    })
  }
}

extension AppleMusicClient: TestDependencyKey {
  static let testValue = Self(
    searchAlbums: unimplemented("AppleMusicClient.searchAlbums()", placeholder: []),
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

func searchAppleMusicCatalogAlbums(
  _ search: AppleMusicAlbumSearch,
  developerToken: String,
) async throws -> [AppleMusicCatalogAlbum] {
  let url = try appleMusicCatalogSearchURL(search)
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

  return try decodeAppleMusicCatalogAlbums(from: data)
}

func appleMusicCatalogSearchURL(_ search: AppleMusicAlbumSearch) throws -> URL {
  var components = URLComponents()
  components.scheme = "https"
  components.host = "api.music.apple.com"
  components.path = "/v1/catalog/\(search.storefront)/search"
  components.queryItems = [
    .init(name: "term", value: search.term),
    .init(name: "types", value: "albums"),
    .init(name: "limit", value: String(search.limit)),
  ]
  guard let url = components.url else {
    throw AppleMusicError.invalidSearchUrl
  }
  return url
}

func decodeAppleMusicCatalogAlbums(from data: Data) throws -> [AppleMusicCatalogAlbum] {
  let response = try JSONDecoder().decode(AppleMusicCatalogSearchResponse.self, from: data)
  return response.results?.albums?.data.map { album in
    .init(
      id: .init(rawValue: album.id),
      title: album.attributes.name,
      artistName: album.attributes.artistName,
      artworkUrl: sizedAppleMusicArtworkUrl(album.attributes.artwork?.url),
      trackCount: album.attributes.trackCount,
      releaseDate: album.attributes.releaseDate,
      appleMusicUrl: album.attributes.url,
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

  struct Results: Decodable {
    var albums: AlbumCollection?
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
    var url: String?
  }

  struct Artwork: Decodable {
    var url: String?
  }
}

enum AppleMusicError: Error, CustomStringConvertible {
  case missingEnv(String)
  case invalidSearchUrl
  case invalidResponseType
  case httpError(statusCode: Int, body: String)

  var description: String {
    switch self {
    case .missingEnv(let key):
      "Missing required environment variable: `\(key)`"
    case .invalidSearchUrl:
      "Invalid Apple Music search URL"
    case .invalidResponseType:
      "Invalid Apple Music response type"
    case .httpError(let statusCode, let body):
      "Apple Music error (status \(statusCode)): \(body)"
    }
  }
}

extension AppleMusicClient {
  static let mock = Self(searchAlbums: { search in
    let term = search.term.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let albums =
      term.isEmpty
        ? Self.mockAlbums
        : Self.mockAlbums.filter {
          $0.title.lowercased().contains(term) || $0.artistName.lowercased().contains(term)
        }
    return Array(albums.prefix(max(0, search.limit)))
  })

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
}
