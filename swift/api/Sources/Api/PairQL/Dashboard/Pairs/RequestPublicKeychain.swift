import Dependencies
import PairQL

struct RequestPublicKeychain: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var searchQuery: String
    var description: String
  }
}

extension RequestPublicKeychain: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.postmark) var postmark

    let adminLink = AdminLink()
    let html = """
    <p>From admin \(adminLink.email(
      to: .parent(context.parent.id),
      text: context.parent.email.rawValue,
    )).</p>
    <p>They searched for "<b>\(input.searchQuery)</b>". This is what they want:</p>
    <code>"\(input.description)"</code>
    """

    postmark.toSuperAdmin("Public keychain request", html)
    return .success
  }
}
