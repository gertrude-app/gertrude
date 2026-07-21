import Foundation
import XCTest
import XExpect

@testable import Api

final class SubscriptionPanelTests: DependencyTestCase {
  typealias Action = GetSubscriptionPanel_v2.Action

  // MARK: - free, no history

  func testFreeStandardLeadsWithLightNotFull() {
    let billing = self.billing()
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.free)
    expect(panel.primary).toEqual(.startCheckout(tier: .light)) // next rung up, not the top
    expect(panel.secondary).toEqual([
      .startCheckout(tier: .medium),
      .startCheckout(tier: .full),
      .startFullTrial,
    ])
  }

  func testFreeStandardWithUsedTrialOmitsTrialOption() {
    let billing = self.billing(trialStartedAt: .reference - .days(60))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.startCheckout(tier: .light))
    expect(panel.secondary).toEqual([
      .startCheckout(tier: .medium),
      .startCheckout(tier: .full),
    ])
  }

  // MARK: - free, lapsed

  func testFreeLapsedLightReactivatesEitherTier() {
    let billing = self.billing(lastSubId: "sub_old", lastPaidTier: .light)
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .light))
    expect(panel.secondary).toEqual([ // upgrades ascending
      .reactivateViaCheckout(tier: .medium),
      .reactivateViaCheckout(tier: .full),
    ])
  }

  func testFreeLapsedFullOffersBothTiersForReactivation() {
    let billing = self.billing(lastSubId: "sub_old", lastPaidTier: .full)
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .full))
    expect(panel.secondary).toEqual([
      .reactivateViaCheckout(tier: .medium),
      .reactivateViaCheckout(tier: .light),
    ])
  }

  func testFreeLapsedMediumReactivatesMediumPrimary() {
    let billing = self.billing(lastSubId: "sub_old", lastPaidTier: .medium)
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .medium))
    expect(panel.secondary).toEqual([
      .reactivateViaCheckout(tier: .full),
      .reactivateViaCheckout(tier: .light),
    ])
  }

  // MARK: - light tier

  func testLightPaidLeadsWithManageNotUpgrade() {
    let billing = self.billing(sub: (tier: .light, status: .active))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.light(status: .current(renewsAt: .reference + .days(30))))
    expect(panel.primary).toEqual(.openBillingPortal(config: .lightTier)) // manage, not upsell
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .medium), // upgrades ascending
      .changeSubscriptionTier(to: .full),
      .startFullTrial,
    ])
  }

  func testLightPaidWithUsedTrialOmitsTrialOption() {
    let billing = self.billing(
      trialStartedAt: .reference - .days(60),
      sub: (tier: .light, status: .active),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.openBillingPortal(config: .lightTier))
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .medium),
      .changeSubscriptionTier(to: .full),
    ])
  }

  func testLightOverdueOffersPortalThenUpgrade() {
    let billing = self.billing(sub: (tier: .light, status: .pastDue))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.openBillingPortal(config: .lightTier))
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .medium),
      .changeSubscriptionTier(to: .full),
    ])
  }

  // MARK: - medium tier

  func testMediumPaidLeadsWithManageNotUpgrade() {
    let billing = self.billing(sub: (tier: .medium, status: .active))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.medium(status: .current(renewsAt: .reference + .days(30))))
    expect(panel.primary).toEqual(.openBillingPortal(config: .mediumTier)) // manage, not upsell
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .full), // upgrade
      .changeSubscriptionTier(to: .light), // downgrade
      .startFullTrial,
    ])
  }

  func testMediumPaidWithUsedTrialOmitsTrialOption() {
    let billing = self.billing(
      trialStartedAt: .reference - .days(60),
      sub: (tier: .medium, status: .active),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.openBillingPortal(config: .mediumTier))
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .full),
      .changeSubscriptionTier(to: .light),
    ])
  }

  func testMediumOverdueOffersPortalThenTierChanges() {
    let billing = self.billing(sub: (tier: .medium, status: .pastDue))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.medium(status: .pastDue(since: .reference + .days(30))))
    expect(panel.primary).toEqual(.openBillingPortal(config: .mediumTier))
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .full), // upgrade
      .changeSubscriptionTier(to: .light), // downgrade — always available from medium
    ])
  }

  // MARK: - full trial (within trial window)

  func testFullTrialStandalone() {
    let trialStart = Date.reference
    let billing = self.billing(trialStartedAt: trialStart, date: trialStart + .days(10))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.fullTrial(until: trialStart + .days(21), substrate: nil))
    expect(panel.primary).toEqual(.startCheckout(tier: .full)) // trialing Full → lead with Full
    expect(panel.secondary).toEqual([
      .startCheckout(tier: .medium),
      .startCheckout(tier: .light),
    ])
  }

  func testFullTrialFromLight() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      sub: (tier: .light, status: .active),
      date: trialStart + .days(10),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.changeSubscriptionTier(to: .full))
    expect(panel.secondary).toEqual([
      .openBillingPortal(config: .lightTier),
      .changeSubscriptionTier(to: .medium),
    ])
  }

  func testFullTrialFromMedium() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      sub: (tier: .medium, status: .active),
      date: trialStart + .days(10),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.changeSubscriptionTier(to: .full))
    expect(panel.secondary).toEqual([
      .openBillingPortal(config: .mediumTier),
      .changeSubscriptionTier(to: .light), // medium subscriber can always step down
    ])
  }

  func testFullTrialFromPastDueMedium() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      sub: (tier: .medium, status: .pastDue),
      date: trialStart + .days(10),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.openBillingPortal(config: .mediumTier))
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .full),
      .changeSubscriptionTier(to: .light),
    ])
  }

  func testFullTrialFromPastDueLightLeadsWithPortal() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      sub: (tier: .light, status: .pastDue),
      date: trialStart + .days(10),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.openBillingPortal(config: .lightTier))
    expect(panel.secondary).toEqual([ // upgrades ascending; medium was previously missing
      .changeSubscriptionTier(to: .medium),
      .changeSubscriptionTier(to: .full),
    ])
  }

  func testFullTrialFromLapsedLight() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      lastSubId: "sub_old",
      lastPaidTier: .light,
      date: trialStart + .days(10),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .full)) // trialing Full
    expect(panel.secondary).toEqual([
      .reactivateViaCheckout(tier: .medium),
      .reactivateViaCheckout(tier: .light),
    ])
  }

  // MARK: - full tier

  func testFullPaidOpensDefaultPortal() {
    let billing = self.billing(sub: (tier: .full, status: .active))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.full(status: .current(renewsAt: .reference + .days(30))))
    expect(panel.primary).toEqual(.openBillingPortal(config: .default))
    expect(panel.secondary).toEqual([])
  }

  func testFullOverdueOpensDefaultPortal() {
    let billing = self.billing(sub: (tier: .full, status: .pastDue))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.full(status: .pastDue(since: .reference + .days(30))))
    expect(panel.primary).toEqual(.openBillingPortal(config: .default))
    expect(panel.secondary).toEqual([])
  }

  // MARK: - complimentary

  func testComplimentaryOffersNoActions() {
    let billing = self.billing(comp: true)
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.complimentary)
    expect(panel.primary).toBeNil()
    expect(panel.secondary).toEqual([])
  }

  // MARK: - full trial grace (post-trial, within grace period)

  func testFullTrialGraceStandalone() {
    let trialStart = Date.reference
    let billing = self.billing(trialStartedAt: trialStart, date: trialStart + .days(24))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.fullTrialGrace(until: trialStart + .days(28), substrate: nil))
    expect(panel.primary).toEqual(.startCheckout(tier: .full)) // trialing Full → lead with Full
    expect(panel.secondary).toEqual([
      .startCheckout(tier: .medium),
      .startCheckout(tier: .light),
    ])
  }

  func testFullTrialGraceFromLight() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      sub: (tier: .light, status: .active),
      date: trialStart + .days(24),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.changeSubscriptionTier(to: .full))
    expect(panel.secondary).toEqual([
      .openBillingPortal(config: .lightTier),
      .changeSubscriptionTier(to: .medium),
    ])
  }

  func testFullTrialGraceFromLapsedFullOffersDowngrades() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      lastSubId: "sub_old",
      lastPaidTier: .full,
      date: trialStart + .days(24),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.fullTrialGrace(until: trialStart + .days(28), substrate: nil))
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .full)) // their last tier
    expect(panel.secondary).toEqual([ // downgrades descending
      .reactivateViaCheckout(tier: .medium),
      .reactivateViaCheckout(tier: .light),
    ])
  }

  // MARK: - past-due status payload

  func testPastDueLightCarriesPayload() {
    let billing = self.billing(sub: (tier: .light, status: .pastDue))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.light(status: .pastDue(since: .reference + .days(30))))
  }

  func testRenewalDateCarriedInPlanStatus() {
    let billing = self.billing(sub: (tier: .full, status: .active))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.full(status: .current(renewsAt: .reference + .days(30))))
  }

  func testNoSubscriptionIsFreePlanStatus() {
    let billing = self.billing()
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.free)
  }

  func testTrialingStripeSubFullCountsAsLiveSubstrate() {
    let billing = self.billing(sub: (tier: .full, status: .trialing))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.full(status: .current(renewsAt: .reference + .days(30))))
    expect(panel.primary).toEqual(.openBillingPortal(config: .default))
  }

  func testCanceledStripeSubDoesNotCountAsLiveSubstrate() {
    let billing = self.billing(sub: (tier: .full, status: .canceled))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.free)
  }

  func testIncompleteStripeSubDoesNotCountAsLiveSubstrate() {
    let billing = self.billing(sub: (tier: .full, status: .incomplete))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.free)
  }
}

final class SubscriptionPanelResolverTests: ApiTestCase, @unchecked Sendable {
  func testFullPaidWithNoMacsOffersBothDowngrades() async throws {
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .full
      sub.stripeStatus = .active
    }

    let panel = try await GetSubscriptionPanel_v2.resolve(in: context(parent.model))

    expect(panel.primary).toEqual(.openBillingPortal(config: .default))
    expect(panel.secondary).toEqual([
      .changeSubscriptionTier(to: .medium),
      .changeSubscriptionTier(to: .light),
    ])
    expect(panel.availableTiers).toEqual([.light, .medium])
  }

  func testFullPaidWithRegisteredMacOmitsDowngrades() async throws {
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .full
      sub.stripeStatus = .active
    }
    _ = try await self.db.create(Computer.random {
      $0.parentId = parent.id
    })

    let panel = try await GetSubscriptionPanel_v2.resolve(in: context(parent.model))

    expect(panel.primary).toEqual(.openBillingPortal(config: .default))
    expect(panel.secondary).toEqual([])
    expect(panel.availableTiers).toEqual([])
  }
}

extension SubscriptionPanelTests {
  func billing(
    comp: Bool = false,
    trialStartedAt: Date? = nil,
    sub: (tier: StripeSubscription.Tier, status: StripeSubscription.StripeStatus)? = nil,
    lastSubId: String? = nil,
    lastPaidTier: StripeSubscription.Tier? = nil,
    date: Date = .reference,
  ) -> BillingAccountSnapshot {
    let identity = BillingIdentity(
      parentId: .init(),
      stripeCustomerId: lastSubId == nil ? nil : .init("cus_test"),
      fullTrialStartedAt: trialStartedAt,
      lastStripeSubscriptionId: lastSubId.map { .init($0) },
      lastPaidTier: lastPaidTier,
      isComplimentary: comp,
    )
    let subscription = sub.map { sub in
      var s = StripeSubscription(
        parentId: identity.parentId,
        tier: sub.tier,
        stripeId: .init("sub_test"),
        stripeStatus: sub.status,
        currentPeriodEnd: .reference + .days(30),
      )
      s.isLegacyPrice = false
      return s
    }
    return BillingAccountSnapshot(
      billingIdentity: identity,
      stripeSubscription: subscription,
      date: date,
    )
  }
}
