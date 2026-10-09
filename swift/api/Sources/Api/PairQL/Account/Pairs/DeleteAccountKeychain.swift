import PairQL

struct DeleteAccountKeychain: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let keychainId: Keychain.Id
  }
}

extension DeleteAccountKeychain: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let keychain = try await context.privateKeychain(input.keychainId)
    return try await DeleteEntity_v2.resolve(
      with: .init(id: keychain.id.rawValue, type: .keychain),
      in: context.legacyContext,
    )
  }
}
