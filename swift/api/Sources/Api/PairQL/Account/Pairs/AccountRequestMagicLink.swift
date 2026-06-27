import PairQL

struct AccountRequestMagicLink: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let email: String
  }
}

// resolver

extension AccountRequestMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await RequestMagicLink.resolve(
      with: .init(email: input.email, redirect: nil),
      in: context,
    )
  }
}
