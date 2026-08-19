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

  func testSubmissionsAlternateBetweenRotationEmails() async throws {
    let rotation = ["rotate-a@example.com", "rotate-b@example.com"]
    let firstEmail = "first-\(UUID())@example.com"
    let secondEmail = "second-\(UUID())@example.com"

    try await withDependencies {
      $0.env.supportRotationEmails = rotation
    } operation: {
      try await self.submitSiteForm(self.contactFields(email: firstEmail))
      try await self.submitSiteForm(self.contactFields(email: secondEmail))
    }

    let first = try await SiteFormSubmission.query()
      .where(.email == firstEmail)
      .first(in: self.db)
    let second = try await SiteFormSubmission.query()
      .where(.email == secondEmail)
      .first(in: self.db)
    expect(first.assignee).not.toEqual(second.assignee) // consecutive submissions rotate
    expect([first.assignee, second.assignee].sorted()).toEqual(rotation)
  }
}

// helpers

extension SiteFormsRouteTests {
  func contactFields(email: String) -> [String: String] {
    [
      "form": "contact",
      "app": "mac",
      "name": "Jane Doe",
      "email": email,
      "subject": "Help",
      "message": "hi",
      "turnstileToken": "turnstile-token",
    ]
  }

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
