import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class RecordDeviceUSBConnectionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_setsUdidAndInsertsEvent() async throws {
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

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await RecordDeviceUSBConnection.resolve(
        with: .init(
          code: code,
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

  func testCodeExpired_throwsError() async throws {
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
        try await RecordDeviceUSBConnection.resolve(
          with: .init(
            code: code,
            udid: "fake-udid",
            modelIdentifier: device.modelIdentifier,
          ),
          in: .mock,
        )
      }
    }.toContain("expired")
  }
}
