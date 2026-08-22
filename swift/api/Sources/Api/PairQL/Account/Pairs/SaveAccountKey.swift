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
    let keychain = try await Keychain.query()
      .where(.id == input.keychainId)
      .where(.parentId == context.accountOwner.id)
      .first(in: context.db)
    guard !keychain.isPublic else {
      throw context.error(
        id: "68c0a4fb",
        type: .badRequest,
        debugMessage: "account site attempted to edit public keychain \(keychain.id)",
        userMessage: "Public keychains are maintained by Gertrude and can't be edited.",
        showContactSupport: false,
      )
    }

    switch input.key {
    case .path:
      throw context.error(
        id: "2272f45f",
        type: .badRequest,
        debugMessage: "account site attempted to save legacy path key",
        userMessage: "Legacy path keys can't be edited. Delete this key and create a replacement instead.",
        showContactSupport: false,
      )
    case .skeleton:
      throw context.error(
        id: "c48110cc",
        type: .badRequest,
        debugMessage: "account site attempted to save skeleton key",
        userMessage: "App internet access is managed from the person's Mac Apps settings.",
        showContactSupport: false,
      )
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
