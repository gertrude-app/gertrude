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
  guard
    let redirect,
    redirect.hasPrefix("/"),
    !redirect.hasPrefix("//"),
    !redirect.contains("\\"),
    redirect.rangeOfCharacter(from: .controlCharacters) == nil,
    let components = URLComponents(string: redirect),
    components.scheme == nil,
    components.host == nil
  else { return nil }
  return redirect
}
