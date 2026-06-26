import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class SignupTests: ApiTestCase, @unchecked Sendable {
  let context = Context.mock

  func testInitiateSignupWithBadEmailErrorsBadRequest() async throws {
    let result = await Signup.result(with: .init(email: "💩", password: ""), in: self.context)
    expect(result).toBeError(containing: "Bad Request")
  }

  func testInitiateSignupWithExistingVerifiedEmailButBadPasswordSendsEmail() async throws {
    let existing = try await self.db.create(Parent.random {
      $0.password = "nope"
      $0.emailVerifiedAt = .reference - .days(1)
    })

    let input = Signup.Input(email: existing.email.rawValue, password: "pass")
    let output = try await Signup.resolve(with: input, in: self.context)

    expect(output).toEqual(.init(admin: nil))
    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].template).toBe("re-signup")
  }

  func testInitiateSignupHappyPath() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(email: email, password: "pass")
    let output = try await Signup.resolve(with: input, in: self.context)

    let parent = try await Parent.query()
      .where(.email == email)
      .first(in: self.db)

    expect(output).toEqual(.init(admin: nil))
    expect(parent.emailVerifiedAt).toEqual(nil)
    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].to).toEqual(email)
    expect(sent.emails[0].template).toBe("initial-signup")
    expect(sent.emails[0].templateModel["redirect"]).toEqual("")
  }

  func testSignupWithAmClaimBakesFunnelRedirectIntoEmail() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(email: email, password: "pass", claimCode: "123456", intent: .podcasts)
    _ = try await Signup.resolve(with: input, in: self.context)

    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].template).toBe("initial-signup")
    expect(sent.emails[0].templateModel["redirect"])
      .toEqual("%2Fclaim-am-device%2F123456%2Fclaim")
  }

  func testSignupWithClaimMintsAppAwareVerificationToken() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(email: email, password: "pass", claimCode: "123456", intent: .podcasts)
    _ = try await Signup.resolve(with: input, in: self.context)

    let parent = try await Parent.query()
      .where(.email == email)
      .first(in: self.db)
    let token = UUID(uuidString: sent.emails[0].templateModel["token"] ?? "")!
    let retrieved = await with(dependency: \.ephemeral).parentIdFromToken(token)

    expect(retrieved).toEqual(.notExpired(parent.id, claimCode: "123456", claimIntent: .podcasts))
  }

  func testSignupWithBlockerClaimBakesSupervisionRedirectIntoEmail() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(
      email: email,
      password: "pass",
      claimCode: "123456",
      intent: .blockerSupervise,
    )
    _ = try await Signup.resolve(with: input, in: self.context)

    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].templateModel["redirect"])
      .toEqual("%2Fsupervise-device%2F123456%2Fclaim")
  }

  func testInitiateSignupWithGclidAndABVariant() async throws {
    let email = "signup".random + "@example.com"
    let input = Signup.Input(
      email: email,
      password: "pass",
      gclid: "gclid-123",
      abTestVariant: "old_site",
    )

    _ = try await Signup.resolve(with: input, in: self.context)

    let parent = try await Parent.query()
      .where(.email == email)
      .first(in: self.db)

    expect(parent.gclid).toEqual("gclid-123")
    expect(parent.abTestVariant).toEqual("old_site")
  }

  func testSignupStoresValidReferral() async throws {
    let referrer = try await self.db.create(Parent.random {
      $0.referralCode = "PARENT-ONE"
    })
    let email = "referred".random + "@example.com"

    _ = try await Signup.resolve(
      with: .init(
        email: email,
        password: "pass",
        referralCode: "  PARENT-ONE ",
      ),
      in: self.context,
    )

    let referred = try await Parent.query()
      .where(.email == email)
      .first(in: self.db)

    expect(referred.referredByParentId).toEqual(referrer.id)
  }

  func testSignupIgnoresUnknownReferralCode() async throws {
    let email = "unknown-referral".random + "@example.com"

    _ = try await Signup.resolve(
      with: .init(email: email, password: "pass", referralCode: "does-not-exist"),
      in: self.context,
    )

    let referred = try await Parent.query()
      .where(.email == email)
      .first(in: self.db)

    expect(referred.referredByParentId).toBeNil()
  }

  func testSignupSlackMessageIncludesReferralContext() {
    let parent = Parent.random
    let referrer = Parent.random(with: {
      $0.referralCode = "PARENT-ONE"
    })

    let message = newSignupSlackMessage(parent, nil, referrer)

    expect(message).toContain("referral: `PARENT-ONE`")
    expect(message).toContain(referrer.email.rawValue)
  }

  func testSigningUpWhenAlreadyVerifiedReturnsAuthCreds() async throws {
    let uuids = MockUUIDs()
    let existing = try await self.parent {
      $0.password = "pass"
      $0.emailVerifiedAt = .reference - .days(1)
    }

    try await withDependencies {
      $0.uuid = .mock(uuids)
    } operation: {
      let input = Signup.Input(email: existing.email.rawValue, password: "pass")
      let output = try await Signup.resolve(with: input, in: self.context)

      expect(output).toEqual(.init(admin: .init(
        adminId: existing.id,
        token: .init(uuids[1]),
      )))

      expect(sent.emails.count).toEqual(0)
    }
  }

  func testSignupFailsIfTurnstileTokenRejected() async throws {
    var env = Env.fromProcess(mode: .testing)
    env.mode = .prod

    await withDependencies {
      $0.env = env
      $0.cloudflare = .init(verifyTurnstileToken: { _ in .failure(errorCodes: [], messages: nil) })
    } operation: {
      let input = Signup.Input(email: "test@example.com", password: "pass", turnstileToken: "bad")
      let result = await Signup.result(with: input, in: self.context)
      expect(result).toBeError(containing: "invalid turnstile token")
    }
  }
}
