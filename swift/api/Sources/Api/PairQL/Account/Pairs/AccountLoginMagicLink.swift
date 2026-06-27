import Foundation
import PairQL

struct AccountLoginMagicLink: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let token: UUID
  }

  struct Output: PairOutput {
    let accountId: Parent.Id
    let token: Parent.DashToken.Value
  }
}

// resolver

extension AccountLoginMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let result = try await LoginMagicLink.resolve(with: .init(token: input.token), in: context)
    return Output(accountId: result.adminId, token: result.token)
  }
}
