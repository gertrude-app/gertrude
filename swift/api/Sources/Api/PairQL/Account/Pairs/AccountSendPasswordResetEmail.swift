import Foundation
import PairQL

struct AccountSendPasswordResetEmail: Pair {
  static let auth: ClientAuth = .none
  typealias Input = SendPasswordResetEmail.Input
}

extension AccountSendPasswordResetEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await SendPasswordResetEmail.resolve(with: input, in: context)
  }
}
