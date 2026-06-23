import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class StartFullTrialTests: ApiTestCase, @unchecked Sendable {
  func testFreeUser_setsFullTrialStartedAtOnIdentity() async throws {
    let parent = try await self.parent()

    let output = try await StartFullTrial.resolve(in: parent.context)

    expect(output).toEqual(.success)

    let identity = try await parent.model.billingIdentity(in: self.db)
    let id = try XCTUnwrap(identity)
    expect(id.fullTrialStartedAt).toEqual(.reference)

    let subscription = try await parent.model.subscription(in: self.db)
    expect(subscription).toBeNil()
  }

  func testLightUser_setsTrialOnIdentityWithoutTouchingSubscription() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(parentId: parent.id))
    try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .light,
      stripeId: .init("sub_123"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(365),
    ))

    let output = try await StartFullTrial.resolve(in: parent.context)

    expect(output).toEqual(.success)

    let identity = try await parent.model.billingIdentity(in: self.db)
    let id = try XCTUnwrap(identity)
    expect(id.fullTrialStartedAt).toEqual(.reference)

    let subOpt = try await parent.model.subscription(in: self.db)
    let sub = try XCTUnwrap(subOpt)
    expect(sub.tier).toEqual(.light)
    expect(sub.stripeStatus).toEqual(.active)
  }

  func testAlreadyTrialed_throwsError() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(60),
    ))

    try await expectErrorFrom {
      try await StartFullTrial.resolve(in: parent.context)
    }.toContain("Trial already used")
  }

  func testStandaloneTrialPanelShowsFullTrialNotFull() async throws {
    let parent = try await self.parent()
    _ = try await StartFullTrial.resolve(in: parent.context)

    let panel = try await GetSubscriptionPanel_v2.resolve(in: parent.context)
    expect(panel.planStatus).toEqual(.fullTrial(until: .reference + .days(21), substrate: nil))
    expect(panel.primary).toEqual(.startCheckout(tier: .full))
    expect(panel.secondary).toEqual([.startCheckout(tier: .light)])
  }
}
