import Dependencies
import DuetSQL
import Foundation
import PairQL
import XCTest
import XExpect

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@testable import Api

final class SendMarketingEmailCampaignTests: ApiTestCase, @unchecked Sendable {
  func testRouteParses() throws {
    let token = UUID(uuidString: "deadbeef-dead-beef-dead-beefdeadbeef")!
    let input = SendMarketingEmailCampaign.Input(campaign: "launch", dryRun: true, limit: 10)
    var request = URLRequest(url: URL(string: "super-admin/SendMarketingEmailCampaign")!)
    request.httpMethod = "POST"
    request.addValue(token.uuidString, forHTTPHeaderField: "X-SuperAdminToken")
    request.httpBody = try JSONEncoder().encode(input)

    let matched = try PairQLRoute.router.match(request: request)

    expect(matched).toEqual(.superAdmin(.authed(token, .sendMarketingEmailCampaign(input))))
  }

  func testDryRunUsesRegisteredManualCampaignBySlug() async throws {
    let slug = "test_manual_marketing_dry_run"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let campaign = TestManualMarketingEmailCampaign(
      slug: slug,
      recipients: [
        .init(parentId: parent1.id, email: parent1.email),
        .init(parentId: parent2.id, email: parent2.email),
      ],
    )

    let output = try await SendMarketingEmailCampaign.resolve(
      with: .init(campaign: slug, dryRun: true, limit: 1),
      in: .mock,
      campaigns: [campaign],
    )

    expect(output.audienceSize).toEqual(2)
    expect(output.alreadySent).toEqual(0)
    expect(output.eligible).toEqual(2)
    expect(output.sent).toEqual(0)
    expect(output.failed).toEqual(0)
    expect(output.audience).toEqual([parent1.email.rawValue, parent2.email.rawValue])
    expect(output.toSend).toEqual([parent1.email.rawValue])
    expect(self.sent.emails).toHaveCount(0)
    await expect(try self.marketingEmailSends(for: slug)).toHaveCount(0)
  }

  func testSendUsesRegisteredManualCampaignBySlug() async throws {
    let slug = "test_manual_marketing_send"
    let parent1 = try await self.parent()
    let parent2 = try await self.parent()
    let campaign = TestManualMarketingEmailCampaign(
      slug: slug,
      templateAlias: "manual-template",
      from: "Jared from Gertrude <jared@gertrude.app>",
      replyTo: "jared@netrivet.com",
      recipients: [
        .init(parentId: parent1.id, email: parent1.email, templateModel: ["name": "One"]),
        .init(parentId: parent2.id, email: parent2.email, templateModel: ["name": "Two"]),
      ],
    )

    var env = self.env
    env.mode = .prod

    let output = try await withDependencies {
      $0.env = env
      $0.postmark._sendTemplateEmailBatch = { @Sendable emails in
        self.sent.emails.append(contentsOf: emails)
        return .success(emails.map { _ in .success(()) })
      }
    } operation: {
      try await SendMarketingEmailCampaign.resolve(
        with: .init(campaign: slug, dryRun: false, limit: 1),
        in: .mock,
        campaigns: [campaign],
      )
    }

    expect(output.audienceSize).toEqual(2)
    expect(output.eligible).toEqual(2)
    expect(output.sent).toEqual(1)
    expect(output.failed).toEqual(0)
    expect(output.toSend).toEqual([parent1.email.rawValue])
    expect(self.sent.emails.map(\.to)).toEqual([parent1.email.rawValue])
    expect(self.sent.emails.map(\.templateAlias)).toEqual(["manual-template"])
    expect(self.sent.emails.map(\.from)).toEqual(["Jared from Gertrude <jared@gertrude.app>"])
    expect(self.sent.emails.map(\.replyTo)).toEqual(["jared@netrivet.com"])
    expect(self.sent.emails.map(\.messageStream)).toEqual(["broadcast"])
    expect(self.sent.emails.map(\.tag)).toEqual([slug])
    expect(self.sent.emails[0].templateModel["name"]).toEqual("One")
    await expect(try self.marketingEmailSends(for: slug).map(\.parentId)).toEqual([parent1.id])
  }

  func testRealSendOutsideProdThrowsBadRequest() async throws {
    let slug = "test_manual_marketing_non_prod_send"
    let parent = try await self.parent()
    let campaign = TestManualMarketingEmailCampaign(
      slug: slug,
      recipients: [.init(parentId: parent.id, email: parent.email)],
    )

    do {
      _ = try await withDependencies {
        $0.postmark._sendTemplateEmailBatch = { @Sendable _ in
          XCTFail("expected no email send")
          return .success([])
        }
      } operation: {
        try await SendMarketingEmailCampaign.resolve(
          with: .init(campaign: slug, dryRun: false, limit: nil),
          in: .mock,
          campaigns: [campaign],
        )
      }
      XCTFail("expected non-prod send error")
    } catch let error as PqlError {
      expect(error.id).toEqual("send_marketing_email_campaign.non_prod_send")
      expect(error.type).toEqual(.badRequest)
    }

    expect(self.sent.emails).toHaveCount(0)
    await expect(try self.marketingEmailSends(for: slug)).toHaveCount(0)
  }

  func testUnknownManualCampaignThrowsBadRequest() async throws {
    do {
      _ = try await SendMarketingEmailCampaign.resolve(
        with: .init(campaign: "unknown", dryRun: true, limit: nil),
        in: .mock,
        campaigns: [],
      )
      XCTFail("expected unknown campaign error")
    } catch let error as PqlError {
      expect(error.id).toEqual("send_marketing_email_campaign.unknown_campaign")
      expect(error.type).toEqual(.badRequest)
    }
  }

  func testNegativeLimitThrowsBadRequest() async throws {
    do {
      _ = try await SendMarketingEmailCampaign.resolve(
        with: .init(campaign: "test", dryRun: true, limit: -1),
        in: .mock,
        campaigns: [TestManualMarketingEmailCampaign(slug: "test", recipients: [])],
      )
      XCTFail("expected invalid limit error")
    } catch let error as PqlError {
      expect(error.id).toEqual("send_marketing_email_campaign.invalid_limit")
      expect(error.type).toEqual(.badRequest)
    }
  }
}

private struct TestManualMarketingEmailCampaign: MarketingEmailCampaign {
  var slug: String
  var templateAlias = "test-manual-template"
  var from = "Gertrude App <noreply@gertrude.app>"
  var replyTo: String?
  var recipients: [MarketingEmailCampaignRecipient]

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingEmailCampaignRecipient] {
    self.recipients
  }
}
