import Dependencies
import Foundation
import PairQL
import Vapor

struct HandleCheckoutSuccess: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var stripeCheckoutSessionId: String
  }
}

// resolver

extension HandleCheckoutSuccess: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.date.now) var now
    @Dependency(\.stripe) var stripe
    @Dependency(\.slack) var slack
    @Dependency(\.postmark) var postmark

    let session = try await stripe.getCheckoutSession(input.stripeCheckoutSessionId)
    guard let parentId = session.clientReferenceId
      .flatMap(UUID.init(uuidString:))
      .flatMap(Parent.Id.init(rawValue:)) else {
      unexpected("d3f3b1c3", context)
      throw Abort(.badRequest)
    }

    let parent = try await context.db.find(parentId)
    guard let subscriptionId = session.subscription else {
      unexpected("9742cd40", context)
      throw Abort(.badRequest)
    }

    let subscription = try await stripe.getSubscription(subscriptionId)
    guard let priceId = subscription.items.data.first?.price.id else {
      unexpected("10bd2192", context)
      throw Abort(.badRequest)
    }

    guard let tier = Subscription.Tier(stripePriceId: priceId) else {
      unexpected("2958cf22", context)
      throw Abort(.badRequest)
    }

    let expiration = Date(timeIntervalSince1970: TimeInterval(subscription.currentPeriodEnd))
    if var model = try await parent.subscription(in: context.db) {
      switch model.plan {
      case .full(.complimentary):
        unexpected("537d360f", context)
        throw Abort(.badRequest)
      default:
        if model.stripeId == nil {
          notifyFirstPayment(parent: parent, tier: tier)
        } else if model.stripeId?.rawValue != subscriptionId {
          let allow = try await reconcileDuplicateSubscription(
            parent: parent,
            existingSubId: model.stripeId!.rawValue,
            incomingSubId: subscriptionId,
            context: "checkout-success",
            audit: "checkout_session_id: \(input.stripeCheckoutSessionId)",
            db: context.db,
          )
          guard allow else { return .success }
        }
        model.tier = tier
        model.billingStatus = .paid
        model.stripeId = .init(subscriptionId)
        model.stripeStatus = .active
        model.currentPeriodEnd = expiration
        model.statusExpiresAt = expiration + .days(2)
        try await context.db.update(model)
      }
    } else {
      // if they have no subscription record, they were on the free plan
      try await context.db.create(Subscription(
        parentId: parent.id,
        tier: tier,
        billingStatus: .paid,
        stripeId: .init(subscriptionId),
        stripeStatus: .active,
        currentPeriodEnd: expiration,
        statusExpiresAt: expiration + .days(2),
      ))
      notifyFirstPayment(parent: parent, tier: tier)
      // all full subscriptions should have come thru trial state
      if tier != .light { unexpected("d6db1ebc", context) }
    }

    return .success
  }
}
