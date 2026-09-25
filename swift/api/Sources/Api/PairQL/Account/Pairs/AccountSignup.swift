import Foundation
import PairQL

struct AccountSignup: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
    var password: String
    var gclid: String?
    var abTestVariant: String?
    var referralCode: String?
    var redirect: String?
    var turnstileToken: String?
  }

  struct Output: PairOutput {
    var account: AccountLogin.Output?
  }
}

extension AccountSignup: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let email = input.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard email.isValidEmail else {
      throw context.error("8740e3a5", .badRequest, user: "Enter a valid email address.")
    }
    guard input.password.count >= 5 else {
      throw context.error(
        "389b4844",
        .badRequest,
        user: "Use at least five characters for your password.",
      )
    }

    let claim = input.redirect.flatMap(accountClaimFromRedirect)
    let result = try await Signup.resolve(
      with: .init(
        email: email,
        password: input.password,
        gclid: input.gclid,
        abTestVariant: input.abTestVariant,
        referralCode: input.referralCode,
        turnstileToken: input.turnstileToken,
        claimCode: claim.map { String($0.code) },
        intent: claim?.flow,
      ),
      in: context,
    )
    return Output(account: result.admin.map {
      .init(accountId: $0.adminId, token: $0.token)
    })
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
                               let code = result.claimCode.flatMap(Int.init),
                               (100_000 ... 999_999).contains(code) {
      intent.accountClaimPath(code: code)
    } else {
      nil
    }
    return .init(accountId: result.adminId, token: result.token, redirect: redirect)
  }
}

private func accountClaimFromRedirect(_ redirect: String) -> (flow: ClaimIntent, code: Int)? {
  let parts = redirect.split(separator: "/", omittingEmptySubsequences: false)
  guard parts.count == 4, parts[0].isEmpty, parts[1] == "connect",
        let flow = ClaimIntent(rawValue: String(parts[2])),
        let code = Int(parts[3]), (100_000 ... 999_999).contains(code)
  else { return nil }
  return (flow, code)
}
