import Dependencies
import Queues

struct ScheduledMarketingEmailCampaignJob: AsyncScheduledJob {
  @Dependency(\.env) var env
  @Dependency(\.logger) var logger
  @Dependency(\.slack) var slack

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    let results = try await self.tick()
    for result in results {
      context.logger
        .info(
          "ScheduledMarketingEmailCampaignJob \(result.campaign): audience=\(result.audienceSize) alreadySent=\(result.alreadySent) eligible=\(result.eligible) sent=\(result.sent) failed=\(result.failed)",
        )
    }
  }

  func tick(
    campaigns: [any MarketingEmailCampaign]? = nil,
  ) async throws -> [MarketingEmailCampaignRunResult] {
    var results: [MarketingEmailCampaignRunResult] = []
    for campaign in campaigns ?? scheduledMarketingEmailCampaigns(env: self.env) {
      do {
        let result = try await MarketingEmailCampaignRunner().send(campaign)
        results.append(result)
      } catch {
        self.logger.error("ScheduledMarketingEmailCampaignJob \(campaign.slug) failed: \(error)")
        await self.slack.error(
          "ScheduledMarketingEmailCampaignJob `\(campaign.slug)` failed: \(String(reflecting: error))")
      }
    }
    return results
  }
}
