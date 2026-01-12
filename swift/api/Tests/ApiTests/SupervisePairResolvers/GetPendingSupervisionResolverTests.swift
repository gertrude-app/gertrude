import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class GetPendingSupervisionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_validClaimedCode_returnsChildAndDeviceInfo() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let pending = try await self.db.create(IOSApp.PendingSupervision.random {
      $0.claimedChildId = child.id
      $0.expiresAt = .reference + .days(7)
    })

    let output = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await GetPendingSupervision.resolve(with: .init(code: pending.code), in: .mock)
    }

    expect(output.childName).toEqual(child.name)
    expect(output.modelIdentifier).toEqual(pending.modelIdentifier)
    expect(output.modelName).toEqual(pending.modelName)
    expect(output.iosVersion).toEqual(pending.iosVersion)
  }

  func testCodeNotFound_throwsError() async throws {
    try await expectErrorFrom {
      try await GetPendingSupervision.resolve(
        with: .init(code: Int.random(in: 100_000 ... 999_999)),
        in: .mock,
      )
    }.toContain("not found")
  }

  func testCodeNotClaimed_throwsSameErrorAsNotFound() async throws {
    let pending = try await self.db.create(IOSApp.PendingSupervision.random {
      $0.claimedChildId = nil // <-- not claimed
    })

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetPendingSupervision.resolve(with: .init(code: pending.code), in: .mock)
      }
    }.toContain("not found")
  }

  func testCodeExpired_throwsExpiredError() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let pending = try await self.db.create(IOSApp.PendingSupervision.random {
      $0.claimedChildId = child.id
      $0.expiresAt = .reference - .days(1) // <-- expired
    })

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await GetPendingSupervision.resolve(with: .init(code: pending.code), in: .mock)
      }
    }.toContain("expired")
  }
}
