import Foundation
import PairQL

struct SaveAccountKeychain: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let keychainId: Keychain.Id?
    let name: String
    let description: String?
  }

  struct Output: PairOutput {
    let id: Keychain.Id
  }
}

extension SaveAccountKeychain: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    if let keychainId = input.keychainId {
      _ = try await context.privateKeychain(keychainId)
    }
    let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      throw context.error("8d48a231", .badRequest, user: "Enter a name for this keychain.")
    }
    let description = input.description?.trimmingCharacters(in: .whitespacesAndNewlines)
    let id = input.keychainId ?? .init()
    _ = try await SaveKeychain.resolve(
      with: .init(
        isNew: input.keychainId == nil,
        id: id,
        name: name,
        description: description?.isEmpty == false ? description : nil,
      ),
      in: context.legacyContext,
    )
    return .init(id: id)
  }
}
