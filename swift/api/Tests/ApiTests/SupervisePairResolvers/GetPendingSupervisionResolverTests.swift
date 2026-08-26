import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetPendingSupervisionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_validClaimedCode_returnsChildAndDeviceInfo() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      claimedAt: .reference,
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetPendingSupervision.resolve(
        with: .init(code: claim.code, platform: "macos"),
        in: .mock,
      )
    }

    expect(output.childName).toEqual(child.name)
    expect(output.deviceType).toEqual(device.deviceType)
    expect(output.modelIdentifier).toEqual(device.modelIdentifier)
    expect(output.modelName).toEqual(device.modelName)
    expect(output.iosVersion).toEqual(device.iosVersion)
  }

  func testCodeNotFound_throwsError() async throws {
    try await expectErrorFrom {
      try await GetPendingSupervision.resolve(
        with: .init(code: uniqueClaimCode(), platform: "macos"),
        in: .mock,
      )
    }.toContain("not found")
  }

  func testCodeNotClaimed_throwsError() async throws {
    let code = uniqueClaimCode()
    let device = try await self.db.create(IOSDevice.random { $0.childId = nil })
    try await self.createClaim(.blockerSupervise, device.id, code: code)
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetPendingSupervision.resolve(
          with: .init(code: code, platform: "macos"),
          in: .mock,
        )
      }
    }.toContain("Complete the claim step in the Gertrude dashboard first")
  }

  func testUnclaimedCode_throwsClaimStepError() async throws {
    let code = uniqueClaimCode()
    let device = try await self.db.create(IOSDevice.random { $0.childId = nil })
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      code: code,
      expiresAt: .reference - .days(1),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetPendingSupervision.resolve(
          with: .init(code: code, platform: "macos"),
          in: .mock,
        )
      }
    }.toContain("Complete the claim step in the Gertrude dashboard first")
  }

  func testClaimedExpiredCode_renewsAndReturnsPendingSupervision() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      expiresAt: .reference - .days(1),
      claimedAt: .reference - .days(8),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetPendingSupervision.resolve(
        with: .init(code: claim.code, platform: "macos"),
        in: .mock,
      )
    }

    expect(output.childName).toEqual(child.name)

    let updatedClaim = try await Claim.find(code: claim.code, in: self.db)
    expect(updatedClaim?.code).toEqual(claim.code)
    expect(updatedClaim?.expiresAt).toEqual(.reference + .days(21)) // renewed
  }
}
