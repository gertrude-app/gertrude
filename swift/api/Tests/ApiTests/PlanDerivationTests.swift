import Foundation
import XCTest
import XExpect

@testable import Api

final class PlanDerivationTests: DependencyTestCase {
  func testNoSubscriptionReturnsFreeStandard() {
    let plan = Plan(subscription: nil)
    expect(plan).toEqual(.free(kind: .standard))
  }

  func testLightUserWithActiveTrialDerivesToFullTrialing() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(10)
    let subscription = Subscription(
      parentId: .init(),
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      trialStartedAt: trialStarted,
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: now)
    let expectedExpiration = trialStarted + Plan.Full.trialLengthDays
    expect(plan).toEqual(.full(status: .trialing(
      kind: .fromLight(stripeId: .init("sub_test")),
      until: expectedExpiration,
    )))
  }

  func testLightUserWithTrialOnDay21StillTrialing() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(20) + .hours(23)
    let subscription = Subscription(
      parentId: .init(),
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      trialStartedAt: trialStarted,
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: now)
    let expectedExpiration = trialStarted + Plan.Full.trialLengthDays
    expect(plan).toEqual(.full(status: .trialing(
      kind: .fromLight(stripeId: .init("sub_test")),
      until: expectedExpiration,
    )))
  }

  func testLightUserInGracePeriodDerivesToFullTrialExpired() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(25)
    let subscription = Subscription(
      parentId: .init(),
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      trialStartedAt: trialStarted,
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: now)
    expect(plan).toEqual(.full(status: .trialExpired(
      kind: .fromLight(stripeId: .init("sub_test")),
    )))
  }

  func testLightUserAfterGracePeriodReturnsToLight() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(30)
    let subscription = Subscription(
      parentId: .init(),
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      trialStartedAt: trialStarted,
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: now)
    expect(plan).toEqual(.light(status: .paid(stripeId: .init("sub_test"), hasTrialedFull: true)))
  }

  func testLightUserWithoutTrialStartedReturnsLight() {
    let subscription = Subscription(
      parentId: .init(),
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      trialStartedAt: nil,
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: .reference)
    expect(plan).toEqual(.light(status: .paid(stripeId: .init("sub_test"), hasTrialedFull: false)))
  }

  func testLightUserOverdueWithActiveTrialStillGetsFullTrialing() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(10)
    let subscription = Subscription(
      parentId: .init(),
      tier: .light,
      billingStatus: .overdue,
      stripeId: .init("sub_test"),
      trialStartedAt: trialStarted,
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: now)
    let expectedExpiration = trialStarted + Plan.Full.trialLengthDays
    expect(plan).toEqual(.full(status: .trialing(
      kind: .fromLight(stripeId: .init("sub_test")),
      until: expectedExpiration,
    )))
  }

  func testFullUserUnaffectedByNowParameter() {
    let subscription = Subscription(
      parentId: .init(),
      tier: .full,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: .reference)
    expect(plan).toEqual(.full(status: .paid(
      stripeId: .init("sub_test"),
      monthlyPriceInCents: 1000,
    )))
  }

  func testFullComplimentaryUnaffectedByNowParameter() {
    let subscription = Subscription(
      parentId: .init(),
      tier: .full,
      billingStatus: nil,
      statusExpiresAt: .distantFuture,
    )
    let plan = Plan(subscription: subscription, now: .reference)
    expect(plan).toEqual(.full(status: .complimentary))
  }

  func testAllowsSupervisionForLightPaidUserTrialingFull() {
    let trialStarted = Date.reference
    let subscription = Subscription(
      parentId: .init(),
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_test"),
      trialStartedAt: trialStarted,
      statusExpiresAt: .distantFuture,
    )
    let trialing = Plan(subscription: subscription, now: trialStarted + .days(10))
    expect(trialing.allowsSupervision).toEqual(true)
    let trialExpired = Plan(subscription: subscription, now: trialStarted + .days(25))
    expect(trialExpired.allowsSupervision).toEqual(true)
  }

  func testDoesNotAllowSupervisionForFullTrialingFromScratch() {
    let plan = Plan.full(status: .trialing(kind: .full, until: .distantFuture))
    expect(plan.allowsSupervision).toEqual(false)
  }

  func testLapsedLightWithActiveTrialDerivesToFullTrialingFromLapsedLight() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(10)
    for status: BillingStatus.Db in [.unpaid, .cancelled] {
      let subscription = Subscription(
        parentId: .init(),
        tier: .light,
        billingStatus: status,
        stripeId: .init("sub_test"),
        trialStartedAt: trialStarted,
        statusExpiresAt: .distantFuture,
      )
      let plan = Plan(subscription: subscription, now: now)
      expect(plan).toEqual(.full(status: .trialing(
        kind: .fromLapsedLight(stripeId: .init("sub_test")),
        until: trialStarted + Plan.Full.trialLengthDays,
      )))
      expect(plan.allowsSupervision).toEqual(false)
    }
  }

  func testLapsedLightInGracePeriodDerivesToTrialExpiredFromLapsedLight() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(25)
    for status: BillingStatus.Db in [.unpaid, .cancelled] {
      let subscription = Subscription(
        parentId: .init(),
        tier: .light,
        billingStatus: status,
        stripeId: .init("sub_test"),
        trialStartedAt: trialStarted,
        statusExpiresAt: .distantFuture,
      )
      let plan = Plan(subscription: subscription, now: now)
      expect(plan).toEqual(.full(status: .trialExpired(
        kind: .fromLapsedLight(stripeId: .init("sub_test")),
      )))
      expect(plan.allowsSupervision).toEqual(false)
    }
  }

  func testLapsedLightAfterGracePeriodReturnsToLapsedLight() {
    let trialStarted = Date.reference
    let now = trialStarted + .days(30)
    for status: BillingStatus.Db in [.unpaid, .cancelled] {
      let subscription = Subscription(
        parentId: .init(),
        tier: .light,
        billingStatus: status,
        stripeId: .init("sub_test"),
        trialStartedAt: trialStarted,
        statusExpiresAt: .distantFuture,
      )
      let plan = Plan(subscription: subscription, now: now)
      expect(plan).toEqual(.free(kind: .lapsedLight(
        stripeId: .init("sub_test"),
        hasTrialedFull: true,
      )))
      expect(plan.allowsSupervision).toEqual(false)
    }
  }
}

extension TimeInterval {
  static func hours(_ hours: Int) -> Self {
    Double(hours) * 3600
  }
}
