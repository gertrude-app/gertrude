import Dependencies
import Vapor

public struct ScheduledMarketingCampaignDryRunCommand: AsyncCommand {
  public struct Signature: CommandSignature {
    public init() {}
  }

  public init() {}

  public var help: String {
    "Dry-run scheduled marketing campaigns without sending emails or recording sends"
  }

  public func run(using context: CommandContext, signature: Signature) async throws {
    @Dependency(\.env) var env
    for campaign in scheduledMarketingCampaigns(env: env) {
      let result = try await MarketingCampaignRunner().dryRun(campaign)
      context.console.print("campaign: \(result.campaign)")
      context.console.print("audience: \(result.audienceSize)")
      context.console.print("already sent: \(result.alreadySent)")
      context.console.print("eligible: \(result.eligible)")
      context.console.print("would send: \(result.toSend.count)")
      if result.toSend.isEmpty {
        context.console.print("  (none)")
      } else {
        for email in result.toSend {
          context.console.print("  - \(email)")
        }
      }
    }
  }
}
