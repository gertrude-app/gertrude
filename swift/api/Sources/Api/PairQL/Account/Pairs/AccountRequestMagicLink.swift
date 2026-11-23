import Foundation
import PairQL

struct AccountRequestMagicLink: Pair {
  static let auth: ClientAuth = .none
  typealias Input = RequestMagicLink.Input
}

// resolver

extension AccountRequestMagicLink: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await RequestMagicLink.resolve(
      with: .init(
        email: input.email,
        redirect: validatedAccountRedirect(input.redirect),
      ),
      in: context,
    )
  }
}

private func validatedAccountRedirect(_ redirect: String?) -> String? {
  guard let redirect, redirect.isLocalAppPath else { return nil }
  return redirect
}
