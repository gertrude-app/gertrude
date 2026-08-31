import PairQL

struct HandleAccountCheckoutSuccess: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = HandleCheckoutSuccess.Input
}

extension HandleAccountCheckoutSuccess: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await HandleCheckoutSuccess.resolve(with: input, in: context.legacyContext)
  }
}
