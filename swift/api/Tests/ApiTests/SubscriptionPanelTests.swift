import Foundation
import XCTest
import XExpect

@testable import Api

final class SubscriptionPanelTests: DependencyTestCase {
  typealias Action = GetSubscriptionPanel_v2.Action

  // MARK: - free, no history

  func testFreeStandardOffersFullAndLightAndTrial() {
    let billing = self.billing()
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.free)
    expect(panel.primary).toEqual(.startCheckout(tier: .full))
    expect(panel.secondary).toEqual([.startCheckout(tier: .light), .startFullTrial])
  }

  func testFreeStandardWithUsedTrialOmitsTrialOption() {
    let billing = self.billing(trialStartedAt: .reference - .days(60))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.startCheckout(tier: .full))
    expect(panel.secondary).toEqual([.startCheckout(tier: .light)])
  }

  // MARK: - free, lapsed

  func testFreeLapsedLightReactivatesEitherTier() {
    let billing = self.billing(lastSubId: "sub_old", lastPaidTier: .light)
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .light))
    expect(panel.secondary).toEqual([.reactivateViaCheckout(tier: .full)])
  }

  func testFreeLapsedFullOffersBothTiersForReactivation() {
    let billing = self.billing(lastSubId: "sub_old", lastPaidTier: .full)
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .full))
    expect(panel.secondary).toEqual([.reactivateViaCheckout(tier: .light)])
  }

  // MARK: - light tier

  func testLightPaidUpgradeFullPrimary() {
    let billing = self.billing(sub: (tier: .light, status: .active))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.light(status: .current(renewsAt: .reference + .days(30))))
    expect(panel.primary).toEqual(.upgradeSubscriptionTier(to: .full))
    expect(panel.secondary).toEqual([
      .openBillingPortal(config: .lightTier),
      .startFullTrial,
    ])
  }

  func testLightPaidWithUsedTrialOmitsTrialOption() {
    let billing = self.billing(
      trialStartedAt: .reference - .days(60),
      sub: (tier: .light, status: .active),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.secondary).toEqual([.openBillingPortal(config: .lightTier)])
  }

  func testLightOverdueOffersPortalThenUpgrade() {
    let billing = self.billing(sub: (tier: .light, status: .pastDue))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.openBillingPortal(config: .lightTier))
    expect(panel.secondary).toEqual([.upgradeSubscriptionTier(to: .full)])
  }

  // MARK: - full trial (within trial window)

  func testFullTrialStandalone() {
    let trialStart = Date.reference
    let billing = self.billing(trialStartedAt: trialStart, date: trialStart + .days(10))
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.fullTrial(until: trialStart + .days(21)))
    expect(panel.primary).toEqual(.startCheckout(tier: .full))
    expect(panel.secondary).toEqual([.startCheckout(tier: .light)])
  }

  func testFullTrialFromLight() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      sub: (tier: .light, status: .active),
      date: trialStart + .days(10),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.upgradeSubscriptionTier(to: .full))
    expect(panel.secondary).toEqual([.openBillingPortal(config: .lightTier)])
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
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .full))
    expect(panel.secondary).toEqual([.reactivateViaCheckout(tier: .light)])
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
    expect(panel.planStatus).toEqual(.fullTrialGrace(until: trialStart + .days(28)))
    expect(panel.primary).toEqual(.startCheckout(tier: .full))
    expect(panel.secondary).toEqual([.startCheckout(tier: .light)])
  }

  func testFullTrialGraceFromLight() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      sub: (tier: .light, status: .active),
      date: trialStart + .days(24),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.primary).toEqual(.upgradeSubscriptionTier(to: .full))
    expect(panel.secondary).toEqual([.openBillingPortal(config: .lightTier)])
  }

  func testFullTrialGraceFromLapsedFullReactivatesFullOnly() {
    let trialStart = Date.reference
    let billing = self.billing(
      trialStartedAt: trialStart,
      lastSubId: "sub_old",
      lastPaidTier: .full,
      date: trialStart + .days(24),
    )
    let panel = panelOutput_v2(billing: billing)
    expect(panel.planStatus).toEqual(.fullTrialGrace(until: trialStart + .days(28)))
    expect(panel.primary).toEqual(.reactivateViaCheckout(tier: .full))
    expect(panel.secondary).toEqual([])
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
