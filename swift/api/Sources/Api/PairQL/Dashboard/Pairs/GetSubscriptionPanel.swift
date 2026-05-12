import Dependencies
import Foundation
import PairQL
import TSCodable

struct GetSubscriptionPanel: Pair {
  static let auth: ClientAuth = .parent

  enum PortalConfig: String, PairNestable {
    case lightTier
    case `default`
  }

  enum SupportReason: String, PairNestable {
    case complimentary
  }

  @TSCodable
  enum Action: Equatable, Sendable {
    case startCheckout(tier: StripeSubscription.Tier)
    case openBillingPortal(config: PortalConfig)
    case upgradeSubscriptionTier(to: StripeSubscription.Tier)
    case reactivateViaCheckout(tier: StripeSubscription.Tier)
    case startFullTrial
    case contactSupport(reason: SupportReason)
  }

  struct BillingState: PairNestable {
    enum Status: String, PairNestable {
      case active
      case pastDue
    }

    var status: Status?
    var currentPeriodEnd: Date?
  }

  struct Output: PairOutput {
    var entitlement: Entitlement
    var billing: BillingState
    var primary: Action?
    var secondary: [Action]
    var availableTiers: [StripeSubscription.Tier]
  }
}

extension GetSubscriptionPanel: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    @Dependency(\.date.now) var now
    let billing = try await context.parent.parentBilling(in: context.db)
    return panelOutput(billing: billing, now: now)
  }
}

func panelOutput(
  billing: ParentBilling,
  now: Date,
) -> GetSubscriptionPanel.Output {
  typealias Action = GetSubscriptionPanel.Action
  let entitlement = billing.entitlement(at: now)
  let identity = billing.identity
  let sub = billing.stripeSubscription

  let billingState = GetSubscriptionPanel.BillingState(
    status: sub.flatMap { sub in
      switch sub.stripeStatus {
      case .active: .active
      case .pastDue: .pastDue
      case .trialing, .unpaid, .canceled, .incomplete, .incompleteExpired: nil
      }
    },
    currentPeriodEnd: sub?.currentPeriodEnd,
  )

  let primary: Action?
  let secondary: [Action]

  switch entitlement {
  case .complimentary:
    primary = nil
    secondary = [.contactSupport(reason: .complimentary)]

  case .full:
    primary = .openBillingPortal(config: .default)
    secondary = []

  case .light:
    if sub?.stripeStatus == .pastDue {
      primary = .openBillingPortal(config: .lightTier)
      secondary = [.upgradeSubscriptionTier(to: .full)]
    } else if identity?.fullTrialStartedAt == nil {
      primary = .upgradeSubscriptionTier(to: .full)
      secondary = [.openBillingPortal(config: .lightTier), .startFullTrial]
    } else {
      primary = .upgradeSubscriptionTier(to: .full)
      secondary = [.openBillingPortal(config: .lightTier)]
    }

  case .fullTrial, .fullTrialGrace:
    if sub?.tier == .light {
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
      secondary = []
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
      case .openBillingPortal, .startFullTrial, .contactSupport:
        break
      }
    }
    return StripeSubscription.Tier.allCases.filter { tiers.contains($0) }
  }()

  return GetSubscriptionPanel.Output(
    entitlement: entitlement,
    billing: billingState,
    primary: primary,
    secondary: secondary,
    availableTiers: availableTiers,
  )
}
