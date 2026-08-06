import PairQL

struct GetMusicCuration: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
  }

  typealias Output = MusicCurationOutput
}

extension GetMusicCuration: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChildWithConnectedMusicApp(from: input.childId)
    return try await currentMusicCuration(
      childId: child.id,
      in: context.db,
      context: context,
    )
  }
}
