import DuetSQL
import Foundation
import Gertie
import PairQL

struct SaveAccountKey: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let keychainId: Keychain.Id
    let keyId: Key.Id?
    let key: Gertie.Key
    let comment: String?
    let expiration: Date?
  }
}

extension SaveAccountKey: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let keychain = try await context.keychain(input.keychainId)

    switch input.key {
    case .path:
      throw context.unexpectedError("2272f45f", "account save legacy path key")
    case .skeleton:
      throw context.unexpectedError("c48110cc", "account save skeleton key")
    case .anySubdomain, .domain, .domainRegex, .ipAddress:
      break
    }

    if let keyId = input.keyId {
      _ = try await Key.query()
        .where(.id == keyId)
        .where(.keychainId == keychain.id)
        .first(in: context.db)
    }

    return try await SaveKey.resolve(
      with: .init(
        isNew: input.keyId == nil,
        id: input.keyId ?? .init(),
        keychainId: keychain.id,
        key: input.key,
        comment: input.comment,
        expiration: input.expiration,
      ),
      in: context.legacyContext,
    )
  }
}
