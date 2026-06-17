import PairQL

struct SearchMusicCatalog: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var query: String
    var limit: Int?
  }

  struct Output: PairOutput {
    struct Album: PairNestable {
      var id: Music.AlbumId
      var title: String
      var artistName: String
      var artworkUrl: String?
      var trackCount: Int?
      var releaseDate: String?
      var appleMusicUrl: String?
    }

    var albums: [Album]
  }
}

extension SearchMusicCatalog: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let account = try await context.currentBillingAccount()
    try requireGertrudeMusicAccess(in: context, billing: account)

    let query = input.query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      return .init(albums: [])
    }

    let albums = try await get(dependency: \.appleMusic).searchAlbums(
      .init(
        term: query,
        storefront: "us",
        limit: min(max(input.limit ?? 10, 1), 25),
      ))

    return .init(
      albums: albums.map {
        .init(
          id: $0.id,
          title: $0.title,
          artistName: $0.artistName,
          artworkUrl: $0.artworkUrl,
          trackCount: $0.trackCount,
          releaseDate: $0.releaseDate,
          appleMusicUrl: $0.appleMusicUrl,
        )
      })
  }
}
