import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class RecordDeviceUSBConnectionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_setsUdidAndInsertsEvent() async throws {
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
      try await RecordDeviceUSBConnection.resolve(
        with: .init(
          code: claim.code,
          udid: "00008030-001234567890802E",
          modelIdentifier: device.modelIdentifier,
        ),
        in: .mock,
      )
    }

    let updatedSupervision = try await device.supervision(in: self.db)
    expect(updatedSupervision?.udid).toEqual("00008030-001234567890802E")

    let events = try await IOSEvent.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events[0].detail!).toContain("tool_connected")
    expect(events[0].kind).toEqual(IOSEvent.Kind.supervision)
  }

  func testCodeNotFound_throwsError() async throws {
    try await expectErrorFrom {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(
          code: Int.random(in: 100_000 ... 999_999),
          udid: "fake-udid",
          modelIdentifier: "iPhone17,1",
        ),
        in: .mock,
      )
    }.toContain("not found")
  }

  func testClaimedExpiredCode_renewsAndRecordsConnection() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let claim = try await self.createClaim(
      .blockerSupervise,
      device.id,
      child.id,
      expiresAt: .reference - .days(1), // <-- expired
      claimedAt: .reference - .days(8),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(
          code: claim.code,
          udid: "fake-udid",
          modelIdentifier: device.modelIdentifier,
        ),
        in: .mock,
      )
    }

    let updatedClaim = try await Claim.find(code: claim.code, in: self.db)
    expect(updatedClaim?.expiresAt).toEqual(.reference + .days(21)) // renewed

    let updatedSupervision = try await device.supervision(in: self.db)
    expect(updatedSupervision?.udid).toEqual("fake-udid")
  }
}
