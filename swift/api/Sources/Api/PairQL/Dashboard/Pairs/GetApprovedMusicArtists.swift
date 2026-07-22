import DuetSQL
import PairQL

struct GetApprovedMusicArtists: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = Child.Id

  struct Output: PairOutput {
    struct Artist: PairNestable {
      var id: Music.ArtistId
      var name: String
      var catalogMetadata: Music.CatalogMetadata?
      var createdAt: Date?
    }

    var artists: [Artist]
  }
}

extension GetApprovedMusicArtists: Resolver {
  static func resolve(with childId: Child.Id, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: childId)
    let artists = try await child.approvedMusicArtists(in: context.db)
    return .init(artists: artists.map {
      .init(
        id: $0.appleMusicArtistId,
        name: $0.name,
        catalogMetadata: $0.catalogMetadata,
        createdAt: $0.createdAt,
      )
    })
  }
}
