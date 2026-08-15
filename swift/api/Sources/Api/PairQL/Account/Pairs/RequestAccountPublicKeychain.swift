import PairQL

struct RequestAccountPublicKeychain: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let searchQuery: String
    let description: String
  }
}

extension RequestAccountPublicKeychain: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await RequestPublicKeychain.resolve(
      with: .init(
        searchQuery: input.searchQuery,
        description: input.description,
      ),
      in: context.legacyContext,
    )
  }
}
