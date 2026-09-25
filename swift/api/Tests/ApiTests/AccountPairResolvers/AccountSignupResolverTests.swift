import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class AccountSignupResolverTests: ApiTestCase, @unchecked Sendable {
  func testSignupAndVerificationPreservePairingDestination() async throws {
    let email = "pairing".random + "@example.com"
    let context = Context(
      requestId: "signup-test",
      dashboardUrl: "https://account.example",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )

    let signup = try await AccountSignup.resolve(
      with: .init(
        email: email,
        password: "secret",
        redirect: "/connect/blockerSupervise/123456",
        turnstileToken: nil,
      ),
      in: context,
    )
    expect(signup.token).toBeNil()
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].templateModel["dashboardUrl"]).toEqual("https://account.example")
    let token = UUID(uuidString: self.sent.emails[0].templateModel["token"] ?? "")!

    let verified = try await AccountVerifySignupEmail.resolve(
      with: .init(token: token),
      in: context,
    )
    expect(verified.redirect).toEqual("/connect/blockerSupervise/123456")
    expect(verified.token).not.toBeNil()
  }

  func testSignupIgnoresExternalOrUnrecognizedRedirect() async throws {
    let email = "pairing".random + "@example.com"
    let context = Context(
      requestId: "signup-test",
      dashboardUrl: "https://account.example",
      ipAddress: nil,
      telemetry: TelemetryBag(),
    )

    _ = try await AccountSignup.resolve(
      with: .init(
        email: email,
        password: "secret",
        redirect: "//evil.example",
        turnstileToken: nil,
      ),
      in: context,
    )
    let token = UUID(uuidString: self.sent.emails[0].templateModel["token"] ?? "")!
    let verified = try await AccountVerifySignupEmail.resolve(
      with: .init(token: token),
      in: context,
    )
    expect(verified.redirect).toBeNil()
  }
}
