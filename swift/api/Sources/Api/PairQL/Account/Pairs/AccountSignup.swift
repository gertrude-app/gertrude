import PairQL

struct AccountSignup: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let email: String
    let password: String
    let redirect: String?
    let turnstileToken: String?
  }

  struct Output: PairOutput {
    let accountId: Parent.Id?
    let token: Parent.DashToken.Value?
  }
}

extension AccountSignup: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let claim = input.redirect.flatMap(accountClaimFromRedirect)
    let result = try await Signup.resolve(
      with: .init(
        email: input.email,
        password: input.password,
        turnstileToken: input.turnstileToken,
        claimCode: claim.map { String($0.code) },
        intent: claim?.flow.intent,
      ),
      in: context,
    )
    return .init(accountId: result.admin?.adminId, token: result.admin?.token)
  }
}

struct AccountVerifySignupEmail: Pair {
  static let auth: ClientAuth = .none

  typealias Input = VerifySignupEmail.Input

  struct Output: PairOutput {
    let accountId: Parent.Id
    let token: Parent.DashToken.Value
    let redirect: String?
  }
}

extension AccountVerifySignupEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let result = try await VerifySignupEmail.resolve(with: input, in: context)
    let redirect: String? = if let intent = result.claimIntent,
                               let flow = AccountIOSFlow(intent),
                               let code = result.claimCode.flatMap(Int.init),
                               (100_000 ... 999_999).contains(code) {
      flow.path(code: code)
    } else {
      nil
    }
    return .init(accountId: result.adminId, token: result.token, redirect: redirect)
  }
}

private func accountClaimFromRedirect(_ redirect: String) -> (flow: AccountIOSFlow, code: Int)? {
  let parts = redirect.split(separator: "/", omittingEmptySubsequences: false)
  guard parts.count == 4, parts[0].isEmpty, parts[1] == "connect",
        let flow = AccountIOSFlow(rawValue: String(parts[2])),
        let code = Int(parts[3]), (100_000 ... 999_999).contains(code)
  else { return nil }
  return (flow, code)
}
