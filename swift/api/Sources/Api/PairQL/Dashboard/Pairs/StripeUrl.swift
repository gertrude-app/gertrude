import Dependencies
import Foundation
import PairQL
import Vapor
import XStripe

struct StripeUrl: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = Subscription.Tier?

  struct Output: PairOutput {
    var url: String
  }
}

// resolver

extension StripeUrl: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    switch try await context.parent.plan(in: context.db) {
    case .full(.trialing), .full(.trialExpired):
      return try await .init(url: checkoutSessionUrl(tier: .full, in: context))
    case .full(.paid(let stripeId, _)), .full(.overdue(let stripeId, _)):
      return try await .init(url: billingPortalSessionUrl(for: stripeId))
    case .light(.paid(let stripeId, _)), .light(.overdue(let stripeId, _)):
      if let tier = input, tier == .full {
        return try await .init(url: checkoutSessionUrl(tier: .full, in: context))
      }
      return try await .init(url: billingPortalSessionUrl(for: stripeId))
    case .free(let kind):
      if let tier = input {
        return try await .init(url: checkoutSessionUrl(tier: tier, in: context))
      }
      switch kind {
      case .lapsedFull(let stripeId):
        return try await .init(url: billingPortalSessionUrl(for: stripeId))
      case .lapsedLight(let stripeId, _):
        return try await .init(url: billingPortalSessionUrl(for: stripeId))
      case .standard:
        unexpected("92c4365f", context)
        throw Abort(.badRequest)
      }
    case .full(.complimentary):
      unexpected("550e0632", context)
      throw Abort(.badRequest)
    }
  }
}

// helpers

private func checkoutSessionUrl(
  tier: Subscription.Tier,
  in context: ParentContext,
) async throws -> String {
  let sessionData = Stripe.CheckoutSessionData(
    successUrl: "\(context.dashboardUrl)/checkout-success?session_id={CHECKOUT_SESSION_ID}",
    cancelUrl: "\(context.dashboardUrl)/checkout-cancel?session_id={CHECKOUT_SESSION_ID}",
    lineItems: [.init(quantity: 1, priceId: tier.checkoutStripePriceId)],
    mode: .subscription,
    clientReferenceId: context.parent.id.lowercased,
    customerEmail: context.parent.email.rawValue,
    // below params are for no-credit card trials, which we don't do any more
    // since we don't send them to stripe at all when they sign up
    trialPeriodDays: nil,
    trialEndBehavior: nil,
    paymentMethodCollection: nil,
  )

  let session = try await with(dependency: \.stripe)
    .createCheckoutSession(sessionData)

  guard let url = session.url else {
    with(dependency: \.postmark)
      .unexpected("b66e1eaf", "admin: \(context.parent.id)")
    throw Abort(.internalServerError)
  }
  return url
}

private func billingPortalSessionUrl(
  for stripeId: Subscription.StripeId,
) async throws -> String {
  @Dependency(\.stripe) var stripe
  let subscription = try await stripe.getSubscription(stripeId.rawValue)
  let portal = try await stripe.createBillingPortalSession(subscription.customer)
  return portal.url
}

extension Subscription.Tier: PairInput {}
