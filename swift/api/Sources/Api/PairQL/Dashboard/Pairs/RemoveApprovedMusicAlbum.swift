import DuetSQL
import PairQL

struct RemoveApprovedMusicAlbum: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicAlbumId: Music.AlbumId
  }
}

extension RemoveApprovedMusicAlbum: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await verifiedChildWithConnectedMusicApp(from: input.childId, in: context)
    try await Music.ApprovedAlbum.query()
      .where(.childId == child.id)
      .where(.appleMusicAlbumId == input.appleMusicAlbumId.rawValue)
      .delete(in: context.db)
    return .success
  }
}
