import BlockerRoute
import Dependencies
import DuetSQL
import Foundation
import GertieApp
import XCTest
import XExpect

@testable import Api

final class BlockerResolverTests: ApiTestCase, @unchecked Sendable {
  func testLogIOSEvent() async throws {
    let eventId = UUID().uuidString
    let vendorId = UUID()
    _ = try await LogIOSEvent_v2.resolve(
      with: .init(
        eventId: eventId,
        kind: "event",
        modelIdentifier: "iPhone18,2",
        iOSVersion: "18.0.1",
        appVersion: "1.5.0",
        vendorId: vendorId,
        detail: "first launch",
      ),
      in: .mock,
    )

    let retrieved = try await IOSEvent.query()
      .where(.eventId == eventId)
      .first(in: self.db)

    expect(retrieved.level).toEqual(.info)
    expect(retrieved.domain).toEqual(nil)
    expect(retrieved.modelIdentifier).toEqual("iPhone18,2")
    expect(retrieved.iosVersion).toEqual("18.0.1")
    expect(retrieved.appVersion).toEqual("1.5.0")
    expect(retrieved.deviceId).toEqual(.init(vendorId))
    expect(retrieved.detail).toEqual("first launch")

    let device = try await IOSDevice.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone18,2")
    expect(device.iosVersion).toEqual("18.0.1")
    let install = try await device.blockerInstall(in: self.db)
    expect(install.appVersion).toEqual("1.5.0")
  }

  func testLogIOSEvent_legacy() async throws {
    let eventId = UUID().uuidString
    let vendorId = UUID()
    _ = try await LogIOSEvent.resolve(
      with: .init(
        eventId: eventId,
        kind: "event",
        deviceType: "iPhone",
        iOSVersion: "18.0.1",
        vendorId: vendorId,
        detail: "first launch",
      ),
      in: .mock,
    )

    let retrieved = try await IOSEvent.query()
      .where(.eventId == eventId)
      .first(in: self.db)

    expect(retrieved.level).toEqual(.info)
    expect(retrieved.domain).toEqual(nil)
    expect(retrieved.modelIdentifier).toEqual("iPhone,unknown")
    expect(retrieved.iosVersion).toEqual("18.0.1")
    expect(retrieved.appVersion).toEqual("0.0.0")
    expect(retrieved.deviceId).toEqual(.init(vendorId))
    expect(retrieved.detail).toEqual("first launch")

    let device = try await IOSDevice.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone,unknown")
  }

  func testDeviceShouldUpdateModelIdentifier() {
    func device(_ modelIdentifier: String) -> IOSDevice {
      IOSDevice(
        id: .init(),
        modelIdentifier: modelIdentifier,
        iosVersion: "18.0",
      )
    }
    expect(device("iPhone,unknown").shouldUpdateModelIdentifier(to: "iPhone14,2")).toEqual(true)
    expect(device("iPhone14,2").shouldUpdateModelIdentifier(to: "iPhone14,3")).toEqual(true)
    expect(device("iPhone14,2").shouldUpdateModelIdentifier(to: "iPhone14,2")).toEqual(false)
    expect(device("iPhone14,2").shouldUpdateModelIdentifier(to: "iPhone,unknown")).toEqual(false)
    expect(device("iPad,unknown").shouldUpdateModelIdentifier(to: "iPad,unknown")).toEqual(false)
    expect(device("iPhone14,2").shouldUpdateModelIdentifier(to: "iPhone")).toEqual(false)
    expect(device("iPhone14,2").shouldUpdateModelIdentifier(to: "iPad")).toEqual(false)
    expect(device("iPhone,unknown").shouldUpdateModelIdentifier(to: "iPhone")).toEqual(false)
  }

  func testLogIOSEvent_v2_backfillsLegacyDevice() async throws {
    let vendorId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(vendorId),
      modelIdentifier: "iPhone,unknown",
      iosVersion: "17.0",
    ))

    _ = try await LogIOSEvent_v2.resolve(
      with: .init(
        eventId: UUID().uuidString,
        kind: "event",
        modelIdentifier: "iPhone14,2",
        iOSVersion: "18.0.1",
        appVersion: "1.5.0",
        vendorId: vendorId,
        detail: nil,
      ),
      in: .mock,
    )

    let device = try await IOSDevice.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone14,2")
  }

  func testLogIOSEvent_v1_doesNotOverwriteGoodData() async throws {
    let vendorId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(vendorId),
      modelIdentifier: "iPhone14,2",
      iosVersion: "17.0",
    ))

    _ = try await LogIOSEvent.resolve(
      with: .init(
        eventId: UUID().uuidString,
        kind: "event",
        deviceType: "iPhone",
        iOSVersion: "18.0.1",
        vendorId: vendorId,
        detail: nil,
      ),
      in: .mock,
    )

    let device = try await IOSDevice.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone14,2")
  }
}
