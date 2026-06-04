import Dependencies
import DuetSQL

struct MarketingCampaignRecipient: Sendable, Equatable {
  var parentId: Parent.Id
  var email: EmailAddress
  var templateModel: [String: String]

  init(parentId: Parent.Id, email: EmailAddress, templateModel: [String: String] = [:]) {
    self.parentId = parentId
    self.email = email
    self.templateModel = templateModel
  }
}

protocol MarketingCampaign: Sendable {
  var slug: String { get }
  var templateAlias: String { get }
  var from: String { get }
  var replyTo: String? { get }

  func audience(in db: any DuetSQL.Client) async throws -> [MarketingCampaignRecipient]
}

extension MarketingCampaign {
  var from: String { "Gertrude App <noreply@gertrude.app>" }
  var replyTo: String? { nil }
}

func scheduledMarketingCampaigns(env: Env) -> [any MarketingCampaign] {
  [
    MacSetup24hCampaign(dashboardUrl: env.dashboardUrl),
    IosOnlyMacTrialCampaign(),
  ]
}

func manualMarketingCampaigns(env _: Env) -> [any MarketingCampaign] {
  []
}

struct MarketingCampaignRunResult: Sendable, Equatable {
  var campaign: String
  var audienceSize: Int
  var alreadySent: Int
  var eligible: Int
  var sent: Int
  var failed: Int
  var audience: [String]
  var toSend: [String]
}

struct PreparedMarketingCampaignRecipients: Sendable, Equatable {
  var audience: [MarketingCampaignRecipient]
  var alreadySent: [MarketingCampaignRecipient]
  var toSend: [MarketingCampaignRecipient]
}

func prepareMarketingCampaignRecipients(
  audience: [MarketingCampaignRecipient],
  priorSends: [MarketingEmailSend],
) -> PreparedMarketingCampaignRecipients {
  let audience = uniqueRecipients(audience)
  let alreadySentParentIds = Set(priorSends.map(\.parentId))
  return .init(
    audience: audience,
    alreadySent: audience.filter { alreadySentParentIds.contains($0.parentId) },
    toSend: audience.filter { !alreadySentParentIds.contains($0.parentId) },
  )
}

struct MarketingCampaignRunner {
  @Dependency(\.db) var db
  @Dependency(\.postmark) var postmark

  func dryRun(
    _ campaign: any MarketingCampaign,
    limit: Int? = nil,
  ) async throws -> MarketingCampaignRunResult {
    let prepared = try await self.prepare(campaign)
    return self.result(for: campaign, prepared: prepared, limit: limit, sent: 0, failed: 0)
  }

  func send(
    _ campaign: any MarketingCampaign,
    limit: Int? = nil,
  ) async throws -> MarketingCampaignRunResult {
    let prepared = try await self.prepare(campaign)
    let toSend = self.toSend(from: prepared, limit: limit)
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
    _ campaign: any MarketingCampaign,
  ) async throws -> PreparedMarketingCampaignRecipients {
    let audience = try await campaign.audience(in: self.db)
    let priorSends = try await MarketingEmailSend.query()
      .where(.campaign == campaign.slug)
      .all(in: self.db)
    return prepareMarketingCampaignRecipients(
      audience: audience,
      priorSends: priorSends,
    )
  }

  private func result(
    for campaign: any MarketingCampaign,
    prepared: PreparedMarketingCampaignRecipients,
    limit: Int?,
    sent: Int,
    failed: Int,
  ) -> MarketingCampaignRunResult {
    let toSend = self.toSend(from: prepared, limit: limit)
    return .init(
      campaign: campaign.slug,
      audienceSize: prepared.audience.count,
      alreadySent: prepared.alreadySent.count,
      eligible: prepared.toSend.count,
      sent: sent,
      failed: failed,
      audience: prepared.audience.map(\.email.rawValue),
      toSend: toSend.map(\.email.rawValue),
    )
  }

  private func toSend(
    from prepared: PreparedMarketingCampaignRecipients,
    limit: Int?,
  ) -> [MarketingCampaignRecipient] {
    guard let limit else { return prepared.toSend }
    return Array(prepared.toSend.prefix(max(0, limit)))
  }
}

private func uniqueRecipients(
  _ recipients: [MarketingCampaignRecipient],
) -> [MarketingCampaignRecipient] {
  var seen = Set<Parent.Id>()
  var unique: [MarketingCampaignRecipient] = []
  for recipient in recipients where seen.insert(recipient.parentId).inserted {
    unique.append(recipient)
  }
  return unique
}
