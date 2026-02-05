import Dependencies
import DuetSQL
import Foundation
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class iOSResolverTests: ApiTestCase, @unchecked Sendable {
  func testScreenshotUploadUrlTests() async throws {
    let signedUrl = URL(string: "/\(UUID())")!
    let child = try await self.childWithIOSDevice()
    let output = try await withDependencies {
      $0.date = .constant(.reference)
      $0.uuid = .incrementing
      $0.aws._signedS3UploadUrl = { _, _, _ in signedUrl }
    } operation: {
      try await ScreenshotUploadUrl.resolve(
        with: .init(width: 973, height: 321, createdAt: .reference),
        in: child.context,
      )
    }
    let record = try await Screenshot.query()
      .where(.iosDeviceId == child.device.id)
      .first(in: self.db)
    expect(record.width).toEqual(973)
    expect(record.height).toEqual(321)
    expect(record.filterSuspended).toEqual(true)
    expect(output.uploadUrl).toEqual(signedUrl)
  }

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

    expect(retrieved.kind).toEqual(.info)
    expect(retrieved.modelIdentifier).toEqual("iPhone18,2")
    expect(retrieved.iosVersion).toEqual("18.0.1")
    expect(retrieved.deviceId).toEqual(.init(vendorId))
    expect(retrieved.detail).toEqual("first launch")

    let device = try await IOSApp.Device.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone18,2")
    expect(device.iosVersion).toEqual("18.0.1")
    expect(device.appVersion).toEqual("1.5.0")
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

    expect(retrieved.kind).toEqual(.info)
    expect(retrieved.modelIdentifier).toEqual("iPhone,unknown")
    expect(retrieved.iosVersion).toEqual("18.0.1")
    expect(retrieved.deviceId).toEqual(.init(vendorId))
    expect(retrieved.detail).toEqual("first launch")

    let device = try await IOSApp.Device.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone,unknown")
  }

  func testDeviceShouldUpdateModelIdentifier() {
    func device(_ modelIdentifier: String) -> IOSApp.Device {
      IOSApp.Device(
        id: .init(),
        modelIdentifier: modelIdentifier,
        appVersion: "1.0",
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
    try await self.db.create(IOSApp.Device(
      id: .init(vendorId),
      modelIdentifier: "iPhone,unknown",
      appVersion: "1.0.0",
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

    let device = try await IOSApp.Device.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone14,2")
  }

  func testLogIOSEvent_v1_doesNotOverwriteGoodData() async throws {
    let vendorId = UUID()
    try await self.db.create(IOSApp.Device(
      id: .init(vendorId),
      modelIdentifier: "iPhone14,2",
      appVersion: "1.0.0",
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

    let device = try await IOSApp.Device.query()
      .where(.id == vendorId)
      .first(in: self.db)
    expect(device.modelIdentifier).toEqual("iPhone14,2")
  }
}
