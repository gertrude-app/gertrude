import PairQL

struct HandleAccountCheckoutCancel: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = HandleCheckoutCancel.Input
}

extension HandleAccountCheckoutCancel: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await HandleCheckoutCancel.resolve(with: input, in: context.legacyContext)
  }
}
