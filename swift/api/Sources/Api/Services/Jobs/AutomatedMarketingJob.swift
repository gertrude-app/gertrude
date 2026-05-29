import Dependencies
import Queues

struct AutomatedMarketingJob: AsyncScheduledJob {
  @Dependency(\.env) var env

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    _ = try await self.tick()
  }

  func tick() async throws -> [AutomatedMarketingRunResult] {
    let macSetup24h = MacSetup24hCampaign(dashboardUrl: self.env.dashboardUrl)
    let result = try await AutomatedMarketingRunner().send(macSetup24h)
    return [result]
  }
}
