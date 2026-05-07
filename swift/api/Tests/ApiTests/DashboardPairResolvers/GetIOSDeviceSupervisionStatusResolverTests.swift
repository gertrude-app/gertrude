import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetIOSDeviceSupervisionStatusResolverTests: ApiTestCase, @unchecked Sendable {
  func testPaidPlan_doesNotRequirePayment() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .light
      $1.billingStatus = .paid
      $1.stripeId = .init("sub_123")
      $1.statusExpiresAt = .distantFuture
    }
    let (code, _) = try await self.claimedDevice(parentId: parent.id)

    let output = try await GetIOSDeviceSupervisionStatus.resolve(
      with: .init(code: code),
      in: self.context(parent.model),
    )

    expect(output.requiresPayment).toEqual(false)
  }

  func testTrialingPlan_requiresPayment() async throws {
    let parent = try await self.parentWithSubscription {
      $1.tier = .full
      $1.billingStatus = .trialing
      $1.trialStartedAt = .reference
      $1.statusExpiresAt = .reference + .days(18)
    }
    let (code, _) = try await self.claimedDevice(parentId: parent.id)

    let output = try await GetIOSDeviceSupervisionStatus.resolve(
      with: .init(code: code),
      in: self.context(parent.model),
    )

    expect(output.requiresPayment).toEqual(true)
  }

  func testFreePlan_requiresPayment() async throws {
    let parent = try await self.parent()
    let (code, _) = try await self.claimedDevice(parentId: parent.id)

    let output = try await GetIOSDeviceSupervisionStatus.resolve(
      with: .init(code: code),
      in: self.context(parent.model),
    )

    expect(output.requiresPayment).toEqual(true)
  }
}

extension GetIOSDeviceSupervisionStatusResolverTests {
  func claimedDevice(parentId: Parent.Id) async throws -> (Int, IOSDevice) {
    let child = try await self.db.create(Child(parentId: parentId, name: "Test Child"))
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
    ))
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))
    return (code, device)
  }
}
