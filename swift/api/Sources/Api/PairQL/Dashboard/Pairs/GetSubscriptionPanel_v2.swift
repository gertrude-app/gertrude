import Dependencies
import DuetSQL
import Foundation
import PairQL
import TSCodable

struct GetSubscriptionPanel_v2: Pair {
  static let auth: ClientAuth = .parent

  enum PortalConfig: String, PairNestable {
    case lightTier
    case mediumTier
    case `default`
  }

  @TSCodable
  enum Action: Equatable, Sendable {
    case startCheckout(tier: StripeSubscription.Tier)
    case openBillingPortal(config: PortalConfig)
    case changeSubscriptionTier(to: StripeSubscription.Tier)
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
    let billing = try await context.currentBillingAccount()
    var output = panelOutput_v2(billing: billing)
    let downgrades = try await fullSubscriptionDowngradeActions(
      parent: context.parent,
      billing: billing,
      in: context.db,
    )
    if !downgrades.isEmpty {
      output.secondary.append(contentsOf: downgrades)
      output.availableTiers = availableTiers(
        primary: output.primary,
        secondary: output.secondary,
      )
    }
    return output
  }
}

func fullSubscriptionDowngradeActions(
  parent: Parent,
  billing: BillingAccountSnapshot,
  in db: any DuetSQL.Client,
) async throws -> [GetSubscriptionPanel_v2.Action] {
  guard case .full = billing.planStatus else {
    return []
  }
  return try await parent.canLeaveFullTier(in: db)
    ? [.changeSubscriptionTier(to: .medium), .changeSubscriptionTier(to: .light)]
    : []
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
    secondary = [.changeSubscriptionTier(to: .medium), .changeSubscriptionTier(to: .full)]

  case .light(.current):
    primary = .openBillingPortal(config: .lightTier)
    secondary = identity?.fullTrialStartedAt == nil
      ? [
        .changeSubscriptionTier(to: .medium),
        .changeSubscriptionTier(to: .full),
        .startFullTrial,
      ]
      : [.changeSubscriptionTier(to: .medium), .changeSubscriptionTier(to: .full)]

  case .medium(.pastDue):
    primary = .openBillingPortal(config: .mediumTier)
    secondary = [.changeSubscriptionTier(to: .full), .changeSubscriptionTier(to: .light)]

  case .medium(.current):
    primary = .openBillingPortal(config: .mediumTier)
    secondary = identity?.fullTrialStartedAt == nil
      ? [
        .changeSubscriptionTier(to: .full),
        .changeSubscriptionTier(to: .light),
        .startFullTrial,
      ]
      : [.changeSubscriptionTier(to: .full), .changeSubscriptionTier(to: .light)]

  case .fullTrial(_, let substrate), .fullTrialGrace(_, let substrate):
    if let substrate {
      let portalConfig: GetSubscriptionPanel_v2.PortalConfig = substrate.tier == .light
        ? .lightTier
        : .mediumTier
      switch substrate.status {
      case .current:
        primary = .changeSubscriptionTier(to: .full)
        secondary = substrate.tier == .light
          ? [.openBillingPortal(config: portalConfig), .changeSubscriptionTier(to: .medium)]
          : [.openBillingPortal(config: portalConfig), .changeSubscriptionTier(to: .light)]
      case .pastDue:
        primary = .openBillingPortal(config: portalConfig)
        secondary = substrate.tier == .light
          ? [.changeSubscriptionTier(to: .medium), .changeSubscriptionTier(to: .full)]
          : [.changeSubscriptionTier(to: .full), .changeSubscriptionTier(to: .light)]
      }
    } else if identity?.lastStripeSubscriptionId != nil {
      // trialing Full signals Full interest — lead with it, cheaper tiers step down
      primary = .reactivateViaCheckout(tier: .full)
      secondary = [.reactivateViaCheckout(tier: .medium), .reactivateViaCheckout(tier: .light)]
    } else {
      primary = .startCheckout(tier: .full)
      secondary = [.startCheckout(tier: .medium), .startCheckout(tier: .light)]
    }

  case .free:
    if identity?.lastStripeSubscriptionId == nil {
      let trialOption: [Action] = identity?.fullTrialStartedAt == nil ? [.startFullTrial] : []
      primary = .startCheckout(tier: .light)
      secondary = [.startCheckout(tier: .medium), .startCheckout(tier: .full)] + trialOption
    } else {
      let lastPaid = identity?.lastPaidTier ?? .light
      primary = .reactivateViaCheckout(tier: lastPaid)
      secondary = ladderOrderedReactivations(around: lastPaid)
    }
  }

  return GetSubscriptionPanel_v2.Output(
    planStatus: planStatus,
    primary: primary,
    secondary: secondary,
    availableTiers: availableTiers(primary: primary, secondary: secondary),
    fullTrialStartedAt: identity?.fullTrialStartedAt,
    lastPaidTier: identity?.lastPaidTier,
  )
}

func ladderOrderedReactivations(
  around tier: StripeSubscription.Tier,
) -> [GetSubscriptionPanel_v2.Action] {
  let upgrades = StripeSubscription.Tier.allCases.filter { $0 > tier }
  let downgrades = StripeSubscription.Tier.allCases.filter { $0 < tier }.reversed()
  return (upgrades + downgrades).map { .reactivateViaCheckout(tier: $0) }
}

func availableTiers(
  primary: GetSubscriptionPanel_v2.Action?,
  secondary: [GetSubscriptionPanel_v2.Action],
) -> [StripeSubscription.Tier] {
  var tiers: Set<StripeSubscription.Tier> = []
  let actions = [primary].compactMap(\.self) + secondary
  for action in actions {
    switch action {
    case .startCheckout(let t),
         .changeSubscriptionTier(let t),
         .reactivateViaCheckout(let t):
      tiers.insert(t)
    case .openBillingPortal, .startFullTrial:
      break
    }
  }
  return StripeSubscription.Tier.allCases.filter { tiers.contains($0) }
}
