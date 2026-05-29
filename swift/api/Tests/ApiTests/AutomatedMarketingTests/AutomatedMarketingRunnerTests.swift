import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class AutomatedMarketingRunnerTests: ApiTestCase, @unchecked Sendable {
  func testPrepareRecipientsSeparatesAlreadySentFromToSend() {
    let parent1 = Parent.Id(UUID())
    let parent2 = Parent.Id(UUID())
    let parent3 = Parent.Id(UUID())
    let audience = [
      AutomatedMarketingRecipient(parentId: parent1, email: "one@example.com"),
      AutomatedMarketingRecipient(parentId: parent2, email: "two@example.com"),
      AutomatedMarketingRecipient(parentId: parent3, email: "three@example.com"),
    ]
    let priorSends = [MarketingEmailSend(parentId: parent2, campaign: "test_campaign")]

    let prepared = prepareAutomatedMarketingRecipients(
      audience: audience,
      priorSends: priorSends,
    )

    expect(prepared.audience.map(\.parentId)).toEqual([parent1, parent2, parent3])
    expect(prepared.alreadySent.map(\.parentId)).toEqual([parent2])
    expect(prepared.toSend.map(\.parentId)).toEqual([parent1, parent3])
  }

  func testPrepareRecipientsDeduplicatesAudienceByParentKeepingFirst() {
    let parent = Parent.Id(UUID())
    let audience = [
      AutomatedMarketingRecipient(
        parentId: parent,
        email: "first@example.com",
        templateModel: ["version": "first"],
      ),
      AutomatedMarketingRecipient(
        parentId: parent,
        email: "second@example.com",
        templateModel: ["version": "second"],
      ),
    ]

    let prepared = prepareAutomatedMarketingRecipients(
      audience: audience,
      priorSends: [],
    )

    expect(prepared.audience.count).toEqual(1)
    expect(prepared.toSend.count).toEqual(1)
    expect(prepared.toSend[0].email.rawValue).toEqual("first@example.com")
    expect(prepared.toSend[0].templateModel).toEqual(["version": "first"])
  }

  func testDryRunLoadsAudienceAndFiltersPriorSends() async throws {
    let slug = "test_automated_marketing_dry_run"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let campaign = TestAutomatedMarketingCampaign(
      slug: slug,
      recipients: [
        .init(parentId: parent1.id, email: parent1.email),
        .init(parentId: parent2.id, email: parent2.email),
      ],
    )
    _ = try await self.db.create(MarketingEmailSend(
      parentId: parent2.id,
      campaign: slug,
    ))

    let result = try await AutomatedMarketingRunner().dryRun(campaign)

    expect(result).toEqual(.init(
      campaign: slug,
      audienceSize: 2,
      alreadySent: 1,
      eligible: 1,
      sent: 0,
      failed: 0,
      audience: [parent1.email.rawValue, parent2.email.rawValue],
      toSend: [parent1.email.rawValue],
    ))
  }

  func testSendUsesMarketingBatchAndRecordsSuccessfulSends() async throws {
    let slug = "test_automated_marketing_send"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let parent3 = try await self.parent()
    let campaign = TestAutomatedMarketingCampaign(
      slug: slug,
      templateAlias: "test-template-send",
      from: "Jared from Gertrude <jared@gertrude.app>",
      replyTo: "jared@netrivet.com",
      recipients: [
        .init(parentId: parent1.id, email: parent1.email, templateModel: ["name": "One"]),
        .init(parentId: parent2.id, email: parent2.email, templateModel: ["name": "Two"]),
        .init(parentId: parent3.id, email: parent3.email, templateModel: ["name": "Three"]),
      ],
    )
    _ = try await self.db.create(MarketingEmailSend(
      parentId: parent2.id,
      campaign: slug,
    ))

    let result = try await withDependencies {
      $0.postmark._sendTemplateEmailBatch = { @Sendable emails in
        self.sent.emails.append(contentsOf: emails)
        return .success(emails.map { _ in .success(()) })
      }
    } operation: {
      try await AutomatedMarketingRunner().send(campaign)
    }

    expect(result).toEqual(.init(
      campaign: slug,
      audienceSize: 3,
      alreadySent: 1,
      eligible: 2,
      sent: 2,
      failed: 0,
      audience: [parent1.email.rawValue, parent2.email.rawValue, parent3.email.rawValue],
      toSend: [parent1.email.rawValue, parent3.email.rawValue],
    ))
    expect(self.sent.emails.map(\.to)).toEqual([parent1.email.rawValue, parent3.email.rawValue])
    expect(self.sent.emails.map(\.templateAlias)).toEqual([
      "test-template-send",
      "test-template-send",
    ])
    expect(self.sent.emails.map(\.from)).toEqual([
      "Jared from Gertrude <jared@gertrude.app>",
      "Jared from Gertrude <jared@gertrude.app>",
    ])
    expect(self.sent.emails.map(\.replyTo)).toEqual([
      "jared@netrivet.com",
      "jared@netrivet.com",
    ])
    expect(self.sent.emails.map(\.messageStream)).toEqual(["broadcast", "broadcast"])
    expect(self.sent.emails.map(\.tag)).toEqual([slug, slug])
    expect(self.sent.emails[0].templateModel["name"]).toEqual("One")
    expect(self.sent.emails[1].templateModel["name"]).toEqual("Three")
    await expect(try Set(self.sends(for: slug).map(\.parentId))).toEqual(Set([
      parent1.id,
      parent2.id,
      parent3.id,
    ]))
  }

  func testSendRecordsOnlySuccessfulSends() async throws {
    let slug = "test_automated_marketing_partial_failure"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let campaign = TestAutomatedMarketingCampaign(
      slug: slug,
      recipients: [
        .init(parentId: parent1.id, email: parent1.email),
        .init(parentId: parent2.id, email: parent2.email),
      ],
    )

    let result = try await withDependencies {
      $0.postmark._sendTemplateEmailBatch = { @Sendable emails in
        self.sent.emails.append(contentsOf: emails)
        return .success([
          .success(()),
          .failure(.init(errorCode: 10, message: "nope")),
        ])
      }
    } operation: {
      try await AutomatedMarketingRunner().send(campaign)
    }

    expect(result.sent).toEqual(1)
    expect(result.failed).toEqual(1)
    expect(self.sent.emails.map(\.to)).toEqual([parent1.email.rawValue, parent2.email.rawValue])
    await expect(try self.sends(for: slug).map(\.parentId)).toEqual([parent1.id])
  }

  private func sends(for slug: String) async throws -> [MarketingEmailSend] {
    try await MarketingEmailSend.query()
      .where(.campaign == slug)
      .all(in: self.db)
  }
}

private struct TestAutomatedMarketingCampaign: AutomatedMarketingCampaign {
  var slug: String
  var templateAlias = "test-template"
  var from = "Gertrude App <noreply@gertrude.app>"
  var replyTo: String?
  var recipients: [AutomatedMarketingRecipient]

  func audience(in db: any DuetSQL.Client) async throws -> [AutomatedMarketingRecipient] {
    self.recipients
  }
}
