import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class RecordDeviceConnectionResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_setsUdidAndInsertsEvent() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSApp.Device.random {
      $0.childId = child.id
      $0.supervisionClaimCode = .random(in: 100_000 ... 999_999)
      $0.claimCodeExpiresAt = .reference + .days(7)
    })

    _ = try await withDependencies {
      $0.date = .constant(.reference)
    } operation: {
      try await RecordDeviceConnection.resolve(
        with: .init(
          code: device.supervisionClaimCode!,
          udid: "00008030-001234567890802E",
          modelIdentifier: device.modelIdentifier,
        ),
        in: .mock,
      )
    }

    let updatedDevice = try await self.db.find(device.id)
    expect(updatedDevice.udid).toEqual("00008030-001234567890802E")

    let events = try await IOSEvent.query()
      .where(.deviceId == device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events[0].detail!).toContain("tool_connected")
    expect(events[0].kind).toEqual(IOSEvent.Kind.supervision)
  }

  func testCodeNotFound_throwsError() async throws {
    try await expectErrorFrom {
      try await RecordDeviceConnection.resolve(
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
    let device = try await self.db.create(IOSApp.Device.random {
      $0.childId = child.id
      $0.supervisionClaimCode = .random(in: 100_000 ... 999_999)
      $0.claimCodeExpiresAt = .reference - .days(1) // <-- expired
    })

    try await expectErrorFrom {
      try await withDependencies {
        $0.date = .constant(.reference)
      } operation: {
        try await RecordDeviceConnection.resolve(
          with: .init(
            code: device.supervisionClaimCode!,
            udid: "fake-udid",
            modelIdentifier: device.modelIdentifier,
          ),
          in: .mock,
        )
      }
    }.toContain("expired")
  }
}
