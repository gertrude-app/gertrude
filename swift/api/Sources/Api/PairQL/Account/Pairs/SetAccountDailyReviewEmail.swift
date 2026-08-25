import PairQL

struct SetAccountDailyReviewEmail: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = SetDailyReviewEmail.Input
}

extension SetAccountDailyReviewEmail: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await SetDailyReviewEmail.resolve(with: input, in: context.legacyContext)
  }
}
