import Dependencies
import DuetSQL
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class SiteFormsRouteTests: ApiTestCase, @unchecked Sendable {
  func testContactSubmissionPersistedAndLinkedToParent() async throws {
    let parent = try await self.parent().model
    let email = parent.email.rawValue.uppercased() // route normalizes before parent lookup

    try await self.submitSiteForm([
      "form": "contact",
      "app": "music",
      "name": "Jane Doe",
      "email": email,
      "subject": "Pricing question",
      "message": "How much per device?",
      "turnstileToken": "turnstile-token",
    ])

    let submission = try await SiteFormSubmission.query()
      .where(.email == email)
      .first(in: self.db)

    expect(submission.form).toEqual(.contact)
    expect(submission.app).toEqual(.music)
    expect(submission.name).toEqual("Jane Doe")
    expect(submission.email).toEqual(email) // stored as submitted, not normalized
    expect(submission.subject).toEqual("Pricing question")
    expect(submission.message).toEqual("How much per device?")
    expect(submission.parentId).toEqual(parent.id) // links via email
  }
}

// helpers

extension SiteFormsRouteTests {
  func submitSiteForm(_ fields: [String: String]) async throws {
    let body = fields
      .map { "\($0)=\($1.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)" }
      .joined(separator: "&")
    try await withDependencies {
      $0.cloudflare.verifyTurnstileToken = { _ in .success }
      $0.postmark._sendEmail = { _ in .success(()) }
    } operation: {
      try await self.app.test(
        .POST,
        "site-forms",
        beforeRequest: { (req: inout XCTHTTPRequest) async throws in
          req.headers.contentType = .urlEncodedForm
          req.body = ByteBuffer(string: body)
        },
        afterResponse: { (res: XCTHTTPResponse) async throws in
          expect(res.status).toEqual(.ok)
        },
      )
    }
  }
}
