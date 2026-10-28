import PairQL

struct DisconnectMacConnection: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let connectionId: ComputerUser.Id
  }
}

extension DisconnectMacConnection: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await DeleteEntity_v2.resolve(
      with: .init(id: input.connectionId.rawValue, type: .computerUser),
      in: context.legacyContext,
    )
  }
}
