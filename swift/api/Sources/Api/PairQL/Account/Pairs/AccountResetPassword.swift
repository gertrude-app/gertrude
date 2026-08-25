import Foundation
import PairQL

struct AccountResetPassword: Pair {
  static let auth: ClientAuth = .none
  typealias Input = ResetPassword.Input
}

extension AccountResetPassword: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await ResetPassword.resolve(with: input, in: context)
  }
}
