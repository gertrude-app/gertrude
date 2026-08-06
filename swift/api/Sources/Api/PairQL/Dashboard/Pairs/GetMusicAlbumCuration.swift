import Dependencies
import PairQL

struct GetMusicAlbumCuration: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicAlbumId: Music.AlbumId
  }

  typealias Output = MusicAlbumCuration
}

extension GetMusicAlbumCuration: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    let album = try await get(dependency: \.appleMusic).resolveAlbum(
      input.appleMusicAlbumId,
    )
    let policy = try await Music.CatalogPolicy.load(childId: child.id, in: context.db)
    let revision = try await musicCurationRevision(
      childId: child.id,
      policy: policy,
      in: context.db,
      context: context,
    )
    return policy.albumCuration(album: album, revision: revision)
  }
}
