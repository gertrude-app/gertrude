import DuetSQL
import PairQL

struct GetApprovedMusicAlbums: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = Child.Id

  struct Output: PairOutput {
    struct Album: PairNestable {
      var id: Music.AlbumId
      var title: String
      var artistName: String
      var artworkUrl: String?
      var trackCount: Int?
      var showsArtwork: Bool
    }

    var albums: [Album]
  }
}

extension GetApprovedMusicAlbums: Resolver {
  static func resolve(with childId: Child.Id, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: childId)
    let albums = try await child.approvedMusicAlbums(in: context.db)
    return .init(albums: albums.map {
      .init(
        id: $0.appleMusicAlbumId,
        title: $0.title,
        artistName: $0.artistName,
        artworkUrl: $0.artworkUrl,
        trackCount: $0.trackCount,
        showsArtwork: $0.showsArtwork,
      )
    })
  }
}
