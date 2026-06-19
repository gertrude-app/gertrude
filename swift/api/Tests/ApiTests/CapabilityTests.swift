import Foundation
import Gertie
import XCTest
import XExpect

@testable import Api

final class CapabilityTests: DependencyTestCase {
  func testCanSuperviseForActiveLight() {
    expect(billing(tier: .light, status: .active).can(.superviseIosDevice)).toBeTrue()
  }

  func testCanSuperviseForActiveFull() {
    expect(billing(tier: .full, status: .active).can(.superviseIosDevice)).toBeTrue()
  }

  func testCanSuperviseForPastDueLight() {
    expect(billing(tier: .light, status: .pastDue).can(.superviseIosDevice)).toBeFalse()
  }

  func testCannotSuperviseForPastDueFull() {
    expect(billing(tier: .full, status: .pastDue).can(.superviseIosDevice)).toBeFalse()
  }

  func testCanSuperviseForComplimentary() {
    expect(billing(comp: true).can(.superviseIosDevice)).toBeTrue()
  }

  func testCanSuperviseForComplimentaryDespitePastDueFullSub() {
    expect(
      billing(comp: true, tier: .full, status: .pastDue).can(.superviseIosDevice),
    ).toBeTrue()
  }

  func testCannotSuperviseForFreeNoSub() {
    expect(billing().can(.superviseIosDevice)).toBeFalse()
  }

  func testCannotSuperviseForStandaloneTrial() {
    let trialStart = Date.reference
    expect(
      billing(trialStartedAt: trialStart, date: trialStart + .days(10))
        .can(.superviseIosDevice),
    ).toBeFalse()
  }

  func testCanSuperviseForPaidLightWhileTrialingFull() {
    let trialStart = Date.reference
    expect(
      billing(
        trialStartedAt: trialStart,
        tier: .light,
        status: .active,
        date: trialStart + .days(10),
      ).can(.superviseIosDevice),
    ).toBeTrue()
  }

  func testCannotSuperviseForPastDueLightWhileTrialingFull() {
    let trialStart = Date.reference
    expect(
      billing(
        trialStartedAt: trialStart,
        tier: .light,
        status: .pastDue,
        date: trialStart + .days(10),
      ).can(.superviseIosDevice),
    ).toBeFalse()
  }

  func testCannotSuperviseForCanceledFullSub() {
    expect(billing(tier: .full, status: .canceled).can(.superviseIosDevice)).toBeFalse()
  }

  func testCanUseMusicForActiveLight() {
    expect(billing(tier: .light, status: .active).can(.useGertrudeMusic)).toBeTrue()
  }

  func testCanUseMusicForActiveFull() {
    expect(billing(tier: .full, status: .active).can(.useGertrudeMusic)).toBeTrue()
  }

  func testCanUseMusicForStandaloneFullTrial() {
    let trialStart = Date.reference
    expect(
      billing(trialStartedAt: trialStart, date: trialStart + .days(10))
        .can(.useGertrudeMusic),
    ).toBeTrue()
  }

  func testCannotUseMusicForFullTrialGraceWithoutPaidSubstrate() {
    let trialStart = Date.reference
    expect(
      billing(trialStartedAt: trialStart, date: trialStart + .days(24))
        .can(.useGertrudeMusic),
    ).toBeFalse()
  }

  func testCanUseMusicForCurrentLightDuringFullTrialGrace() {
    let trialStart = Date.reference
    expect(
      billing(
        trialStartedAt: trialStart,
        tier: .light,
        status: .active,
        date: trialStart + .days(24),
      ).can(.useGertrudeMusic),
    ).toBeTrue()
  }

  func testCannotUseMusicForPastDueLightDuringFullTrialGrace() {
    let trialStart = Date.reference
    expect(
      billing(
        trialStartedAt: trialStart,
        tier: .light,
        status: .pastDue,
        date: trialStart + .days(24),
      ).can(.useGertrudeMusic),
    ).toBeFalse()
  }

  func testCannotUseMusicForPastDueFull() {
    expect(billing(tier: .full, status: .pastDue).can(.useGertrudeMusic)).toBeFalse()
  }

  func testCanUseMusicForComplimentary() {
    expect(billing(comp: true).can(.useGertrudeMusic)).toBeTrue()
  }

  func testCannotUseMusicForFree() {
    expect(billing().can(.useGertrudeMusic)).toBeFalse()
  }

  func testPaymentActionForMissingLightPlanCapabilityIgnoresMacAppCapability() {
    expect(billing().paymentActionForMissingLightPlanCapability(.connectMacApp)).toBeNil()
  }

  func testCanConnectMacAppForFull() {
    expect(billing(tier: .full, status: .active).can(.connectMacApp)).toBeTrue()
  }

  func testCanConnectMacAppForStandaloneTrial() {
    let trialStart = Date.reference
    expect(
      billing(trialStartedAt: trialStart, date: trialStart + .days(10)).can(.connectMacApp),
    ).toBeTrue()
  }

  func testCanConnectMacAppForComplimentary() {
    expect(billing(comp: true).can(.connectMacApp)).toBeTrue()
  }

  func testCannotConnectMacAppForFree() {
    expect(billing().can(.connectMacApp)).toBeFalse()
  }

  func testCannotConnectMacAppForLight() {
    expect(billing(tier: .light, status: .active).can(.connectMacApp)).toBeFalse()
  }

  // MARK: - macAppAccessStatus tri-state (.active / .needsAttention / .inactive)

  func testAccessStatusActiveForFull() {
    expect(billing(tier: .full, status: .active).macAppAccessStatus).toEqual(.active)
  }

  func testAccessStatusActiveForComplimentary() {
    expect(billing(comp: true).macAppAccessStatus).toEqual(.active)
  }

  func testAccessStatusActiveForFullTrial() {
    let trialStart = Date.reference
    expect(
      billing(trialStartedAt: trialStart, date: trialStart + .days(10)).macAppAccessStatus,
    ).toEqual(.active)
  }

  func testAccessStatusNeedsAttentionForPastDueFull() {
    expect(
      billing(tier: .full, status: .pastDue).macAppAccessStatus,
    ).toEqual(.needsAttention)
  }

  func testAccessStatusNeedsAttentionForFullTrialGrace() {
    let trialStart = Date.reference
    expect(
      billing(trialStartedAt: trialStart, date: trialStart + .days(24)).macAppAccessStatus,
    ).toEqual(.needsAttention)
  }

  func testAccessStatusInactiveForLight() {
    expect(
      billing(tier: .light, status: .active).macAppAccessStatus,
    ).toEqual(.inactive)
  }

  func testAccessStatusInactiveForFree() {
    expect(billing().macAppAccessStatus).toEqual(.inactive)
  }

  // MARK: - macAppConnectionGate

  func testGateNilForFullActive() {
    expect(billing(tier: .full, status: .active).macAppConnectionGate).toBeNil()
  }

  func testGateNilForComplimentary() {
    expect(billing(comp: true).macAppConnectionGate).toBeNil()
  }

  func testGateNilForFullTrial() {
    let trialStart = Date.reference
    expect(
      billing(trialStartedAt: trialStart, date: trialStart + .days(10)).macAppConnectionGate,
    ).toBeNil()
  }

  func testGateSubscriptionFixForPastDueFull() {
    expect(
      billing(tier: .full, status: .pastDue).macAppConnectionGate,
    ).toEqual(.subscriptionFixRequired)
  }

  func testGateSubscriptionFixForPastDueLight() {
    expect(
      billing(tier: .light, status: .pastDue).macAppConnectionGate,
    ).toEqual(.subscriptionFixRequired)
  }

  func testGatePlanUpgradeForLightGraceFromLightSub() {
    let trialStart = Date.reference
    expect(
      billing(
        trialStartedAt: trialStart,
        tier: .light,
        status: .active,
        date: trialStart + .days(24),
      ).macAppConnectionGate,
    ).toEqual(.planUpgradeRequired)
  }

  func testGateSubscriptionFixForPastDueLightGrace() {
    let trialStart = Date.reference
    expect(
      billing(
        trialStartedAt: trialStart,
        tier: .light,
        status: .pastDue,
        date: trialStart + .days(24),
      ).macAppConnectionGate,
    ).toEqual(.subscriptionFixRequired)
  }

  func testGateTrialRequiredForBrandNewFree() {
    expect(billing().macAppConnectionGate).toEqual(.trialRequired)
  }

  func testGateTrialRequiredForLightWithoutPriorTrial() {
    expect(
      billing(tier: .light, status: .active).macAppConnectionGate,
    ).toEqual(.trialRequired)
  }

  func testGatePlanUpgradeRequiredForLightWithPriorTrial() {
    expect(
      billing(
        trialStartedAt: .reference - .days(60),
        tier: .light,
        status: .active,
      ).macAppConnectionGate,
    ).toEqual(.planUpgradeRequired)
  }
}

private func billing(
  comp: Bool = false,
  trialStartedAt: Date? = nil,
  tier: StripeSubscription.Tier? = nil,
  status: StripeSubscription.StripeStatus = .active,
  date: Date = .reference,
) -> BillingAccountSnapshot {
  let identity = BillingIdentity(
    parentId: .init(),
    fullTrialStartedAt: trialStartedAt,
    isComplimentary: comp,
  )
  let subscription = tier.map { tier in
    StripeSubscription(
      parentId: identity.parentId,
      tier: tier,
      stripeId: .init("sub_test"),
      stripeStatus: status,
      currentPeriodEnd: .reference + .days(30),
    )
  }
  return BillingAccountSnapshot(
    billingIdentity: identity,
    stripeSubscription: subscription,
    date: date,
  )
}
