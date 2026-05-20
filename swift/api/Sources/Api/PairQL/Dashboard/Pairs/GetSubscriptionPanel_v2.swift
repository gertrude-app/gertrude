import Dependencies
import Foundation
import PairQL
import TSCodable

struct GetSubscriptionPanel_v2: Pair {
  static let auth: ClientAuth = .parent

  enum PortalConfig: String, PairNestable {
    case lightTier
    case `default`
  }

  @TSCodable
  enum Action: Equatable, Sendable {
    case startCheckout(tier: StripeSubscription.Tier)
    case openBillingPortal(config: PortalConfig)
    case upgradeSubscriptionTier(to: StripeSubscription.Tier)
    case reactivateViaCheckout(tier: StripeSubscription.Tier)
    case startFullTrial
  }

  struct Output: PairOutput {
    var planStatus: PlanStatus
    var primary: Action?
    var secondary: [Action]
    var availableTiers: [StripeSubscription.Tier]
    var fullTrialStartedAt: Date?
    var lastPaidTier: StripeSubscription.Tier?
  }
}

extension GetSubscriptionPanel_v2: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    try await panelOutput_v2(billing: context.currentBillingAccount())
  }
}

func panelOutput_v2(billing: BillingAccountSnapshot) -> GetSubscriptionPanel_v2.Output {
  typealias Action = GetSubscriptionPanel_v2.Action
  let planStatus = billing.planStatus
  let identity = billing.billingIdentity

  let primary: Action?
  let secondary: [Action]

  switch planStatus {
  case .complimentary:
    primary = nil
    secondary = []

  case .full:
    primary = .openBillingPortal(config: .default)
    secondary = []

  case .light(.pastDue):
    primary = .openBillingPortal(config: .lightTier)
    secondary = [.upgradeSubscriptionTier(to: .full)]

  case .light(.current):
    if identity?.fullTrialStartedAt == nil {
      primary = .upgradeSubscriptionTier(to: .full)
      secondary = [.openBillingPortal(config: .lightTier), .startFullTrial]
    } else {
      primary = .upgradeSubscriptionTier(to: .full)
      secondary = [.openBillingPortal(config: .lightTier)]
    }

  case .fullTrial, .fullTrialGrace:
    if billing.stripeSubscription?.tier == .light {
      primary = .upgradeSubscriptionTier(to: .full)
      secondary = [.openBillingPortal(config: .lightTier)]
    } else if identity?.lastStripeSubscriptionId != nil {
      primary = .reactivateViaCheckout(tier: .full)
      secondary = identity?.lastPaidTier == .full
        ? []
        : [.reactivateViaCheckout(tier: .light)]
    } else {
      primary = .startCheckout(tier: .full)
      secondary = [.startCheckout(tier: .light)]
    }

  case .free:
    if identity?.lastStripeSubscriptionId == nil {
      let trialOption: [Action] = identity?.fullTrialStartedAt == nil ? [.startFullTrial] : []
      primary = .startCheckout(tier: .full)
      secondary = [.startCheckout(tier: .light)] + trialOption
    } else if identity?.lastPaidTier == .full {
      primary = .reactivateViaCheckout(tier: .full)
      secondary = [.reactivateViaCheckout(tier: .light)]
    } else {
      primary = .reactivateViaCheckout(tier: .light)
      secondary = [.reactivateViaCheckout(tier: .full)]
    }
  }

  let availableTiers: [StripeSubscription.Tier] = {
    var tiers: Set<StripeSubscription.Tier> = []
    let actions = [primary].compactMap(\.self) + secondary
    for action in actions {
      switch action {
      case .startCheckout(let t),
           .upgradeSubscriptionTier(let t),
           .reactivateViaCheckout(let t):
        tiers.insert(t)
      case .openBillingPortal, .startFullTrial:
        break
      }
    }
    return StripeSubscription.Tier.allCases.filter { tiers.contains($0) }
  }()

  return GetSubscriptionPanel_v2.Output(
    planStatus: planStatus,
    primary: primary,
    secondary: secondary,
    availableTiers: availableTiers,
    fullTrialStartedAt: identity?.fullTrialStartedAt,
    lastPaidTier: identity?.lastPaidTier,
  )
}
