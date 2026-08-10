import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MarketingEmailCampaignRunnerTests: ApiTestCase, @unchecked Sendable {
  func testDryRunLoadsAudienceAndFiltersPriorSends() async throws {
    let slug = "test_automated_marketing_dry_run"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let campaign = TestMarketingEmailCampaign(
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

    let result = try await MarketingEmailCampaignRunner().dryRun(campaign)

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

  func testDryRunLimitOnlyLimitsToSendList() async throws {
    let slug = "test_marketing_email_campaign_dry_run_limit"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let parent3 = try await self.parent()
    let campaign = TestMarketingEmailCampaign(
      slug: slug,
      recipients: [
        .init(parentId: parent1.id, email: parent1.email),
        .init(parentId: parent2.id, email: parent2.email),
        .init(parentId: parent3.id, email: parent3.email),
      ],
    )

    let result = try await MarketingEmailCampaignRunner().dryRun(campaign, limit: 2)

    expect(result.audienceSize).toEqual(3)
    expect(result.eligible).toEqual(3)
    expect(result.toSend).toEqual([parent1.email.rawValue, parent2.email.rawValue])
  }

  func testSendHonorsLimit() async throws {
    let slug = "test_marketing_email_campaign_send_limit"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let parent3 = try await self.parent()
    let campaign = TestMarketingEmailCampaign(
      slug: slug,
      recipients: [
        .init(parentId: parent1.id, email: parent1.email),
        .init(parentId: parent2.id, email: parent2.email),
        .init(parentId: parent3.id, email: parent3.email),
      ],
    )

    let result = try await withDependencies {
      $0.postmark._sendTemplateEmailBatch = { @Sendable emails in
        self.sent.emails.append(contentsOf: emails)
        return .success(emails.map { _ in .success(()) })
      }
    } operation: {
      try await MarketingEmailCampaignRunner().send(campaign, limit: 2)
    }

    expect(result.audienceSize).toEqual(3)
    expect(result.eligible).toEqual(3)
    expect(result.sent).toEqual(2)
    expect(result.failed).toEqual(0)
    expect(result.toSend).toEqual([parent1.email.rawValue, parent2.email.rawValue])
    expect(self.sent.emails.map(\.to)).toEqual([parent1.email.rawValue, parent2.email.rawValue])
    await expect(try self.sends(for: slug).map(\.parentId)).toEqual([parent1.id, parent2.id])
  }

  func testSendUsesMarketingBatchAndRecordsSuccessfulSends() async throws {
    let slug = "test_automated_marketing_send"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let parent3 = try await self.parent()
    let campaign = TestMarketingEmailCampaign(
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
      try await MarketingEmailCampaignRunner().send(campaign)
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
    let campaign = TestMarketingEmailCampaign(
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
      try await MarketingEmailCampaignRunner().send(campaign)
    }

    expect(result.sent).toEqual(1)
    expect(result.failed).toEqual(1)
    expect(self.sent.emails.map(\.to)).toEqual([parent1.email.rawValue, parent2.email.rawValue])
    await expect(try self.sends(for: slug).map(\.parentId)).toEqual([parent1.id])
  }

  func testSendChunksLargeAudienceAndRecordsEarlierSuccessesWhenLaterChunkFails() async throws {
    let slug = "test_automated_marketing_chunked_send"
    let parents = (0 ..< 501).map { index in
      Parent.random(with: { $0.email = "chunked-\(index)@example.com" })
    }
    try await self.db.create(parents)
    let campaign = TestMarketingEmailCampaign(
      slug: slug,
      recipients: parents.map { .init(parentId: $0.id, email: $0.email) },
    )

    let result = try await withDependencies {
      $0.postmark._sendTemplateEmailBatch = { @Sendable emails in
        XCTAssertLessThan(emails.count, 500)
        let isFirstChunk = self.sent.emails.isEmpty
        self.sent.emails.append(contentsOf: emails)
        if isFirstChunk {
          return .success(emails.map { _ in .success(()) })
        } else {
          return .failure(.init(statusCode: 500, errorCode: 500, message: "chunk failed"))
        }
      }
    } operation: {
      try await MarketingEmailCampaignRunner().send(campaign)
    }

    expect(result.audienceSize).toEqual(501)
    expect(result.eligible).toEqual(501)
    expect(result.sent > 0).toBeTrue()
    expect(result.failed > 0).toBeTrue()
    expect(result.sent + result.failed).toEqual(501)
    expect(self.sent.emails.count).toEqual(501)
    await expect(try self.sends(for: slug).count).toEqual(result.sent)
  }

  private func sends(for slug: String) async throws -> [MarketingEmailSend] {
    try await MarketingEmailSend.query()
      .where(.campaign == slug)
      .all(in: self.db)
  }
}

private struct TestMarketingEmailCampaign: MarketingEmailCampaign {
  var slug: String
  var templateAlias = "test-template"
  var from = "Gertrude App <noreply@gertrude.app>"
  var replyTo: String?
  var recipients: [MarketingEmailCampaignRecipient]

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingEmailCampaignRecipient] {
    self.recipients
  }
}
