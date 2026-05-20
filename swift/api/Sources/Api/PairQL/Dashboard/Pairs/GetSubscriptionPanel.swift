import Dependencies
import Foundation
import PairQL
import TSCodable

/// @deprecated safe to remove 2026-06-05
struct GetSubscriptionPanel: Pair {
  static let auth: ClientAuth = .parent

  enum BillingStatusV1: String, Codable, Equatable, Sendable {
    case current
    case pastDue
  }

  @TSCodable
  enum PlanStatusV1: Equatable, Sendable {
    case free
    case light(status: BillingStatusV1)
    case full(status: BillingStatusV1)
    case fullTrial(until: Date)
    case fullTrialGrace(until: Date)
    case complimentary
  }

  struct Output: PairOutput {
    var planStatus: PlanStatusV1
    var currentPeriodEnd: Date?
    var primary: GetSubscriptionPanel_v2.Action?
    var secondary: [GetSubscriptionPanel_v2.Action]
    var availableTiers: [StripeSubscription.Tier]
    var fullTrialStartedAt: Date?
    var lastPaidTier: StripeSubscription.Tier?
  }
}

extension GetSubscriptionPanel.PlanStatusV1 {
  init(_ status: PlanStatus) {
    switch status {
    case .free: self = .free
    case .light(.current): self = .light(status: .current)
    case .light(.pastDue): self = .light(status: .pastDue)
    case .full(.current): self = .full(status: .current)
    case .full(.pastDue): self = .full(status: .pastDue)
    case .fullTrial(let until): self = .fullTrial(until: until)
    case .fullTrialGrace(let until): self = .fullTrialGrace(until: until)
    case .complimentary: self = .complimentary
    }
  }
}

extension GetSubscriptionPanel: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    await context.db.logDeprecated("GetSubscriptionPanel(v1)")
    let billing = try await context.currentBillingAccount()
    let panel = panelOutput_v2(billing: billing)
    return Output(
      planStatus: PlanStatusV1(panel.planStatus),
      currentPeriodEnd: billing.stripeSubscription?.currentPeriodEnd,
      primary: panel.primary,
      secondary: panel.secondary,
      availableTiers: panel.availableTiers,
      fullTrialStartedAt: panel.fullTrialStartedAt,
      lastPaidTier: panel.lastPaidTier,
    )
  }
}
