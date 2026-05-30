import Dependencies
import Queues

struct AutomatedMarketingJob: AsyncScheduledJob {
  @Dependency(\.env) var env
  @Dependency(\.logger) var logger
  @Dependency(\.slack) var slack

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    let results = try await self.tick()
    for result in results {
      context.logger
        .info(
          "AutomatedMarketingJob \(result.campaign): audience=\(result.audienceSize) alreadySent=\(result.alreadySent) eligible=\(result.eligible) sent=\(result.sent) failed=\(result.failed)",
        )
    }
  }

  func tick(
    campaigns: [any AutomatedMarketingCampaign]? = nil,
  ) async throws -> [AutomatedMarketingRunResult] {
    var results: [AutomatedMarketingRunResult] = []
    for campaign in campaigns ?? automatedMarketingCampaigns(env: self.env) {
      do {
        let result = try await AutomatedMarketingRunner().send(campaign)
        results.append(result)
      } catch {
        self.logger.error("AutomatedMarketingJob \(campaign.slug) failed: \(error)")
        await self.slack.error(
          "AutomatedMarketingJob `\(campaign.slug)` failed: \(String(reflecting: error))")
      }
    }
    return results
  }
}
