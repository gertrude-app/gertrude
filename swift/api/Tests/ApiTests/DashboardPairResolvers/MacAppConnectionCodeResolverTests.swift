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
    let parent = try await self.parentWithSubscription {
      $1.tier = .full
      $1.billingStatus = .paid
      $1.stripeId = .init("sub_123")
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

  func testLightUserNotTrialed_getsTrialRequiredGate() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .light
      $1.billingStatus = .paid
      $1.trialStartedAt = nil
      $1.stripeId = .init("sub_123")
    }
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: context(parent.model),
    )

    expect(output).toEqual(.init(code: 123_456, gate: .trialRequired))
  }

  func testLightUserAlreadyTrialed_getsPlanUpgradeRequiredGate() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .light
      $1.billingStatus = .paid
      $1.stripeId = .init("sub_123")
      $1.trialStartedAt = .reference - .days(60)
    }
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: context(parent.model),
    )

    expect(output).toEqual(.init(code: 123_456, gate: .planUpgradeRequired))
  }

  func testLapsedFullUser_getsSubscriptionFixRequiredGate() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .full
      $1.billingStatus = .unpaid
      $1.stripeId = .init("sub_123")
      $1.statusExpiresAt = .reference - .days(7)
    }
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })

    let output = try await MacAppConnectionCode.resolve(
      with: .init(childId: child.id),
      in: context(parent.model),
    )

    expect(output).toEqual(.init(code: 123_456, gate: .subscriptionFixRequired))
  }
}
