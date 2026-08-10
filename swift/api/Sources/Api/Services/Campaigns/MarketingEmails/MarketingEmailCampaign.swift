import Dependencies
import DuetSQL

struct MarketingEmailCampaignRecipient: Sendable, Equatable {
  var parentId: Parent.Id
  var email: EmailAddress
  var templateModel: [String: String]

  init(parentId: Parent.Id, email: EmailAddress, templateModel: [String: String] = [:]) {
    self.parentId = parentId
    self.email = email
    self.templateModel = templateModel
  }
}

protocol MarketingEmailCampaign: Sendable {
  var slug: String { get }
  var templateAlias: String { get }
  var variant: String { get }
  var from: String { get }
  var replyTo: String? { get }

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingEmailCampaignRecipient]
}

extension MarketingEmailCampaign {
  var variant: String { "v1" }
  var from: String { "Gertrude App <noreply@gertrude.app>" }
  var replyTo: String? { nil }
}

func scheduledMarketingEmailCampaigns(env: Env) -> [any MarketingEmailCampaign] {
  [
    MacSetup24hEmailCampaign(dashboardUrl: env.dashboardUrl),
    IosOnlyMacTrialEmailCampaign(),
  ]
}

func manualMarketingEmailCampaigns(env _: Env) -> [any MarketingEmailCampaign] {
  [IosOnlyMacTrialEmailCampaign()]
}

struct MarketingEmailCampaignRunResult: Sendable, Equatable {
  var campaign: String
  var audienceSize: Int
  var alreadySent: Int
  var eligible: Int
  var sent: Int
  var failed: Int
  var audience: [String]
  var toSend: [String]
}

struct MarketingEmailCampaignRunner {
  @Dependency(\.db) var db
  @Dependency(\.postmark) var postmark

  func dryRun(
    _ campaign: any MarketingEmailCampaign,
    limit: Int? = nil,
  ) async throws -> MarketingEmailCampaignRunResult {
    let prepared = try await self.prepare(campaign)
    return self.result(for: campaign, prepared: prepared, limit: limit, sent: 0, failed: 0)
  }

  func send(
    _ campaign: any MarketingEmailCampaign,
    limit: Int? = nil,
  ) async throws -> MarketingEmailCampaignRunResult {
    let prepared = try await self.prepare(campaign)
    let toSend = prepared.selectedRecipients(limit: limit)
    guard !toSend.isEmpty else {
      return self.result(for: campaign, prepared: prepared, limit: limit, sent: 0, failed: 0)
    }

    let results = await self.postmark.sendMarketingBatch(
      templateAlias: campaign.templateAlias,
      campaignSlug: campaign.slug,
      recipients: toSend.map { ($0.email.rawValue, $0.templateModel) },
      from: campaign.from,
      replyTo: campaign.replyTo,
    )

    var sent = 0
    var failed = 0
    var successRows: [MarketingEmailSend] = []
    for (recipient, result) in zip(toSend, results) {
      switch result {
      case .success:
        sent += 1
        successRows.append(
          MarketingEmailSend(
            parentId: recipient.parentId,
            campaign: campaign.slug,
            variant: campaign.variant,
          ))
      case .failure:
        failed += 1
      }
    }
    failed += max(0, toSend.count - results.count)

    if !successRows.isEmpty {
      try await self.db.create(successRows)
    }

    return self.result(for: campaign, prepared: prepared, limit: limit, sent: sent, failed: failed)
  }

  private func prepare(
    _ campaign: any MarketingEmailCampaign,
  ) async throws -> PreparedCampaignAudience<MarketingEmailCampaignRecipient> {
    let audience = try await campaign.audience(in: self.db)
    let deliveredParentIds = try await Set(
      MarketingEmailSend.query()
        .where(.campaign == campaign.slug)
        .all(in: self.db)
        .map(\.parentId),
    )
    return prepareCampaignAudience(
      audience: audience,
      deliveredIds: deliveredParentIds,
      identifiedBy: \.parentId,
    )
  }

  private func result(
    for campaign: any MarketingEmailCampaign,
    prepared: PreparedCampaignAudience<MarketingEmailCampaignRecipient>,
    limit: Int?,
    sent: Int,
    failed: Int,
  ) -> MarketingEmailCampaignRunResult {
    let toSend = prepared.selectedRecipients(limit: limit)
    return .init(
      campaign: campaign.slug,
      audienceSize: prepared.audience.count,
      alreadySent: prepared.alreadyDelivered.count,
      eligible: prepared.eligible.count,
      sent: sent,
      failed: failed,
      audience: prepared.audience.map(\.email.rawValue),
      toSend: toSend.map(\.email.rawValue),
    )
  }
}
