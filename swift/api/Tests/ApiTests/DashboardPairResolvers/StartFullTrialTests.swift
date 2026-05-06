import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class StartFullTrialTests: ApiTestCase, @unchecked Sendable {
  func testFreeUser_createsFullTrialingSubscription() async throws {
    let parent = try await self.parent()

    let output = try await StartFullTrial.resolve(in: parent.context)

    expect(output).toEqual(.success)

    let subscription = try await parent.model.subscription(in: self.db)
    let sub = try XCTUnwrap(subscription)
    expect(sub.tier).toEqual(.full)
    expect(sub.billingStatus).toEqual(.trialing)
    expect(sub.trialStartedAt).toEqual(.reference)
  }

  func testLightUserNotTrialed_setsTrialStartedAt() async throws {
    let parent = try await self.parent()
    try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_123"),
      statusExpiresAt: .reference + .days(365),
    ))

    let output = try await StartFullTrial.resolve(in: parent.context)

    expect(output).toEqual(.success)

    let subscription = try await parent.model.subscription(in: self.db)
    let sub = try XCTUnwrap(subscription)
    expect(sub.tier).toEqual(.light)
    expect(sub.billingStatus).toEqual(.paid)
    expect(sub.trialStartedAt).toEqual(.reference)
  }

  func testLightUserAlreadyTrialed_throwsError() async throws {
    let parent = try await self.parent()
    try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_123"),
      trialStartedAt: .reference - .days(60),
      statusExpiresAt: .reference + .days(365),
    ))

    try await expectErrorFrom {
      try await StartFullTrial.resolve(in: parent.context)
    }.toContain("Trial already used")
  }

  func testStandaloneTrialPanelShowsFullTrialNotFull() async throws {
    let parent = try await self.parent()
    _ = try await StartFullTrial.resolve(in: parent.context)

    let panel = try await GetSubscriptionPanel.resolve(in: parent.context)
    expect(panel.entitlement).toEqual(.fullTrial(until: .reference + .days(21)))
    expect(panel.primary).toEqual(.startCheckout(tier: .full))
    expect(panel.secondary).toEqual([.startCheckout(tier: .light)])
  }
}
