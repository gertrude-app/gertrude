import DuetSQL
import PairQL

struct ApproveMusicArtist: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicArtistId: Music.ArtistId
    var name: String
    var catalogMetadata: Music.CatalogMetadata?
  }
}

extension ApproveMusicArtist: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    try await context.db.upsert(
      Music.ApprovedArtist(
        childId: child.id,
        appleMusicArtistId: input.appleMusicArtistId,
        name: input.name,
        catalogMetadata: input.catalogMetadata,
      ),
      conflictOn: [.childId, .appleMusicArtistId],
      do: .update(set: [.name, .catalogMetadata]),
    )
    return .success
  }
}
