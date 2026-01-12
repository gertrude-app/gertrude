import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MarkSupervisionVerifiedResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_setsIsSupervisedAndInsertsEvent() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let pending = try await self.db.create(IOSApp.PendingSupervision.random {
      $0.claimedChildId = child.id
    })
    let device = try await self.db.create(IOSApp.Device.random {
      $0.childId = child.id
      $0.vendorId = .init(pending.vendorId)
      $0.isSupervised = false
    })

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await MarkSupervisionVerified.resolve(with: .init(code: pending.code), in: .mock)
    }

    let updatedDevice = try await self.db.find(device.id)
    expect(updatedDevice.isSupervised).toEqual(true)

    let events = try await IOSEvent.query()
      .where(.iosDeviceId == device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events[0].detail!).toContain("supervision_verified")
    expect(events[0].kind).toEqual(.supervision)
  }

  func testCodeNotFound_throwsError() async throws {
    try await expectErrorFrom {
      try await MarkSupervisionVerified.resolve(
        with: .init(code: Int.random(in: 100_000 ... 999_999)),
        in: .mock,
      )
    }.toContain("not found")
  }

  func testCodeExpired_throwsError() async throws {
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
        try await MarkSupervisionVerified.resolve(with: .init(code: pending.code), in: .mock)
      }
    }.toContain("expired")
  }
}
