import Dependencies
import DuetSQL

struct AutomatedMarketingRecipient: Sendable, Equatable {
  var parentId: Parent.Id
  var email: EmailAddress
  var templateModel: [String: String]

  init(parentId: Parent.Id, email: EmailAddress, templateModel: [String: String] = [:]) {
    self.parentId = parentId
    self.email = email
    self.templateModel = templateModel
  }
}

protocol AutomatedMarketingCampaign: Sendable {
  var slug: String { get }
  var templateAlias: String { get }
  var from: String { get }
  var replyTo: String? { get }

  func audience(in db: any DuetSQL.Client) async throws -> [AutomatedMarketingRecipient]
}

extension AutomatedMarketingCampaign {
  var from: String { "Gertrude App <noreply@gertrude.app>" }
  var replyTo: String? { nil }
}

func automatedMarketingCampaigns(env: Env) -> [any AutomatedMarketingCampaign] {
  [
    MacSetup24hCampaign(dashboardUrl: env.dashboardUrl),
    IosOnlyMacTrialCampaign(),
  ]
}

struct AutomatedMarketingRunResult: Sendable, Equatable {
  var campaign: String
  var audienceSize: Int
  var alreadySent: Int
  var eligible: Int
  var sent: Int
  var failed: Int
  var audience: [String]
  var toSend: [String]
}

struct PreparedAutomatedMarketingRecipients: Sendable, Equatable {
  var audience: [AutomatedMarketingRecipient]
  var alreadySent: [AutomatedMarketingRecipient]
  var toSend: [AutomatedMarketingRecipient]
}

func prepareAutomatedMarketingRecipients(
  audience: [AutomatedMarketingRecipient],
  priorSends: [MarketingEmailSend],
) -> PreparedAutomatedMarketingRecipients {
  let audience = uniqueRecipients(audience)
  let alreadySentParentIds = Set(priorSends.map(\.parentId))
  return .init(
    audience: audience,
    alreadySent: audience.filter { alreadySentParentIds.contains($0.parentId) },
    toSend: audience.filter { !alreadySentParentIds.contains($0.parentId) },
  )
}

struct AutomatedMarketingRunner {
  @Dependency(\.db) var db
  @Dependency(\.postmark) var postmark

  func dryRun(
    _ campaign: any AutomatedMarketingCampaign,
  ) async throws -> AutomatedMarketingRunResult {
    let prepared = try await self.prepare(campaign)
    return self.result(for: campaign, prepared: prepared, sent: 0, failed: 0)
  }

  func send(
    _ campaign: any AutomatedMarketingCampaign,
  ) async throws -> AutomatedMarketingRunResult {
    let prepared = try await self.prepare(campaign)
    guard !prepared.toSend.isEmpty else {
      return self.result(for: campaign, prepared: prepared, sent: 0, failed: 0)
    }

    let results = await self.postmark.sendMarketingBatch(
      templateAlias: campaign.templateAlias,
      campaignSlug: campaign.slug,
      recipients: prepared.toSend.map { ($0.email.rawValue, $0.templateModel) },
      from: campaign.from,
      replyTo: campaign.replyTo,
    )

    var sent = 0
    var failed = 0
    var successRows: [MarketingEmailSend] = []
    for (recipient, result) in zip(prepared.toSend, results) {
      switch result {
      case .success:
        sent += 1
        successRows.append(
          MarketingEmailSend(
            parentId: recipient.parentId,
            campaign: campaign.slug,
          ))
      case .failure:
        failed += 1
      }
    }
    failed += max(0, prepared.toSend.count - results.count)

    if !successRows.isEmpty {
      try await self.db.create(successRows)
    }

    return self.result(for: campaign, prepared: prepared, sent: sent, failed: failed)
  }

  private func prepare(
    _ campaign: any AutomatedMarketingCampaign,
  ) async throws -> PreparedAutomatedMarketingRecipients {
    let audience = try await campaign.audience(in: self.db)
    let priorSends = try await MarketingEmailSend.query()
      .where(.campaign == campaign.slug)
      .all(in: self.db)
    return prepareAutomatedMarketingRecipients(
      audience: audience,
      priorSends: priorSends,
    )
  }

  private func result(
    for campaign: any AutomatedMarketingCampaign,
    prepared: PreparedAutomatedMarketingRecipients,
    sent: Int,
    failed: Int,
  ) -> AutomatedMarketingRunResult {
    .init(
      campaign: campaign.slug,
      audienceSize: prepared.audience.count,
      alreadySent: prepared.alreadySent.count,
      eligible: prepared.toSend.count,
      sent: sent,
      failed: failed,
      audience: prepared.audience.map(\.email.rawValue),
      toSend: prepared.toSend.map(\.email.rawValue),
    )
  }
}

private func uniqueRecipients(
  _ recipients: [AutomatedMarketingRecipient],
) -> [AutomatedMarketingRecipient] {
  var seen = Set<Parent.Id>()
  var unique: [AutomatedMarketingRecipient] = []
  for recipient in recipients where seen.insert(recipient.parentId).inserted {
    unique.append(recipient)
  }
  return unique
}
