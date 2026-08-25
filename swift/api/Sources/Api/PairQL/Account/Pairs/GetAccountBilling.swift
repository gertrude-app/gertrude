import PairQL

struct GetAccountBilling: Pair {
  static let auth: ClientAuth = .parent
  typealias Output = GetSubscriptionPanel_v2.Output
}

extension GetAccountBilling: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    try await GetSubscriptionPanel_v2.resolve(in: context.legacyContext)
  }
}
