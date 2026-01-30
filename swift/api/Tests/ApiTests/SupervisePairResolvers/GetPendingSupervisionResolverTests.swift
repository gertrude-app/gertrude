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
    let device = try await self.db.create(IOSApp.Device.random {
      $0.childId = child.id
    })
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
    ))

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

  func testCodeNotClaimed_throwsSameErrorAsNotFound() async throws {
    let device = try await self.db.create(IOSApp.Device.random {
      $0.childId = nil
    })
    let code = Int.random(in: 100_000 ... 999_999)
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: nil, // <-- not claimed
    ))

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetPendingSupervision.resolve(
          with: .init(code: code, platform: "macos"),
          in: .mock,
        )
      }
    }.toContain("not found")
  }

  func testCodeExpired_throwsExpiredError() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let code = Int.random(in: 100_000 ... 999_999)
    let device = try await self.db.create(IOSApp.Device.random {
      $0.childId = child.id
    })
    try await self.db.create(IOSApp.Supervision(
      deviceId: device.id,
      claimCode: code,
      claimCodeExpiresAt: .reference - .days(1), // <-- expired
      claimedAt: .reference - .days(8),
    ))

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
