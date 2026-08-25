import PairQL

struct DeleteAccountNotificationMethod: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let id: Parent.NotificationMethod.Id
  }
}

extension DeleteAccountNotificationMethod: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await DeleteEntity_v2.resolve(
      with: .init(id: input.id.rawValue, type: .parentVerifiedNotificationMethod),
      in: context.legacyContext,
    )
  }
}
