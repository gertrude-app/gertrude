import Dependencies
import Foundation
import PairQL
import Vapor
import XStripe

struct ChangeSubscriptionTier: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var to: StripeSubscription.Tier
  }
}

extension ChangeSubscriptionTier: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.stripe) var stripe

    guard var subscription = try await context.parent.subscription(in: context.db) else {
      throw context.error(
        "5d3a8b7c",
        .badRequest,
        user: "No active subscription to change.",
      )
    }

    let stripeId = subscription.stripeId.rawValue
    let fromTier = subscription.tier
    guard fromTier != input.to else {
      throw context.error(
        "8a3b9e21",
        .badRequest,
        user: "Already on the requested tier.",
      )
    }

    if fromTier == .full {
      guard try await context.parent.canLeaveFullTier(in: context.db) else {
        throw context.error(
          "1d145a5e",
          .badRequest,
          user: "Switching away from Full is only available when no Macs are registered.",
        )
      }
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
      prorationBehavior: .alwaysInvoice,
      paymentBehavior: .errorIfIncomplete,
      billingCycleAnchor: .now,
    ))

    guard let newStatus = StripeSubscription.StripeStatus(rawValue: updated.status.rawValue),
          newStatus == .active || newStatus == .pastDue else {
      notifyPostUpdateStatusAnomaly(context.parent.id, updated.status.rawValue)
      throw context.error(
        "f73c2a18",
        .serverError,
        user: "Subscription update returned an unexpected status. Please contact support.",
      )
    }

    let periodEnd = Date(timeIntervalSince1970: TimeInterval(updated.currentPeriodEnd))
    subscription.tier = input.to
    subscription.stripeStatus = newStatus
    subscription.currentPeriodEnd = periodEnd
    try await context.db.update(subscription)

    var identity = try await context.parent.ensureBillingIdentity(in: context.db)
    identity.stripeCustomerId = .init(updated.customer)
    identity.lastPaidTier = input.to
    identity.lastStripeSubscriptionId = .init(stripeId)
    try await context.db.update(identity)

    _ = try? await context.db.create(InterestingEvent(
      eventId: input.to > fromTier ? "tier_upgraded" : "tier_downgraded",
      kind: "billing",
      context: "dash",
      parentId: context.parent.id,
      detail: "from: \(fromTier.rawValue), to: \(input.to.rawValue), "
        + "stripe_sub: \(stripeId)",
    ))

    notifyTierChange(context.parent, fromTier, input.to)

    return .success
  }
}
