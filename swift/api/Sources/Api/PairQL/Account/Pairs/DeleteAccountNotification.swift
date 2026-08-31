import PairQL

struct DeleteAccountNotification: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let id: Parent.Notification.Id
  }
}

extension DeleteAccountNotification: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await DeleteEntity_v2.resolve(
      with: .init(id: input.id.rawValue, type: .parentNotification),
      in: context.legacyContext,
    )
  }
}
