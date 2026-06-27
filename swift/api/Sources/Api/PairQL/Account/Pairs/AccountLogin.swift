import PairQL

struct AccountLogin: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let email: String
    let password: String
  }

  struct Output: PairOutput {
    let accountId: Parent.Id
    let token: Parent.DashToken.Value
  }
}

// resolver

extension AccountLogin: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let result = try await Login.resolve(
      with: .init(email: input.email, password: input.password),
      in: context,
    )
    return Output(accountId: result.adminId, token: result.token)
  }
}
