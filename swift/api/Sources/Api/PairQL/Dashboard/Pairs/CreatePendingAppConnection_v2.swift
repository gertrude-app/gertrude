import Foundation
import PairQL

// deprecated: use MacAppConnectionCode instead, remove after 2026-02-25
struct CreatePendingAppConnection_v2: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = MacAppConnectionCode.Input
  typealias Output = MacAppConnectionCode.Output
}

extension CreatePendingAppConnection_v2: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await MacAppConnectionCode.resolve(with: input, in: context)
  }
}
