import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetIOSDeviceClaimDataResolverTests: ApiTestCase, @unchecked Sendable {
  func testClaimedBySameParent_freePlan_resumesAtPayment() async throws {
    let parent = try await self.parent()
    let (_, code) = try await self.claimedDevice(for: parent)

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: code), in: parent.context)
    }

    expect(output.resumeStep).toEqual(.payment)
    expect(output.children).toEqual([])
  }

  func testClaimedBySameParent_paidPlan_notSupervised_resumesAtDownloadHelper() async throws {
    let parent = try await self.parent()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_123"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(30),
    ))
    let (_, code) = try await self.claimedDevice(for: parent)

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: code), in: parent.context)
    }

    expect(output.resumeStep).toEqual(.downloadHelper)
    expect(output.children).toEqual([])
  }

  func testClaimedBySameParent_supervised_resumesAtDone() async throws {
    let parent = try await self.parent()
    let (_, code) = try await self.claimedDevice(for: parent, supervisedAt: .reference)

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: code), in: parent.context)
    }

    expect(output.resumeStep).toEqual(.done)
  }

  func testClaimedByDifferentParent_throwsError() async throws {
    let otherParent = try await self.parent()
    let (_, code) = try await self.claimedDevice(for: otherParent)
    let parent = try await self.parent()

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetIOSDeviceClaimData.resolve(with: .init(code: code), in: parent.context)
      }
    }.toContain("not found")
  }

  func testUnclaimedValidCode_returnsChildrenAndNoResumeStep() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }

    expect(output.resumeStep).toBeNil()
    expect(output.children.map(\.id)).toEqual([child.id])
  }

  func testUnclaimedAlreadyBoundCode_completesClaimAndReturnsResumeStep() async throws {
    let parent = try await self.parent()
    try await self.addPaidSubscription(for: parent.id, tier: .light)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let claim = try await self.createClaim(.blockerSupervise, device.id)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }

    expect(output.resumeStep).toEqual(.downloadHelper)
    expect(output.children).toEqual([])
    let completed = try await Claim.find(code: claim.code, in: self.db)
    expect(completed?.childId).toEqual(child.id)
    expect(completed?.claimedAt).toEqual(.reference)

    let blockGroups = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(blockGroups.isEmpty).toBeFalse()
  }

  func testUnclaimedExpiredCode_throwsError() async throws {
    let parent = try await self.parent()
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      expiresAt: .reference - .days(1),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetIOSDeviceClaimData.resolve(with: .init(code: claim.code), in: parent.context)
      }
    }.toContain("expired")
  }

  func testClaimedMissingBlockGroups_resumeCreatesThem() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      claimedAt: .reference,
    )

    let before = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(before.isEmpty).toBeTrue()

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: claim.code), in: parent.context)
    }

    expect(output.resumeStep).not.toBeNil()

    let nonOptIn = try await BlockerApp.BlockGroup.query()
      .where(.optIn == false)
      .all(in: self.db)
    let after = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(after.isEmpty).toBeFalse()
    expect(after.count).toEqual(nonOptIn.count)
  }
}

extension GetIOSDeviceClaimDataResolverTests {
  private func claimedDevice(
    for parent: ParentEntities,
    supervisedAt: Date? = nil,
  ) async throws -> (device: IOSDevice, code: Int) {
    let code = Int.random(in: 100_000 ... 999_999)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.0",
    ))
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      code: code,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: supervisedAt,
    ))
    return (device, code)
  }
}
