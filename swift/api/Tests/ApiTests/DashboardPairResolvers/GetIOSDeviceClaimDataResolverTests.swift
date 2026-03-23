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
    try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .full,
      billingStatus: .paid,
      stripeId: .init("sub_123"),
      statusExpiresAt: .reference + .days(365),
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
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.5.0",
      iosVersion: "18.0",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
    ))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetIOSDeviceClaimData.resolve(with: .init(code: code), in: parent.context)
    }

    expect(output.resumeStep).toBeNil()
    expect(output.children.map(\.id)).toEqual([child.id])
  }

  func testUnclaimedExpiredCode_throwsError() async throws {
    let parent = try await self.parent()
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: nil,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.5.0",
      iosVersion: "18.0",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(1),
    ))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetIOSDeviceClaimData.resolve(with: .init(code: code), in: parent.context)
      }
    }.toContain("expired")
  }
}

extension GetIOSDeviceClaimDataResolverTests {
  private func claimedDevice(
    for parent: ParentEntities,
    supervisedAt: Date? = nil,
  ) async throws -> (device: IOSApp.Device, code: Int) {
    let code = Int.random(in: 100_000 ... 999_999)
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSApp.Device(
      id: .init(),
      childId: child.id,
      modelIdentifier: "iPhone15,2",
      appVersion: "1.5.0",
      iosVersion: "18.0",
    ))
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: supervisedAt,
    ))
    return (device, code)
  }
}
