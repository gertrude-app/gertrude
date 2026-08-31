import PairQL

struct StartAccountCheckout: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let tier: StripeSubscription.Tier
    let successPath: String
    let cancelPath: String
  }

  typealias Output = StartCheckoutSession.Output
}

extension StartAccountCheckout: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await StartCheckoutSession.resolve(
      with: .init(
        tier: input.tier,
        successPath: input.successPath,
        cancelPath: input.cancelPath,
        associatedIosDeviceId: nil,
      ),
      in: context.legacyContext,
    )
  }
}
