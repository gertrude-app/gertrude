import Dependencies
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class VerifySignupEmailResolverTests: ApiTestCase, @unchecked Sendable {
  let context = Context.mock

  func testVerifySignupEmailSetsSubscriptionStatusAndCreatesNotificationMethod() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: nil)
    let token = await with(dependency: \.ephemeral).createParentIdToken(parent.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    let subscription = try await parent.model.subscription(in: self.db)
    let method = try await Parent.NotificationMethod.query()
      .where(.parentId == parent.id)
      .first(in: self.db)

    expect(output.adminId).toEqual(parent.id)
    expect(subscription).toBeNil()
    expect(method.config).toEqual(.email(email: parent.email.rawValue))
  }

  func testVerifySignupEmailReturnsClaimCodeAndApp() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: nil)
    let token = await with(dependency: \.ephemeral).createParentIdToken(
      parent.id,
      claimCode: "123456",
      claimIntent: .podcasts,
    )

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    expect(output.adminId).toEqual(parent.id)
    expect(output.claimCode).toEqual("123456")
    expect(output.claimIntent).toEqual(.podcasts)
  }

  func testVerifyingWithExpiredTokenErrorsButSendsNewVerification() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: nil)
    let token = await with(dependency: \.ephemeral).createParentIdToken(
      parent.id,
      expiration: Date.reference - .days(1),
    )

    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)

    expect(result).toBeError(containing: "expired, but we sent a new verification email")
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].to).toEqual(parent.email.rawValue)
    expect(sent.emails[0].template).toBe("initial-signup")
  }

  func testExpiredTokenResendPreservesClaimContext() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: nil)
    let ephemeral = with(dependency: \.ephemeral)
    let token = await ephemeral.createParentIdToken(
      parent.id,
      expiration: Date.reference - .days(1),
      claimCode: "123456",
      claimIntent: .podcasts,
    )

    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)

    expect(result).toBeError(containing: "expired, but we sent a new verification email")
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].template).toBe("initial-signup")
    expect(sent.emails[0].templateModel["redirect"]) // <-- replacement email keeps funnel
      .toEqual("%2Fclaim-am-device%2F123456%2Fclaim")

    let newToken = UUID(uuidString: sent.emails[0].templateModel["token"] ?? "")!
    let retrieved = await ephemeral.parentIdFromToken(newToken)
    expect(retrieved).toEqual(.notExpired(parent.id, claimCode: "123456", claimIntent: .podcasts))
  }

  func testExpiredTokenForAlreadyVerifiedParentErrorsWithHelpfulMessage() async throws {
    try await withDependencies {
      $0.date = .init { Date() }
    } operation: {
      let parent = try await self.parent(with: \.emailVerifiedAt, of: .epoch) // <- verified
      let token = await with(dependency: \.ephemeral).createParentIdToken(
        parent.id,
        expiration: Date() - .days(1),
      )

      let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)
      expect(result).toBeError(containing: "already verified")
      expect(sent.emails).toHaveCount(0) // no email sent, they're already verified
    }
  }

  func testPreviouslyRetrievedTokenForVerifiedParentErrors() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: nil)
    let token = await with(dependency: \.ephemeral).createParentIdToken(parent.id)

    // first use succeeds
    _ = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    // second use of same token fails
    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)
    expect(result).toBeError(containing: "already verified")
  }

  func testPreviouslyRetrievedTokenForStillPendingParentResendsEmail() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: nil)
    let ephemeral = with(dependency: \.ephemeral)
    let token = await ephemeral.createParentIdToken(
      parent.id,
      claimCode: "123456",
      claimIntent: .podcasts,
    )

    // simulate token being retrieved but parent somehow still pending
    _ = await ephemeral.parentIdFromToken(token)

    // manually reset the parent to pending (simulating edge case)
    var retrieved = try await self.db.find(parent.id)
    retrieved.emailVerifiedAt = nil
    try await self.db.update(retrieved)

    let result = await VerifySignupEmail.result(with: .init(token: token), in: self.context)
    expect(result).toBeError(containing: "we sent a new verification email")
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].templateModel["redirect"]) // <-- resend keeps funnel
      .toEqual("%2Fclaim-am-device%2F123456%2Fclaim")
  }

  func testVerifySignupEmailDoesntChangeAdminUserSubscriptionStatusWhenNotPending() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: .epoch) // <- verified
    let token = await with(dependency: \.ephemeral)
      .createParentIdToken(parent.id)

    let output = try await VerifySignupEmail.resolve(with: .init(token: token), in: self.context)

    let retrieved = try await self.db.find(parent.id)

    expect(output.adminId).toEqual(parent.id)
    expect(retrieved.emailVerifiedAt).toEqual(.epoch) // <-- not changed
  }

  func testAttemptToLoginWhenEmailNotVerifiedBlocksAndSendsEmail() async throws {
    let parent = try await self.parent {
      $0.emailVerifiedAt = nil
      $0.password = "lol-lol-lol"
    }

    let result = await Login.result(
      with: .init(email: parent.email.rawValue, password: "lol-lol-lol"),
      in: self.context,
    )

    expect(result).toBeError(containing: "until your email is verified")
    expect(sent.emails).toHaveCount(1)
    expect(sent.emails[0].to).toEqual(parent.email.rawValue)
    expect(sent.emails[0].template).toBe("initial-signup")
  }
}
