import Dependencies
import DuetSQL
import XCore
import XCTest
import XExpect

@testable import Api

final class ScheduledMarketingEmailCampaignJobTests: ApiTestCase, @unchecked Sendable {
  func testTickContinuesAfterCampaignFailure() async throws {
    let parent = try await self.parent()
    let successful = SuccessfulMarketingEmailCampaign(
      parentId: parent.id,
      email: parent.email,
    )

    let results = try await withDependencies {
      $0.postmark._sendTemplateEmailBatch = { @Sendable emails in
        self.sent.emails.append(contentsOf: emails)
        return .success(emails.map { _ in .success(()) })
      }
    } operation: {
      try await ScheduledMarketingEmailCampaignJob().tick(campaigns: [
        FailingMarketingEmailCampaign(),
        successful,
      ])
    }

    expect(results.map(\.campaign)).toEqual(["healthy_campaign"])
    expect(self.sent.emails.map(\.to)).toEqual([parent.email.rawValue])
    expect(self.sent.slacks).toHaveCount(1)
    expect(self.sent.slacks[0].message.text).toContain("failing_campaign")
  }

  func testTickSendsMacSetupCampaignAndRecordsSuccessfulSend() async throws {
    var env = Env.fromProcess(mode: .testing)
    env.dashboardUrl = "https://dash.test/"
    try await self.markCurrentAudienceAsAlreadySent(
      MacSetup24hEmailCampaign(dashboardUrl: env.dashboardUrl),
    )

    let now = Date()
    let child = try await self.child(with: \.name, of: "Sarah")
    _ = try await self.db.create(BillingIdentity(
      parentId: child.parent.model.id,
      fullTrialStartedAt: now - .hours(25),
    ))
    try await self.setChildCreatedAt(child.model.id, to: now - .hours(30))

    let results = try await withDependencies {
      $0.env = env
      $0.postmark._sendTemplateEmailBatch = { @Sendable emails in
        self.sent.emails.append(contentsOf: emails)
        return .success(emails.map { _ in .success(()) })
      }
    } operation: {
      try await ScheduledMarketingEmailCampaignJob().tick(campaigns: [
        MacSetup24hEmailCampaign(dashboardUrl: env.dashboardUrl),
      ])
    }

    let result = try XCTUnwrap(results.first { $0.campaign == "mac_setup_24h" })
    expect(results.map(\.campaign)).toEqual(["mac_setup_24h"])
    expect(result.eligible).toEqual(1)
    expect(result.sent).toEqual(1)
    expect(result.failed).toEqual(0)
    expect(result.toSend).toEqual([child.parent.model.email.rawValue])
    expect(result.audience.contains(child.parent.model.email.rawValue)).toEqual(true)
    expect(self.sent.emails.map(\.to)).toEqual([child.parent.model.email.rawValue])
    expect(self.sent.emails.map(\.templateAlias)).toEqual(["mac-setup-24h"])
    expect(self.sent.emails.map(\.messageStream)).toEqual(["broadcast"])
    expect(self.sent.emails.map(\.tag)).toEqual(["mac_setup_24h"])
    expect(self.sent.emails[0].templateModel["childName"]).toEqual("Sarah")
    expect(self.sent.emails[0].templateModel["dashboardUrl"]).toEqual("https://dash.test")
    expect(self.sent.emails[0].templateModel["primaryCtaUrl"]).toEqual(
      "https://dash.test/children/\(child.model.id.lowercased)/mac",
    )

    let sends = try await MarketingEmailSend.query()
      .where(.parentId == child.parent.model.id)
      .where(.campaign == "mac_setup_24h")
      .all(in: self.db)
    expect(sends.count).toEqual(1)
  }

  private func markCurrentAudienceAsAlreadySent(
    _ campaign: any MarketingEmailCampaign,
  ) async throws {
    let audience = try await campaign.audience(in: self.db)
    let prior = try await MarketingEmailSend.query()
      .where(.campaign == campaign.slug)
      .all(in: self.db)
    let priorParentIds = Set(prior.map(\.parentId))
    let sends = audience
      .filter { !priorParentIds.contains($0.parentId) }
      .map { MarketingEmailSend(parentId: $0.parentId, campaign: campaign.slug) }
    if !sends.isEmpty {
      try await self.db.create(sends)
    }
  }

  private func setChildCreatedAt(_ childId: Child.Id, to date: Date) async throws {
    var stmt = SQL.Statement("""
    UPDATE \(table: Child.self) SET \(Child.columnName(.createdAt)) =
    """)
    stmt.components.append(.binding(.date(date)))
    stmt.components.append(.sql(" WHERE \(Child.columnName(.id)) = "))
    stmt.components.append(.binding(.uuid(childId)))
    try await self.db.execute(statement: stmt)
  }
}

private struct FailingMarketingEmailCampaign: MarketingEmailCampaign {
  let slug = "failing_campaign"
  let templateAlias = "failing-template"

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingEmailCampaignRecipient] {
    throw TestCampaignError()
  }
}

private struct SuccessfulMarketingEmailCampaign: MarketingEmailCampaign {
  let slug = "healthy_campaign"
  let templateAlias = "healthy-template"
  let parentId: Parent.Id
  let email: EmailAddress

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingEmailCampaignRecipient] {
    [MarketingEmailCampaignRecipient(parentId: self.parentId, email: self.email)]
  }
}

private struct TestCampaignError: Error {}
