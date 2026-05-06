import Dependencies
import Foundation
import PairQL
import Vapor
import XStripe

struct UpgradeSubscriptionTier: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var to: Subscription.Tier
  }
}

extension UpgradeSubscriptionTier: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.date.now) var now
    @Dependency(\.stripe) var stripe

    guard var subscription = try await context.parent.subscription(in: context.db) else {
      throw context.error(
        "5d3a8b7c",
        .badRequest,
        user: "No active subscription to upgrade.",
      )
    }

    guard let stripeId = subscription.stripeId?.rawValue else {
      throw context.error(
        "1f2e9c44",
        .badRequest,
        user: "No active Stripe subscription to upgrade.",
      )
    }

    let fromTier = subscription.tier
    guard fromTier == .light, input.to == .full else {
      throw context.error(
        "8a3b9e21",
        .badRequest,
        user: fromTier == input.to
          ? "Already on the requested tier."
          : "Only upgrades from Light to Full are supported.",
      )
    }

    let live = try await stripe.getSubscription(stripeId)
    guard let item = live.items.data.first else {
      unexpected("c14d8f30", context.parent.id)
      throw Abort(.internalServerError)
    }

    let updated = try await stripe.updateSubscription(.init(
      subscriptionId: stripeId,
      itemId: item.id,
      priceId: input.to.checkoutStripePriceId,
    ))

    guard let newStatus = Subscription.StripeStatus(rawValue: updated.status.rawValue),
          newStatus == .active || newStatus == .pastDue else {
      notifyPostUpdateStatusAnomaly(
        parentId: context.parent.id,
        status: updated.status.rawValue,
      )
      throw context.error(
        "f73c2a18",
        .serverError,
        user: "Subscription update returned an unexpected status. Please contact support.",
      )
    }

    let periodEnd = Date(timeIntervalSince1970: TimeInterval(updated.currentPeriodEnd))
    subscription.tier = input.to
    subscription.billingStatus = newStatus.mirroredBillingStatus ?? .paid
    subscription.stripeStatus = newStatus
    subscription.currentPeriodEnd = periodEnd
    subscription.statusExpiresAt = periodEnd + .days(2)
    try await context.db.update(subscription)

    var identity = try await context.parent.ensureBillingIdentity(in: context.db)
    identity.stripeCustomerId = .init(updated.customer)
    identity.lastPaidTier = input.to
    identity.lastStripeSubscriptionId = .init(stripeId)
    try await context.db.update(identity)

    _ = try? await context.db.create(InterestingEvent(
      eventId: "tier_upgraded",
      kind: "billing",
      context: "dash",
      parentId: context.parent.id,
      detail: "from: \(fromTier.rawValue), to: \(input.to.rawValue), "
        + "stripe_sub: \(stripeId)",
    ))

    return .success
  }
}
