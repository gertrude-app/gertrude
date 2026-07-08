import Dependencies
import DuetSQL
import XCTest
import XCTVapor
import XExpect
import XStripe

@testable import Api

final class SubscriptionReactivationTests: ApiTestCase, @unchecked Sendable {
  func testAccidentalCancelThenSelfServeReactivationReusesCustomer() async throws {
    let origSubId = "sub_orig_\("".random)"
    let customerId = "cus_\("".random)"
    let parent = try await self.parent()

    let subscribeJson = """
      {
        "id": "evt_subscribe_\("".random)",
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
            "customer_email": "\(parent.email)",
            "customer": "\(customerId)",
            "subscription": "\(origSubId)",
            "lines": {
              "data": [
                { "price": { "id": "\(self.env.stripe.priceIdFull)" } }
              ]
            }
          }
        }
      }
    """

    try await app.test(
      .POST,
      "stripe-events",
      body: .init(string: subscribeJson),
      afterResponse: { res in
        expect(res.status).toEqual(.noContent)
        let sub = try await parent.model.subscription(in: self.db)!
        expect(sub.stripeId.rawValue).toEqual(origSubId)
        expect(sub.tier).toEqual(.full)
        expect(sub.stripeStatus).toEqual(.active)
        let identity = try await parent.model.billingIdentity(in: self.db)!
        expect(identity.stripeCustomerId?.rawValue).toEqual(customerId)
        expect(identity.lastStripeSubscriptionId?.rawValue).toEqual(origSubId)
        expect(identity.lastPaidTier).toEqual(.full)
      },
    )

    let cancelJson = """
      {
        "id": "evt_cancel_\("".random)",
        "type": "customer.subscription.deleted",
        "data": {
          "object": {
            "id": "\(origSubId)",
            "customer": "\(customerId)",
            "status": "canceled"
          }
        }
      }
    """

    try await app.test(
      .POST,
      "stripe-events",
      body: .init(string: cancelJson),
      afterResponse: { res in
        expect(res.status).toEqual(.noContent)
        let sub = try await parent.model.subscription(in: self.db)!
        expect(sub.stripeStatus).toEqual(.canceled)
        let identity = try await parent.model.billingIdentity(in: self.db)!
        expect(identity.stripeCustomerId?.rawValue).toEqual(customerId)
        expect(identity.lastStripeSubscriptionId?.rawValue).toEqual(origSubId)
        expect(identity.lastPaidTier).toEqual(.full)
      },
    )

    let panel = try await GetSubscriptionPanel_v2.resolve(in: context(parent))
    expect(panel.planStatus).toEqual(.free)
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .full))
    expect(panel.secondary).toEqual([
      .reactivateViaCheckout(tier: .medium),
      .reactivateViaCheckout(tier: .light),
    ])

    let checkout = try await withDependencies {
      $0.stripe.createCheckoutSession = { data in
        expect(data.customer).toEqual(customerId)
        expect(data.customerEmail).toBeNil()
        return .init(
          id: "cs_reactivate",
          url: "https://checkout.stripe.test/reactivate",
          subscription: nil,
          clientReferenceId: nil,
        )
      }
    } operation: {
      try await StartCheckoutSession.resolve(
        with: .init(
          tier: .full,
          successPath: "/checkout-success",
          cancelPath: "/checkout-cancel",
          associatedIosDeviceId: nil,
        ),
        in: context(parent),
      )
    }
    expect(checkout.url).toEqual("https://checkout.stripe.test/reactivate")

    let newSubId = "sub_reactivated_\("".random)"
    let reactivateJson = """
      {
        "id": "evt_reactivate_\("".random)",
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
            "customer_email": "\(parent.email)",
            "customer": "\(customerId)",
            "subscription": "\(newSubId)",
            "lines": {
              "data": [
                { "price": { "id": "\(self.env.stripe.priceIdFull)" } }
              ]
            }
          }
        }
      }
    """

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: origSubId, status: .canceled, customer: customerId, currentPeriodEnd: 0)
      }
    } operation: {
      try await app.test(
        .POST,
        "stripe-events",
        body: .init(string: reactivateJson),
        afterResponse: { res in
          expect(res.status).toEqual(.noContent)
          let subs = try await StripeSubscription.query()
            .where(.parentId == parent.id)
            .all(in: self.db)
          expect(subs.count).toEqual(1)
          expect(subs.first?.stripeId.rawValue).toEqual(newSubId)
          expect(subs.first?.tier).toEqual(.full)
          expect(subs.first?.stripeStatus).toEqual(.active)
          let identity = try await parent.model.billingIdentity(in: self.db)!
          expect(identity.stripeCustomerId?.rawValue).toEqual(customerId)
          expect(identity.lastStripeSubscriptionId?.rawValue).toEqual(newSubId)
        },
      )
    }

    let rejected = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string("duplicate_subscription_rejected"))
      .all(in: self.db)
    expect(rejected.count).toEqual(0)

    let overwritten = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string("subscription_overwritten"))
      .all(in: self.db)
    expect(overwritten.count).toEqual(1)

    let alarms = self.sent.slacks.filter { $0.message.channel == "unexpected-errors" }
    expect(alarms.count).toEqual(0)
  }
}
