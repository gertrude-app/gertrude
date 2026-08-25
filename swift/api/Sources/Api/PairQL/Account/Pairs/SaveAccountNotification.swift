import PairQL

struct SaveAccountNotification: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = SaveNotification.Input
}

extension SaveAccountNotification: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await SaveNotification.resolve(with: input, in: context.legacyContext)
  }
}
