import PairQL

struct OpenAccountBillingPortal: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = OpenBillingPortal.Input
  typealias Output = OpenBillingPortal.Output
}

extension OpenAccountBillingPortal: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await OpenBillingPortal.resolve(with: input, in: context.legacyContext)
  }
}
