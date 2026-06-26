import Foundation
import PairQL

struct ToggleActivityFlag: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let ids: [UUID]
  }
}

// resolver

extension ToggleActivityFlag: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    try await FlagActivityItems.resolve(with: input.ids, in: context.legacyContext)
  }
}
