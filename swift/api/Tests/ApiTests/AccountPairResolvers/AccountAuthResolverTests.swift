import CustomDump
import Dependencies
import DuetSQL
import Foundation
import PairQL
import XCTest
import XExpect

@testable import Api

final class AccountAuthResolverTests: ApiTestCase, @unchecked Sendable {
  private let accountContext = Context(
    requestId: "mock-req-id",
    dashboardUrl: "https://account.example",
    ipAddress: nil,
    telemetry: TelemetryBag(),
  )

  func testSignupAndVerificationUseAccountRoutesAndMapCredentials() async throws {
    let email = "account-signup".random + "@example.com"
    let signupResponse = try await PairQLRoute.respond(
      to: .account(.unauthed(.accountSignup(.init(
        email: "  \(email.uppercased())  ",
        password: "secret-password",
      )))),
      in: .mock,
    )
    let signup = try JSONDecoder().decode(
      AccountSignup.Output.self,
      from: signupResponse.body.data!,
    )
    expectNoDifference(signup.account, nil)
    let verificationEmail = try XCTUnwrap(self.sent.emails.first)
    expectNoDifference(
      verificationEmail.templateModel["dashboardUrl"],
      self.env.accountDashboardUrl,
    )
    expectNoDifference(verificationEmail.to, email)

    let parent = try await Parent.query().where(.email == email).first(in: self.db)
    let verificationToken =
      try XCTUnwrap(UUID(uuidString: verificationEmail.templateModel["token"]!))

    let verifyResponse = try await PairQLRoute.respond(
      to: .account(.unauthed(.accountVerifySignupEmail(.init(token: verificationToken)))),
      in: .mock,
    )
    let verified = try JSONDecoder().decode(
      AccountVerifySignupEmail.Output.self,
      from: verifyResponse.body.data!,
    )
    expectNoDifference(verified.accountId, parent.id)
    expectNoDifference(verified.redirect, nil)
    let authToken = try await Parent.DashToken.query().where(.value == verified.token)
      .first(in: self.db)
    expectNoDifference(authToken.parentId, parent.id)
  }

  func testSignupAndVerificationPreservePairingDestination() async throws {
    let email = "pairing".random + "@example.com"
    let signup = try await AccountSignup.resolve(
      with: .init(
        email: email,
        password: "secret",
        redirect: "/connect/blockerSupervise/123456",
        turnstileToken: nil,
      ),
      in: self.accountContext,
    )
    expect(signup.account).toBeNil()
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].templateModel["dashboardUrl"]).toEqual("https://account.example")
    let token = UUID(uuidString: self.sent.emails[0].templateModel["token"] ?? "")!

    let verified = try await AccountVerifySignupEmail.resolve(
      with: .init(token: token),
      in: self.accountContext,
    )
    expect(verified.redirect).toEqual("/connect/blockerSupervise/123456")
  }

  func testSignupIgnoresExternalOrUnrecognizedRedirect() async throws {
    let email = "pairing".random + "@example.com"
    _ = try await AccountSignup.resolve(
      with: .init(
        email: email,
        password: "secret",
        redirect: "//evil.example",
        turnstileToken: nil,
      ),
      in: self.accountContext,
    )
    let token = UUID(uuidString: self.sent.emails[0].templateModel["token"] ?? "")!
    let verified = try await AccountVerifySignupEmail.resolve(
      with: .init(token: token),
      in: self.accountContext,
    )
    expect(verified.redirect).toBeNil()
  }

  func testSignupForwardsAttribution() async throws {
    let referrer = try await self.db
      .create(Parent.random { $0.referralCode = $0.id.lowercased.uppercased() })
    let email = "account-attribution".random + "@example.com"
    _ = try await AccountSignup.resolve(
      with: .init(
        email: email,
        password: "secret-password",
        gclid: "ad-click",
        abTestVariant: "new_site",
        referralCode: referrer.referralCode,
      ),
      in: self.accountContext,
    )
    let parent = try await Parent.query().where(.email == email).first(in: self.db)
    expectNoDifference(parent.gclid, "ad-click")
    expectNoDifference(parent.abTestVariant, "new_site")
    expectNoDifference(parent.referredByParentId, referrer.id)
  }

  func testSignupWithExistingVerifiedCredentialsReturnsAccountAuth() async throws {
    let parent = try await self.parent {
      $0.password = "secret-password"
      $0.emailVerifiedAt = .reference
    }
    let output = try await AccountSignup.resolve(
      with: .init(email: parent.email.rawValue, password: "secret-password"),
      in: self.accountContext,
    )
    expectNoDifference(output.account?.accountId, parent.id)
    expect(output.account?.token).not.toBeNil()
  }

  func testSignupLoginHelpEmailUsesAccountUrl() async throws {
    let parent = try await self.parent {
      $0.password = "original-password"
      $0.emailVerifiedAt = .reference
    }
    let output = try await AccountSignup.resolve(
      with: .init(email: parent.email.rawValue, password: "different-password"),
      in: self.accountContext,
    )
    expectNoDifference(output.account, nil)
    expect(self.sent.emails).toHaveCount(1)
    expectNoDifference(self.sent.emails[0].templateModel["dashboardUrl"], "https://account.example")
  }

  func testSignupRejectsInvalidEmailAndShortPasswordBeforeSendingEmail() async throws {
    let badEmail = await AccountSignup.result(
      with: .init(email: "invalid", password: "secret-password"),
      in: self.accountContext,
    )
    expect(badEmail).toBeError(containing: "Enter a valid email address")
    let shortPassword = await AccountSignup.result(
      with: .init(email: "valid@example.com", password: "1234"),
      in: self.accountContext,
    )
    expect(shortPassword).toBeError(containing: "Use at least five characters")
    expect(self.sent.emails).toHaveCount(0)
  }

  func testAccountSignupRequiresValidTurnstileTokenInProduction() async throws {
    await withDependencies {
      $0.env.mode = .prod
      $0.cloudflare = .init(verifyTurnstileToken: { _ in .failure(errorCodes: [], messages: nil) })
    } operation: {
      let missing = await AccountSignup.result(
        with: .init(email: "signup@example.com", password: "secret-password"),
        in: self.accountContext,
      )
      expect(missing).toBeError(containing: "missing turnstile token")
      let rejected = await AccountSignup.result(
        with: .init(
          email: "signup@example.com",
          password: "secret-password",
          turnstileToken: "bad",
        ),
        in: self.accountContext,
      )
      expect(rejected).toBeError(containing: "invalid turnstile token")
      expect(self.sent.emails).toHaveCount(0)
    }
  }

  func testExpiredVerificationResendsToAccountSiteAndPreservesPairing() async throws {
    let parent = try await self.parent(with: \.emailVerifiedAt, of: nil)
    let token = await with(dependency: \.ephemeral).createParentIdToken(
      parent.id,
      expiration: .reference - .days(1),
      claimCode: "123456",
      claimIntent: .podcasts,
    )
    let result = await AccountVerifySignupEmail.result(
      with: .init(token: token),
      in: self.accountContext,
    )
    guard case .failure(let error) = result else {
      XCTFail("Expected a verification error")
      return
    }
    expectNoDifference((error as? PqlError)?.dashboardTag, .verificationEmailResent)
    expect(self.sent.emails).toHaveCount(1)
    expectNoDifference(self.sent.emails[0].templateModel["dashboardUrl"], "https://account.example")
    let replacementToken = try XCTUnwrap(
      UUID(uuidString: self.sent.emails[0].templateModel["token"]!),
    )
    let verified = try await AccountVerifySignupEmail.resolve(
      with: .init(token: replacementToken),
      in: self.accountContext,
    )
    expectNoDifference(verified.accountId, parent.id)
    expectNoDifference(verified.redirect, "/connect/podcasts/123456")
  }

  func testPasswordResetEmailUsesAccountUrl() async throws {
    let parent = try await self.db.create(Parent.random)

    let output = try await AccountSendPasswordResetEmail.resolve(
      with: .init(email: parent.email.rawValue),
      in: self.accountContext,
    )

    expect(output).toEqual(.success)
    expect(self.sent.emails).toHaveCount(1)
    expect(self.sent.emails[0].templateModel["dashboardUrl"])
      .toEqual("https://account.example")
  }

  func testMagicLinkPreservesLocalRedirects() async throws {
    let parent = try await self.db.create(Parent.random)
    let redirects = [
      "/requests/suspension/\(parent.id.lowercased)",
      "/activity/person/\(parent.id.lowercased)/day/2026-07-24?view=screenshots&query=school#results",
      "/a-page-that-does-not-exist",
    ]

    for redirect in redirects {
      sent.emails = []
      let (_, output) = try await withUUID {
        try await AccountRequestMagicLink.resolve(
          with: .init(email: parent.email.rawValue, redirect: redirect),
          in: self.accountContext,
        )
      }

      expect(output).toEqual(.success)
      expect(self.sent.emails).toHaveCount(1)
      let url = try XCTUnwrap(self.sent.emails[0].templateModel["url"])
      let components = try XCTUnwrap(URLComponents(string: url))
      let redirectValue = components.queryItems?.first { $0.name == "redirect" }?.value
      expect(redirectValue).toEqual(redirect)
    }
  }

  func testMagicLinkDiscardsExternalAndRelativeRedirects() async throws {
    let parent = try await self.db.create(Parent.random)
    let redirects = [
      "https://example.com/activity",
      "//example.com/activity",
      "/\\example.com/activity",
      "/\t/example.com/activity",
      "javascript:alert(1)",
      "activity",
      "",
    ]

    for redirect in redirects {
      sent.emails = []
      let (token, output) = try await withUUID {
        try await AccountRequestMagicLink.resolve(
          with: .init(email: parent.email.rawValue, redirect: redirect),
          in: self.accountContext,
        )
      }

      expect(output).toEqual(.success)
      expect(self.sent.emails).toHaveCount(1)
      expect(self.sent.emails[0].templateModel["url"]!).toContain("/otp/\(token.lowercased)")
      expect(self.sent.emails[0].templateModel["url"]!).not.toContain("redirect=")
    }
  }
}
