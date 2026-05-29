import Dependencies
import Queues

struct AutomatedMarketingJob: AsyncScheduledJob {
  @Dependency(\.env) var env

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

  func tick() async throws -> [AutomatedMarketingRunResult] {
    var results: [AutomatedMarketingRunResult] = []
    for campaign in automatedMarketingCampaigns(env: self.env) {
      try await results.append(AutomatedMarketingRunner().send(campaign))
    }
    return results
  }
}
