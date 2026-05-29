import Dependencies
import Vapor

public struct AutomatedMarketingDryRunCommand: AsyncCommand {
  public struct Signature: CommandSignature {
    public init() {}
  }

  public init() {}

  public var help: String {
    "Dry-run automated marketing campaigns without sending emails or recording sends"
  }

  public func run(using context: CommandContext, signature: Signature) async throws {
    @Dependency(\.env) var env
    let campaigns: [any AutomatedMarketingCampaign] = [
      MacSetup24hCampaign(dashboardUrl: env.dashboardUrl),
    ]

    for campaign in campaigns {
      let result = try await AutomatedMarketingRunner().dryRun(campaign)
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
