import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MacAppConnectionCodeResolverTests: ApiTestCase, @unchecked Sendable {
  override func invokeTest() {
    withDependencies {
      $0.verificationCode.generate = { 123_456 }
    } operation: {
      super.invokeTest()
    }
  }

  func testFullPaidUser_noGate() async throws {
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .full
      sub.stripeStatus = .active
    }
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: context(parent.model),
    )

    expect(output).toEqual(.init(code: 123_456, gate: nil))
  }

  func testFreeUser_getsTrialRequiredGate() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: parent.context,
    )

    expect(output).toEqual(.init(code: 123_456, gate: .trialRequired))
  }

  func testTrialConsumedNeverPaid_getsPlanUpgradeRequiredGate() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(60),
    ))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: parent.context,
    )

    expect(output).toEqual(.init(code: 123_456, gate: .planUpgradeRequired))
  }

  func testLightUserNotTrialed_getsTrialRequiredGate() async throws {
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .light
      sub.stripeStatus = .active
    }
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: context(parent.model),
    )

    expect(output).toEqual(.init(code: 123_456, gate: .trialRequired))
  }

  func testLightUserAlreadyTrialed_getsPlanUpgradeRequiredGate() async throws {
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .light
      sub.stripeStatus = .active
    }
    let identityOpt = try await parent.model.billingIdentity(in: self.db)
    var identity = try XCTUnwrap(identityOpt)
    identity.fullTrialStartedAt = .reference - .days(60)
    try await self.db.update(identity)

    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: context(parent.model),
    )

    expect(output).toEqual(.init(code: 123_456, gate: .planUpgradeRequired))
  }

  func testLapsedFullUser_getsSubscriptionFixRequiredGate() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init("cus_123"),
      lastStripeSubscriptionId: .init("sub_123"),
      lastPaidTier: .full,
    ))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: context(parent.model),
    )

    expect(output).toEqual(.init(code: 123_456, gate: .subscriptionFixRequired))
  }
}
