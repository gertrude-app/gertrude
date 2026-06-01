import Dependencies
import Queues

struct ScheduledMarketingCampaignJob: AsyncScheduledJob {
  @Dependency(\.env) var env
  @Dependency(\.logger) var logger
  @Dependency(\.slack) var slack

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    let results = try await self.tick()
    for result in results {
      context.logger
        .info(
          "ScheduledMarketingCampaignJob \(result.campaign): audience=\(result.audienceSize) alreadySent=\(result.alreadySent) eligible=\(result.eligible) sent=\(result.sent) failed=\(result.failed)",
        )
    }
  }

  func tick(
    campaigns: [any MarketingCampaign]? = nil,
  ) async throws -> [MarketingCampaignRunResult] {
    var results: [MarketingCampaignRunResult] = []
    for campaign in campaigns ?? scheduledMarketingCampaigns(env: self.env) {
      do {
        let result = try await MarketingCampaignRunner().send(campaign)
        results.append(result)
      } catch {
        self.logger.error("ScheduledMarketingCampaignJob \(campaign.slug) failed: \(error)")
        await self.slack.error(
          "ScheduledMarketingCampaignJob `\(campaign.slug)` failed: \(String(reflecting: error))")
      }
    }
    return results
  }
}
