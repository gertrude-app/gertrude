import DuetSQL
import PairQL

struct DeleteAccountKey: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let keychainId: Keychain.Id
    let keyId: Key.Id
  }
}

extension DeleteAccountKey: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let keychain = try await context.keychain(input.keychainId)
    _ = try await Key.query()
      .where(.id == input.keyId)
      .where(.keychainId == keychain.id)
      .first(in: context.db)

    return try await DeleteEntity_v2.resolve(
      with: .init(id: input.keyId.rawValue, type: .key),
      in: context.legacyContext,
    )
  }
}
