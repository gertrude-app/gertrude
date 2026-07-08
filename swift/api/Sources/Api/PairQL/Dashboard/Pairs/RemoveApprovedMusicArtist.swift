import DuetSQL
import PairQL

struct RemoveApprovedMusicArtist: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
    var appleMusicArtistId: Music.ArtistId
  }
}

extension RemoveApprovedMusicArtist: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    try await Music.ApprovedArtist.query()
      .where(.childId == child.id)
      .where(.appleMusicArtistId == input.appleMusicArtistId.rawValue)
      .delete(in: context.db)
    return .success
  }
}
