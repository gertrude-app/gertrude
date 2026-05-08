import Foundation
import XCTest
import XExpect

@testable import Api

final class EntitlementDerivationTests: DependencyTestCase {
  func testNoTrialNoSubReturnsFree() {
    expect(entitle(at: .reference)).toEqual(.free)
  }

  func testNoTrialLightSubReturnsLight() {
    expect(entitle(sub: .light, at: .reference)).toEqual(.light)
  }

  func testNoTrialFullSubReturnsFull() {
    expect(entitle(sub: .full, at: .reference)).toEqual(.full)
  }

  func testComplimentaryShortCircuitsWithNoSub() {
    expect(entitle(comp: true, at: .reference)).toEqual(.complimentary)
  }

  func testComplimentaryWinsOverTrialOverlay() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(entitle(comp: true, trialStartedAt: trialStart, at: now))
      .toEqual(.complimentary)
  }

  func testTrialJustStartedReturnsFullTrial() {
    let trialStart = Date.reference
    expect(entitle(trialStartedAt: trialStart, at: trialStart))
      .toEqual(.fullTrial(until: trialStart + .days(21)))
  }

  func testMidTrialReturnsFullTrial() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(entitle(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrial(until: trialStart + .days(21)))
  }

  func testTrialOverlayWinsOverLightSubstrate() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(entitle(trialStartedAt: trialStart, sub: .light, at: now))
      .toEqual(.fullTrial(until: trialStart + .days(21)))
  }

  func testFullSubstrateWinsOverTrialOverlay() {
    let trialStart = Date.reference
    let now = trialStart + .days(10)
    expect(entitle(trialStartedAt: trialStart, sub: .full, at: now)).toEqual(.full)
  }

  func testFullSubstrateWinsOverGraceOverlay() {
    let trialStart = Date.reference
    let now = trialStart + .days(25)
    expect(entitle(trialStartedAt: trialStart, sub: .full, at: now)).toEqual(.full)
  }

  func testTrialJustBeforeExpiryStillFullTrial() {
    let trialStart = Date.reference
    let now = trialStart + .days(21) - 1
    expect(entitle(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrial(until: trialStart + .days(21)))
  }

  func testTrialAtExactExpiryEntersGrace() {
    let trialStart = Date.reference
    let now = trialStart + .days(21)
    expect(entitle(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrialGrace(until: trialStart + .days(28)))
  }

  func testMidGraceReturnsFullTrialGrace() {
    let trialStart = Date.reference
    let now = trialStart + .days(25)
    expect(entitle(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrialGrace(until: trialStart + .days(28)))
  }

  func testGraceOverlayWinsOverLightSubstrate() {
    let trialStart = Date.reference
    let now = trialStart + .days(25)
    expect(entitle(trialStartedAt: trialStart, sub: .light, at: now))
      .toEqual(.fullTrialGrace(until: trialStart + .days(28)))
  }

  func testGraceJustBeforeEndStillGrace() {
    let trialStart = Date.reference
    let now = trialStart + .days(28) - 1
    expect(entitle(trialStartedAt: trialStart, at: now))
      .toEqual(.fullTrialGrace(until: trialStart + .days(28)))
  }

  func testAtExactGraceEndFallsThroughToSubstrateFree() {
    let trialStart = Date.reference
    let now = trialStart + .days(28)
    expect(entitle(trialStartedAt: trialStart, at: now)).toEqual(.free)
  }

  func testPastGraceWithLightSubReturnsLight() {
    let trialStart = Date.reference
    let now = trialStart + .days(30)
    expect(entitle(trialStartedAt: trialStart, sub: .light, at: now))
      .toEqual(.light)
  }

  func testPastGraceWithFullSubReturnsFull() {
    let trialStart = Date.reference
    let now = trialStart + .days(30)
    expect(entitle(trialStartedAt: trialStart, sub: .full, at: now))
      .toEqual(.full)
  }

  func testPastGraceWithNoSubReturnsFree() {
    let trialStart = Date.reference
    let now = trialStart + .days(30)
    expect(entitle(trialStartedAt: trialStart, at: now)).toEqual(.free)
  }
}

private func entitle(
  comp: Bool = false,
  trialStartedAt: Date? = nil,
  sub: StripeSubscription.Tier? = nil,
  at now: Date,
) -> Entitlement {
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
      stripeStatus: .active,
      currentPeriodEnd: now + .days(30),
    )
  }
  return ParentBilling(
    identity: identity,
    stripeSubscription: subscription,
  ).entitlement(at: now)
}
