import PairQL

struct StartAccountFullTrial: Pair {
  static let auth: ClientAuth = .parent
}

extension StartAccountFullTrial: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    _ = try await StartFullTrial.resolve(in: context.legacyContext)
    return .success
  }
}
