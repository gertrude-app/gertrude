import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetPendingSupervisionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_validClaimedCode_returnsChildAndDeviceInfo() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference + .days(7)
      $0.claimedAt = .reference
    })
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetPendingSupervision.resolve(
        with: .init(code: code, platform: "macos"),
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
        with: .init(code: Int.random(in: 100_000 ... 999_999), platform: "macos"),
        in: .mock,
      )
    }.toContain("not found")
  }

  func testCodeNotClaimed_throwsError() async throws {
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = nil
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference + .days(7)
    })
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

  func testCodeExpired_throwsExpiredError() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimCode = code
      $0.claimCodeExpiresAt = .reference - .days(1) // <-- expired
      $0.claimedAt = .reference - .days(8)
    })
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
    }.toContain("expired")
  }
}
