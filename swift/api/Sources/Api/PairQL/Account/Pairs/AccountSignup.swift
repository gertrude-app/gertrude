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

    let result = try await Signup.resolve(
      with: .init(
        email: email,
        password: input.password,
        gclid: input.gclid,
        abTestVariant: input.abTestVariant,
        referralCode: input.referralCode,
        turnstileToken: input.turnstileToken,
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
  typealias Output = AccountLogin.Output
}

extension AccountVerifySignupEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let result = try await VerifySignupEmail.resolve(with: input, in: context)
    return Output(accountId: result.adminId, token: result.token)
  }
}
