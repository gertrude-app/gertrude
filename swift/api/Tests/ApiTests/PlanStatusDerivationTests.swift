import Foundation
import XCTest
import XExpect

@testable import Api

final class PlanStatusDerivationTests: DependencyTestCase {
  func testNoTrialNoSubReturnsFree() {
    expect(planStatus(at: .reference)).toEqual(.free)
  }

  func testNoTrialLightSubReturnsLight() {
    expect(planStatus(sub: .light, at: .reference))
      .toEqual(.light(status: .current(renewsAt: .reference + .days(30))))
  }

  func testNoTrialFullSubReturnsFull() {
    expect(planStatus(sub: .full, at: .reference))
      .toEqual(.full(status: .current(renewsAt: .reference + .days(30))))
  }

  func testPastDueLightReturnsLightPastDue() {
    expect(planStatus(sub: .light, status: .pastDue, at: .reference))
      .toEqual(.light(status: .pastDue(since: .reference + .days(30))))
  }

  func testPastDueFullReturnsFullPastDue() {
    expect(planStatus(sub: .full, status: .pastDue, at: .reference))
      .toEqual(.full(status: .pastDue(since: .reference + .days(30))))
  }

  func testComplimentaryShortCircuitsWithNoSub() {
    expect(planStatus(comp: true, at: .reference)).toEqual(.complimentary)
  }

  func testComplimentaryWinsOverTrialOverlay() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(planStatus(comp: true, trialStartedAt: trialStart, at: now))
      .toEqual(.complimentary)
  }

  func testTrialJustStartedReturnsFullTrial() {
    let trialStart = Date.reference
    expect(planStatus(trialStartedAt: trialStart, at: trialStart))
      .toEqual(.fullTrial(until: trialStart + .days(21), substrate: nil))
  }

  func testMidTrialReturnsFullTrial() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(planStatus(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrial(until: trialStart + .days(21), substrate: nil))
  }

  func testTrialOverlayWinsOverLightSubstrate() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(planStatus(trialStartedAt: trialStart, sub: .light, at: now))
      .toEqual(.fullTrial(
        until: trialStart + .days(21),
        substrate: .init(tier: .light, status: .current(renewsAt: now + .days(30))),
      ))
  }

  func testFullSubstrateWinsOverTrialOverlay() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(planStatus(trialStartedAt: trialStart, sub: .full, at: now))
      .toEqual(.full(status: .current(renewsAt: now + .days(30))))
  }

  func testFullSubstrateWinsOverGraceOverlay() {
    let trialStart = Date.reference
    let now = trialStart + .days(25)
    expect(planStatus(trialStartedAt: trialStart, sub: .full, at: now))
      .toEqual(.full(status: .current(renewsAt: now + .days(30))))
  }

  func testTrialJustBeforeExpiryStillFullTrial() {
    let trialStart = Date.reference
    let now = trialStart + .days(21) - 1
    expect(planStatus(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrial(until: trialStart + .days(21), substrate: nil))
  }

  func testTrialAtExactExpiryEntersGrace() {
    let trialStart = Date.reference
    let now = trialStart + .days(21)
    expect(planStatus(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrialGrace(until: trialStart + .days(28), substrate: nil))
  }

  func testMidGraceReturnsFullTrialGrace() {
    let trialStart = Date.reference
    let now = trialStart + .days(25)
    expect(planStatus(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrialGrace(until: trialStart + .days(28), substrate: nil))
  }

  func testGraceOverlayWinsOverLightSubstrate() {
    let trialStart = Date.reference
    let now = trialStart + .days(25)
    expect(planStatus(trialStartedAt: trialStart, sub: .light, at: now))
      .toEqual(.fullTrialGrace(
        until: trialStart + .days(28),
        substrate: .init(tier: .light, status: .current(renewsAt: now + .days(30))),
      ))
  }

  func testGraceJustBeforeEndStillGrace() {
    let trialStart = Date.reference
    let now = trialStart + .days(28) - 1
    expect(planStatus(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrialGrace(until: trialStart + .days(28), substrate: nil))
  }

  func testAtExactGraceEndFallsThroughToSubstrateFree() {
    let trialStart = Date.reference
    let now = trialStart + .days(28)
    expect(planStatus(trialStartedAt: trialStart, at: now)).toEqual(.free)
  }

  func testPastGraceWithLightSubReturnsLight() {
    let trialStart = Date.reference
    let now = trialStart + .days(30)
    expect(planStatus(trialStartedAt: trialStart, sub: .light, at: now))
      .toEqual(.light(status: .current(renewsAt: now + .days(30))))
  }

  func testPastGraceWithFullSubReturnsFull() {
    let trialStart = Date.reference
    let now = trialStart + .days(30)
    expect(planStatus(trialStartedAt: trialStart, sub: .full, at: now))
      .toEqual(.full(status: .current(renewsAt: now + .days(30))))
  }

  func testPastGraceWithNoSubReturnsFree() {
    let trialStart = Date.reference
    let now = trialStart + .days(30)
    expect(planStatus(trialStartedAt: trialStart, at: now)).toEqual(.free)
  }
}

private func planStatus(
  comp: Bool = false,
  trialStartedAt: Date? = nil,
  sub: StripeSubscription.Tier? = nil,
  status: StripeSubscription.StripeStatus = .active,
  at now: Date,
) -> PlanStatus {
  let identity = BillingIdentity(
    parentId: .init(),
    fullTrialStartedAt: trialStartedAt,
    isComplimentary: comp,
  )
  let subscription = sub.map { tier in
    StripeSubscription(
      parentId: identity.parentId,
      tier: tier,
      stripeId: .init("sub_test"),
      stripeStatus: status,
      currentPeriodEnd: now + .days(30),
    )
  }
  return BillingAccountSnapshot(
    billingIdentity: identity,
    stripeSubscription: subscription,
    date: now,
  ).planStatus
}
