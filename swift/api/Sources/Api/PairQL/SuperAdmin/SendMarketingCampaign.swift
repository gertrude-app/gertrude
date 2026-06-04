import PairQL

struct SendMarketingCampaign: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    let campaign: String
    let dryRun: Bool
    let limit: Int?
  }

  struct Output: PairOutput {
    let audienceSize: Int
    let alreadySent: Int
    let eligible: Int
    let sent: Int
    let failed: Int
    let audience: [String]
    let toSend: [String]

    init(_ result: MarketingCampaignRunResult) {
      self.audienceSize = result.audienceSize
      self.alreadySent = result.alreadySent
      self.eligible = result.eligible
      self.sent = result.sent
      self.failed = result.failed
      self.audience = result.audience
      self.toSend = result.toSend
    }
  }
}

extension SendMarketingCampaign: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    try await self.resolve(
      with: input,
      in: context,
      campaigns: manualMarketingCampaigns(env: context.env),
    )
  }

  static func resolve(
    with input: Input,
    in context: Context,
    campaigns: [any MarketingCampaign],
  ) async throws -> Output {
    if let limit = input.limit, limit < 0 {
      throw context.error(
        "send_marketing_campaign.invalid_limit",
        .badRequest,
        "Manual marketing campaign limit must be non-negative",
      )
    }

    guard let campaign = campaigns.first(where: { $0.slug == input.campaign }) else {
      throw context.error(
        "send_marketing_campaign.unknown_campaign",
        .badRequest,
        "Unknown manual marketing campaign: \(input.campaign)",
      )
    }

    if !input.dryRun, context.env.mode != .prod {
      throw context.error(
        "send_marketing_campaign.non_prod_send",
        .badRequest,
        "Manual marketing campaign sends are only allowed in production",
      )
    }

    let runner = MarketingCampaignRunner()
    let result = if input.dryRun {
      try await runner.dryRun(campaign, limit: input.limit)
    } else {
      try await runner.send(campaign, limit: input.limit)
    }
    return Output(result)
  }
}
