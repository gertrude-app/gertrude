import PairQL

struct CreateAccountNotificationMethod: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = Parent.NotificationMethod.Config
  typealias Output = CreatePendingNotificationMethod.Output
}

extension CreateAccountNotificationMethod: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await CreatePendingNotificationMethod.resolve(
      with: input,
      in: context.legacyContext,
    )
  }
}
