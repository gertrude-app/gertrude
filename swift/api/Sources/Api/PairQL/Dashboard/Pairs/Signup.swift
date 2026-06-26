import Dependencies
import DuetSQL
import Foundation
import PairQL
import Vapor

struct Signup: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    var email: String
    var password: String
    var gclid: String?
    var abTestVariant: String?
    var referralCode: String?
    var turnstileToken: String?
    var claimCode: String?
    var intent: ClaimIntent?
  }

  struct Output: PairOutput {
    var admin: Login.Output?
  }
}

// resolver

extension Signup: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now
    @Dependency(\.postmark) var postmark
    @Dependency(\.slack) var slack
    @Dependency(\.cloudflare) var cloudflare

    let email = input.email.lowercased()
    if !email.isValidEmail {
      throw Abort(.badRequest)
    }

    if context.env.mode == .prod, !isProdSmokeTestAddress(email) {
      try await verifyTurnstileToken(input.turnstileToken, cloudflare)
    }

    let existingParent = try? await Parent.query()
      .where(.email == email)
      .first(in: context.db)

    if let existingParent {
      if existingParent.emailVerified, let creds = try? await Login.resolve(
        with: .init(email: input.email, password: input.password),
        in: context,
      ) {
        return .init(admin: creds)
      }

      if context.env.mode == .prod, !isTestAddress(email) {
        postmark.toSuperAdmin("signup [exists]", email)
      }

      if !existingParent.emailVerified {
        try await sendVerificationEmail(
          to: existingParent,
          claimCode: input.claimCode,
          claimIntent: input.intent,
          in: context,
        )
      } else {
        try await postmark.send(template: .reSignup(
          to: email,
          model: .init(dashboardUrl: context.dashboardUrl),
        ))
      }

      return .init(admin: nil)
    }

    let referralCode = input.referralCode?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .uppercased()
    let referrer: Parent? = if let referralCode, !referralCode.isEmpty {
      try await Parent.query()
        .where(.referralCode == referralCode)
        .all(in: context.db)
        .first
    } else {
      nil
    }
    let parent = try await context.db.create(Parent(
      email: .init(rawValue: email),
      password: context.env.mode == .test ? input.password : Bcrypt.hash(input.password),
      gclid: input.gclid,
      abTestVariant: input.abTestVariant,
      referredByParentId: referrer?.id,
    ))

    if context.env.mode == .prod, !isTestAddress(email) {
      await slack.internal(.signups, newSignupSlackMessage(parent, input.gclid, referrer))
    }

    try await sendVerificationEmail(
      to: parent,
      claimCode: input.claimCode,
      claimIntent: input.intent,
      in: context,
    )
    return .init(admin: nil)
  }
}

// helpers

func newSignupSlackMessage(_ parent: Parent, _ gclid: String?, _ referrer: Parent?) -> String {
  var message = """
    *New signup:*
    id: `\(parent.id.lowercased)`
    email: `\(parent.email.rawValue)`
    g-ad: `\(gclid != nil)`
  """
  if let referrer {
    let link = AdminLink().slack(to: .parent(referrer.id), text: referrer.email.rawValue)
    message += "\nreferral: `\(referrer.referralCode ?? "(unknown)")` from \(link)"
  }
  return message
}

func sendVerificationEmail(
  to admin: Parent,
  claimCode: String? = nil,
  claimIntent: ClaimIntent? = nil,
  in context: Context,
) async throws {
  let token = await with(dependency: \.ephemeral)
    .createParentIdToken(
      admin.id,
      expiration: get(dependency: \.date.now) + .hours(24),
      claimCode: claimCode,
      claimIntent: claimIntent,
    )

  var redirect: String?
  if let claimIntent, let claimCode, let code = Int(claimCode) {
    redirect = claimIntent.claimFunnelPath(code: code)
      .addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
  }

  try await with(dependency: \.postmark)
    .send(template: .initialSignup(
      to: admin.email.rawValue,
      model: .init(dashboardUrl: context.dashboardUrl, token: token, redirect: redirect),
    ))
}

func verifyTurnstileToken(_ token: String?, _ cloudflare: CloudflareClient) async throws {
  guard let token else {
    throw Abort(.badRequest, reason: "missing turnstile token")
  }
  switch await cloudflare.verifyTurnstileToken(token) {
  case .success:
    break
  case .failure:
    throw Abort(.badRequest, reason: "invalid turnstile token")
  case .error(let error):
    await with(dependency: \.slack).error("""
      *Error verifying turnstile token (signup)*
      Token: `\(token)`
      Error: \(String(reflecting: error))
    """)
  }
}
