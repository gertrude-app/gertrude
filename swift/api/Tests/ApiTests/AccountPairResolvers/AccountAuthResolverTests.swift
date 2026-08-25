import Foundation
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
