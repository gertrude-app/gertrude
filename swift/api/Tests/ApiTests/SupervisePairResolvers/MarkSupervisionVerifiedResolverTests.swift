import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class MarkSupervisionVerifiedResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_setsSupervisedAtAndInsertsEvent() async throws {
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

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await MarkSupervisionVerified.resolve(
        with: .init(code: claim.code),
        in: .mock,
      )
    }

    let supervision = try await device.supervision(in: self.db)
    expect(supervision?.supervisedAt).not.toBeNil()

    let events = try await IOSEvent.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events[0].detail!).toContain("supervision_verified")
    expect(events[0].domain).toEqual("supervision")
  }

  func testCodeNotFound_throwsError() async throws {
    try await expectErrorFrom {
      try await MarkSupervisionVerified.resolve(
        with: .init(code: uniqueClaimCode()),
        in: .mock,
      )
    }.toContain("not found")
  }

  func testClaimedExpiredCode_renewsAndMarksVerified() async throws {
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

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await MarkSupervisionVerified.resolve(
        with: .init(code: claim.code),
        in: .mock,
      )
    }

    let updatedClaim = try await Claim.find(code: claim.code, in: self.db)
    expect(updatedClaim?.expiresAt).toEqual(.reference + .days(21)) // renewed

    let supervision = try await device.supervision(in: self.db)
    expect(supervision?.supervisedAt).not.toBeNil()
  }
}
