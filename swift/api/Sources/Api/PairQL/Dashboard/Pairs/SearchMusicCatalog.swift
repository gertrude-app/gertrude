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
      var artwork: Music.Artwork?
      var trackCount: Int?
      var releaseDate: String?
      var appleMusicUrl: String?
    }

    struct Artist: PairNestable {
      var id: Music.ArtistId
      var name: String
      var catalogMetadata: Music.CatalogMetadata?
    }

    struct Item: PairNestable {
      enum Kind: String, PairNestable {
        case album
        case artist
      }

      var kind: Kind
      var album: Album?
      var artist: Artist?
    }

    var items: [Item]
    var albums: [Album]
    var artists: [Artist]
  }
}

extension SearchMusicCatalog: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let account = try await context.currentBillingAccount()
    try requireGertrudeMusicAccess(in: context, billing: account)

    let query = input.query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      return .init(items: [], albums: [], artists: [])
    }

    let limit = min(max(input.limit ?? 10, 1), 25)
    let results = try await get(dependency: \.appleMusic).searchCatalog(
      .init(term: query, limit: limit),
    )

    return .init(
      items: results.items.compactMap(Self.outputItem(from:)),
      albums: results.albums.map(Self.outputAlbum(from:)),
      artists: results.artists.map(Self.outputArtist(from:)),
    )
  }

  private static func outputItem(from item: AppleMusicCatalogSearchItem) -> Output.Item? {
    switch item.kind {
    case .album:
      item.album.map { .init(kind: .album, album: Self.outputAlbum(from: $0), artist: nil) }
    case .artist:
      item.artist.map { .init(kind: .artist, album: nil, artist: Self.outputArtist(from: $0)) }
    case .track:
      nil
    }
  }

  private static func outputAlbum(from album: AppleMusicCatalogAlbum) -> Output.Album {
    .init(
      id: album.id,
      title: album.title,
      artistName: album.artistName,
      artworkUrl: album.artworkUrl,
      artwork: album.artwork,
      trackCount: album.trackCount,
      releaseDate: album.releaseDate,
      appleMusicUrl: album.appleMusicUrl,
    )
  }

  private static func outputArtist(from artist: AppleMusicCatalogArtist) -> Output.Artist {
    .init(id: artist.id, name: artist.name, catalogMetadata: artist.catalogMetadata)
  }
}
