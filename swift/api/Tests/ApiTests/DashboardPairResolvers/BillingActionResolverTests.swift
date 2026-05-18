import Dependencies
import DuetSQL
import XCTest
import XExpect
import XStripe

@testable import Api

final class BillingActionResolverTests: ApiTestCase, @unchecked Sendable {
  func testUpgradeSubscriptionTierLightToFullSuccess() async throws {
    let stripeId = "sub_upgrade_\("".random)"
    let customerId = "cus_upgrade_\("".random)"
    let parent = try await self.parentWithSubscription(
      identity: BillingIdentity(
        parentId: .init(),
        stripeCustomerId: .init(customerId),
        lastStripeSubscriptionId: .init(stripeId),
        lastPaidTier: .light,
      ),
    ) { _, sub in
      sub.tier = .light
      sub.stripeId = .init(stripeId)
      sub.stripeStatus = .active
    }

    let output = try await withDependencies {
      $0.stripe.getSubscription = { id in
        expect(id).toEqual(stripeId)
        return .init(
          id: stripeId,
          status: .active,
          customer: customerId,
          currentPeriodEnd: 0,
          items: [.init(id: "si_42", price: .init(id: "price_old"))],
        )
      }
      $0.stripe.updateSubscription = { data in
        expect(data.subscriptionId).toEqual(stripeId)
        expect(data.itemId).toEqual("si_42")
        expect(data.priceId).toEqual(StripeSubscription.Tier.full.checkoutStripePriceId)
        expect(data.prorationBehavior).toEqual(.alwaysInvoice)
        expect(data.paymentBehavior).toEqual(.errorIfIncomplete)
        expect(data.billingCycleAnchor).toEqual(.now)
        return .init(
          id: stripeId,
          status: .active,
          customer: customerId,
          currentPeriodEnd: Int(Date.reference.addingTimeInterval(.days(30)).timeIntervalSince1970),
          items: [.init(id: "si_42", price: .init(id: data.priceId))],
        )
      }
    } operation: {
      try await UpgradeSubscriptionTier.resolve(
        with: .init(to: .full),
        in: context(parent.model),
      )
    }

    expect(output).toEqual(.success)
    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.tier).toEqual(.full)
    expect(sub.stripeStatus).toEqual(.active)

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.lastPaidTier).toEqual(.full)
    expect(identity.lastStripeSubscriptionId?.rawValue).toEqual(stripeId)

    let events = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .all(in: self.db)
    expect(events.contains { $0.eventId == "tier_upgraded" }).toBeTrue()
  }

  func testUpgradeSubscriptionTierAlertsAndFailsOnBadStatus() async throws {
    let stripeId = "sub_upgrade_\("".random)"
    let customerId = "cus_upgrade_\("".random)"
    let parent = try await self.parentWithSubscription(
      identity: BillingIdentity(
        parentId: .init(),
        stripeCustomerId: .init(customerId),
        lastStripeSubscriptionId: .init(stripeId),
        lastPaidTier: .light,
      ),
    ) { _, sub in
      sub.tier = .light
      sub.stripeId = .init(stripeId)
      sub.stripeStatus = .active
    }

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(
          id: stripeId,
          status: .active,
          customer: customerId,
          currentPeriodEnd: 0,
          items: [.init(id: "si_42", price: .init(id: "price_old"))],
        )
      }
      $0.stripe.updateSubscription = { _ in
        .init(
          id: stripeId,
          status: .incomplete,
          customer: customerId,
          currentPeriodEnd: 0,
          items: [.init(id: "si_42", price: .init(id: "price_new"))],
        )
      }
    } operation: { [self] in
      try await expectErrorFrom { [self] in
        try await UpgradeSubscriptionTier.resolve(
          with: .init(to: .full),
          in: context(parent.model),
        )
      }.toContain("unexpected status")
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.tier).toEqual(.light)

    let alarms = self.sent.slacks.filter { $0.message.channel == "unexpected-errors" }
    expect(alarms.contains { $0.message.text.contains("Post-update status anomaly") }).toBeTrue()
  }

  func testUpgradeSubscriptionTierRejectsAlreadyOnTier() async throws {
    let stripeId = "sub_upgrade_\("".random)"
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .full
      sub.stripeId = .init(stripeId)
    }

    try await expectErrorFrom { [self] in
      try await UpgradeSubscriptionTier.resolve(
        with: .init(to: .full),
        in: context(parent.model),
      )
    }.toContain("Already on the requested tier")
  }

  func testUpgradeSubscriptionTierRejectsDownConversion() async throws {
    let stripeId = "sub_upgrade_\("".random)"
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .full
      sub.stripeId = .init(stripeId)
    }

    try await expectErrorFrom { [self] in
      try await UpgradeSubscriptionTier.resolve(
        with: .init(to: .light),
        in: context(parent.model),
      )
    }.toContain("Only upgrades from Light to Full are supported")
  }

  func testUpgradeSubscriptionTierMirrorsPastDueBillingStatus() async throws {
    let stripeId = "sub_upgrade_\("".random)"
    let customerId = "cus_upgrade_\("".random)"
    let parent = try await self.parentWithSubscription(
      identity: BillingIdentity(
        parentId: .init(),
        stripeCustomerId: .init(customerId),
        lastStripeSubscriptionId: .init(stripeId),
        lastPaidTier: .light,
      ),
    ) { _, sub in
      sub.tier = .light
      sub.stripeId = .init(stripeId)
      sub.stripeStatus = .active
    }

    _ = try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(
          id: stripeId,
          status: .active,
          customer: customerId,
          currentPeriodEnd: 0,
          items: [.init(id: "si_42", price: .init(id: "price_old"))],
        )
      }
      $0.stripe.updateSubscription = { _ in
        .init(
          id: stripeId,
          status: .pastDue,
          customer: customerId,
          currentPeriodEnd: Int(Date.reference.addingTimeInterval(.days(30)).timeIntervalSince1970),
          items: [.init(id: "si_42", price: .init(id: "price_new"))],
        )
      }
    } operation: {
      try await UpgradeSubscriptionTier.resolve(
        with: .init(to: .full),
        in: context(parent.model),
      )
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.tier).toEqual(.full)
    expect(sub.stripeStatus).toEqual(.pastDue)
  }

  func testUpgradeSubscriptionTierRejectsWithoutSubscription() async throws {
    let parent = try await self.parent()
    try await expectErrorFrom { [self] in
      try await UpgradeSubscriptionTier.resolve(
        with: .init(to: .full),
        in: context(parent.model),
      )
    }.toContain("No active subscription to upgrade")
  }

  func testOpenBillingPortalWiresReturnUrlToStripe() async throws {
    let customerId = "cus_portal_\("".random)"
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init(customerId),
      lastStripeSubscriptionId: .init("sub_test"),
      lastPaidTier: .full,
    ))

    let output = try await withDependencies {
      $0.stripe.createBillingPortalSession = { cusId, configuration, returnUrl in
        expect(cusId).toEqual(customerId)
        expect(configuration).toBeNil()
        expect(returnUrl).toEqual("/settings")
        return .init(id: "bps_test", url: "https://billing.stripe.com/test")
      }
    } operation: {
      try await OpenBillingPortal.resolve(
        with: .init(returnPath: "/settings", configuration: .default),
        in: context(parent),
      )
    }

    expect(output.url).toEqual("https://billing.stripe.com/test")
  }

  func testOpenBillingPortalLightTierConfigurationIsPassed() async throws {
    let customerId = "cus_portal_\("".random)"
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init(customerId),
      lastStripeSubscriptionId: .init("sub_test"),
      lastPaidTier: .light,
    ))

    _ = try await withDependencies {
      $0.stripe.createBillingPortalSession = { _, configuration, _ in
        expect(configuration).toEqual(self.env.stripe.portalConfigIdLightTier)
        return .init(id: "bps_test", url: "https://billing.stripe.com/test")
      }
    } operation: {
      try await OpenBillingPortal.resolve(
        with: .init(returnPath: "/settings", configuration: .lightTier),
        in: context(parent),
      )
    }
  }

  func testOpenBillingPortalRejectsWithoutCustomer() async throws {
    let parent = try await self.parent()
    try await expectErrorFrom { [self] in
      try await OpenBillingPortal.resolve(
        with: .init(returnPath: "/settings", configuration: .default),
        in: context(parent),
      )
    }.toContain("No Stripe customer")
  }

  func testStartCheckoutSessionRejectsWhenLiveStripeSubExists() async throws {
    for status: StripeSubscription.StripeStatus in [.trialing, .active] {
      let parent = try await self.parentWithSubscription { _, sub in
        sub.tier = .full
        sub.stripeId = .init("sub_live_\("".random)")
        sub.stripeStatus = status
      }

      try await expectErrorFrom { [self] in
        try await StartCheckoutSession.resolve(
          with: .init(
            tier: .full,
            successPath: "/settings",
            cancelPath: "/settings",
            associatedIosDeviceId: nil,
          ),
          in: context(parent.model),
        )
      }.toContain("active subscription already exists")
    }
  }
}
