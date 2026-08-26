import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetIOSDeviceSupervisionStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testPaidPlan_doesNotRequirePayment() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .light
      $1.stripeStatus = .active
    }
    let (code, _) = try await self.claimedDevice(parentId: parent.id)

    let output = try await GetIOSDeviceSupervisionStatus.resolve(
      with: .init(code: code),
      in: self.context(parent.model),
    )

    expect(output.requiresPayment).toEqual(false)
    expect(output.paymentAction).toBeNil()
  }

  func testStandaloneTrial_requiresPayment() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference,
    ))
    let (code, _) = try await self.claimedDevice(parentId: parent.id)

    let output = try await GetIOSDeviceSupervisionStatus.resolve(
      with: .init(code: code),
      in: self.context(parent.model),
    )

    expect(output.requiresPayment).toEqual(true)
    expect(output.paymentAction).toEqual(.startCheckout(tier: .light))
  }

  func testFreePlan_requiresPayment() async throws {
    let parent = try await self.parent()
    let (code, _) = try await self.claimedDevice(parentId: parent.id)

    let output = try await GetIOSDeviceSupervisionStatus.resolve(
      with: .init(code: code),
      in: self.context(parent.model),
    )

    expect(output.requiresPayment).toEqual(true)
    expect(output.paymentAction).toEqual(.startCheckout(tier: .light))
  }

  func testPastDueFullRequiresBillingPortal() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .full
      $1.stripeStatus = .pastDue
    }
    let (code, _) = try await self.claimedDevice(parentId: parent.id)

    let output = try await GetIOSDeviceSupervisionStatus.resolve(
      with: .init(code: code),
      in: self.context(parent.model),
    )

    expect(output.requiresPayment).toEqual(true)
    expect(output.paymentAction).toEqual(.openBillingPortal(config: .default))
  }
}

extension GetIOSDeviceSupervisionStatusResolverTests {
  func claimedDevice(parentId: Parent.Id) async throws -> (Int, IOSDevice) {
    let child = try await self.db.create(Child(parentId: parentId, name: "Test Child"))
    let code = uniqueClaimCode()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      code: code,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))
    return (code, device)
  }
}
