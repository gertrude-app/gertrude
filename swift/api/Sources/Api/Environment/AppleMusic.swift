import Dependencies
import Foundation

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
  static let liveValue = Self.mock
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
