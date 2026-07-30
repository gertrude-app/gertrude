import PairQL

struct DeletePerson: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
  }
}

extension DeletePerson: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await DeleteEntity_v2.resolve(
      with: .init(id: input.personId.rawValue, type: .child),
      in: context.legacyContext,
    )
  }
}
