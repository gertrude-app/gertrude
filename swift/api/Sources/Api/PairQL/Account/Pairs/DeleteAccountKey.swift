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
    let keychain = try await Keychain.query()
      .where(.id == input.keychainId)
      .where(.parentId == context.accountOwner.id)
      .first(in: context.db)
    guard !keychain.isPublic else {
      throw context.error(
        id: "4addf574",
        type: .badRequest,
        debugMessage: "account site attempted to delete key from public keychain \(keychain.id)",
        userMessage: "Public keychains are maintained by Gertrude and can't be edited.",
        showContactSupport: false,
      )
    }
    let key = try await Key.query()
      .where(.id == input.keyId)
      .where(.keychainId == keychain.id)
      .first(in: context.db)

    try await context.db.delete(key, force: true)
    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .usersWith(keychain: keychain.id))
    return .success
  }
}
