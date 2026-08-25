import PairQL

struct ConfirmAccountNotificationMethod: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = ConfirmPendingNotificationMethod.Input
}

extension ConfirmAccountNotificationMethod: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await ConfirmPendingNotificationMethod.resolve(
      with: input,
      in: context.legacyContext,
    )
  }
}
