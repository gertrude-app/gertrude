import PairQL

struct ChangeAccountSubscriptionTier: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let tier: StripeSubscription.Tier
  }
}

extension ChangeAccountSubscriptionTier: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await ChangeSubscriptionTier.resolve(
      with: .init(to: input.tier),
      in: context.legacyContext,
    )
  }
}
