import Dependencies
import Foundation
import PairQL
import Vapor
import XStripe

struct StartCheckoutSession: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var tier: StripeSubscription.Tier
    var successPath: String
    var cancelPath: String
    var associatedIosDeviceId: IOSDevice.Id?
  }

  struct Output: PairOutput {
    var url: String
  }
}

extension StartCheckoutSession: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    @Dependency(\.stripe) var stripe

    let billing = try await context.parent.parentBilling(in: context.db)
    if let sub = billing.stripeSubscription, sub.stripeStatus.isLive {
      throw context.error(
        "20de8a91",
        .badRequest,
        user: "An active subscription already exists. Use upgrade instead of checkout.",
      )
    }

    try await context.parent.ensureBillingIdentity(in: context.db)

    let customerId = billing.identity.stripeCustomerId?.rawValue
    let sessionData = Stripe.CheckoutSessionData(
      successUrl: "\(context.dashboardUrl)\(input.successPath)?session_id={CHECKOUT_SESSION_ID}",
      cancelUrl: "\(context.dashboardUrl)\(input.cancelPath)?session_id={CHECKOUT_SESSION_ID}",
      lineItems: [.init(quantity: 1, priceId: input.tier.checkoutStripePriceId)],
      mode: .subscription,
      clientReferenceId: context.parent.id.lowercased,
      customer: customerId,
      customerEmail: customerId == nil ? context.parent.email.rawValue : nil,
      trialPeriodDays: nil,
      trialEndBehavior: nil,
      paymentMethodCollection: nil,
    )

    let session = try await stripe.createCheckoutSession(sessionData)
    guard let url = session.url else {
      with(dependency: \.postmark)
        .unexpected("3b4f9a5d", "admin: \(context.parent.id)")
      throw Abort(.internalServerError)
    }

    Task {
      _ = try? await context.db.create(InterestingEvent(
        eventId: "checkout_initiated",
        kind: "event",
        context: "dash",
        parentId: context.parent.id,
        detail: "tier=\(input.tier)",
      ))

      if let iosDeviceId = input.associatedIosDeviceId,
         let device = try? await context.db.find(iosDeviceId) {
        _ = try? await context.db.create(IOSEvent(
          eventId: "9c7e2dcb",
          kind: .supervision,
          detail: "checkout_initiated, tier=\(input.tier)",
          deviceId: device.id,
          modelIdentifier: device.modelIdentifier,
          iosVersion: device.iosVersion,
        ))
      }
    }

    return .init(url: url)
  }
}
