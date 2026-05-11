import Dependencies
import Foundation
import PairQL
import Vapor

struct AdminAuth: PairOutput {
  var token: Parent.DashToken.Value
  var adminId: Parent.Id
  var claimCode: String?
}

struct VerifySignupEmail: Pair {
  static let auth: ClientAuth = .none

  struct Input: PairInput {
    let token: UUID
  }

  typealias Output = AdminAuth
}

// resolver

extension VerifySignupEmail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    switch await with(dependency: \.ephemeral).parentIdFromToken(input.token) {

    // happy path: verification is successful
    case .notExpired(let parentId, let claimCode):
      context.telemetry.parentId = parentId
      var parent = try await context.db.find(parentId)
      let token = try await context.db.create(Parent.DashToken(parentId: parent.id))
      if parent.emailVerified {
        return .init(token: token.value, adminId: parent.id, claimCode: claimCode)
      }

      parent.emailVerifiedAt = get(dependency: \.date.now)
      try await context.db.update(parent)

      // they get a default "verified" notification method, since they verified email
      try await context.db.create(Parent.NotificationMethod(
        parentId: parent.id,
        config: .email(email: parent.email.rawValue),
      ))

      if context.env.mode == .prod, !isTestAddress(parent.email.rawValue) {
        var body = AdminLink().email(to: .parent(parent.id), text: parent.email.rawValue)
        if let gclid = parent.gclid {
          body += "<br/>gclid: \(gclid)"
        }
        with(dependency: \.postmark)
          .toSuperAdmin("signup completed", body)
        await with(dependency: \.slack)
          .internal(.signups, "email verified: `\(parent.email.rawValue)`")
      }

      return Output(token: token.value, adminId: parent.id, claimCode: claimCode)

    case .notFound:
      throw Abort(.notFound)

    case .expired(let parentId):
      context.telemetry.parentId = parentId
      let parent = try await context.db.find(parentId)
      if !parent.emailVerified {
        try await sendVerificationEmail(to: parent, in: context)
        throw context.error("84a6c609", .badRequest, user: EXPIRED_TOKEN_MSG)
      } else {
        throw context.error(
          "beb1b493",
          .badRequest,
          "email already verified",
          .emailAlreadyVerified,
        )
      }

    case .previouslyRetrieved(let parentId):
      context.telemetry.parentId = parentId
      let parent = try await context.db.find(parentId)
      if !parent.emailVerified {
        try await sendVerificationEmail(to: parent, in: context)
        throw context.error("6257bfb9", .badRequest, user: UNEXPECTED_RESEND_MSG)
      } else {
        throw context.error(
          "f2b70e49",
          .badRequest,
          "email already verified",
          .emailAlreadyVerified,
        )
      }
    }
  }
}

// helpers

private let EXPIRED_TOKEN_MSG =
  "The link you clicked has expired, but we sent a new verification email. Please check your email and try again."

private let UNEXPECTED_RESEND_MSG =
  "Sorry, we couldn't verify you this time, but we sent a new verification email. Please check your email and try again."
