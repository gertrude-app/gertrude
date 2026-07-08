import BlockerRoute
import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class ConnectDeviceResolverTests: ApiTestCase, @unchecked Sendable {
  func testConnectIOSDeviceHappyPath() async throws {
    let child = try await self.child()
    let vendorId = UUID()
    let data = try await withDependencies {
      $0.verificationCode = .liveValue
      $0.uuid = .incrementing
    } operation: {
      let code = await with(dependency: \.ephemeral)
        .createPendingAppConnection(child.id)
      return try await ConnectDevice_v2.resolve(
        with: .init(
          verificationCode: code,
          vendorId: vendorId,
          modelIdentifier: "iPhone14,2",
          appVersion: "1.5.0",
          iosVersion: "18.4.0",
        ),
        in: .mock,
      )
    }

    expect(data).toEqual(.init(
      childId: child.id.rawValue,
      token: .init(2),
      deviceId: vendorId,
      childName: child.name,
    ))
  }

  func testConnectIOSDeviceWithStaleSupervisionRowDoesNotReportGertrudeSupervision() async throws {
    let child = try await self.child()
    let vendorId = UUID()
    let device = try await self.db.create(IOSDevice.random {
      $0.id = .init(vendorId)
    })
    try await self.createClaim(
      .blockerSupervise,
      device.id,
      code: Int.random(in: 100_000 ... 999_999),
    )
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let data = try await withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      let code = await with(dependency: \.ephemeral)
        .createPendingAppConnection(child.id)
      return try await ConnectDevice_v2.resolve(
        with: .init(
          verificationCode: code,
          vendorId: vendorId,
          modelIdentifier: device.modelIdentifier,
          appVersion: "1.5.0",
          iosVersion: device.iosVersion,
        ),
        in: .mock,
      )
    }

    expect(data.childId).toEqual(child.id.rawValue)
    expect(data.deviceId).toEqual(vendorId)
    expect(data.childName).toEqual(child.name)
    expect(data.supervised).toBeNil()
  }

  func testConnectStampsLegacyAmIapWhenDeviceHasQualifyingPurchase() async throws {
    let child = try await self.child()
    let vendorId = UUID()
    try await self.db.create(IOSDevice(
      id: .init(vendorId),
      modelIdentifier: "iPhone14,2",
      iosVersion: "18.4.0",
    ))
    // a qualifying historical AM IAP recorded against this physical device
    var event = try await self.db.create(PodcastEvent(
      eventId: "af0a338f",
      domain: "subscription",
      detail: "originalID: 123456789012345", // len 15 -> host purchase
      deviceId: .init(vendorId),
      modelIdentifier: "iPhone14,2",
      appVersion: "1.4.0",
      iosVersion: "18.4.0",
    ))
    try await event.modifyCreatedAt(.exact(.reference)) // clean whole-second timestamp

    _ = try await withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      let code = await with(dependency: \.ephemeral)
        .createPendingAppConnection(child.id)
      return try await ConnectDevice_v2.resolve(
        with: .init(
          verificationCode: code,
          vendorId: vendorId,
          modelIdentifier: "iPhone14,2",
          appVersion: "1.5.0",
          iosVersion: "18.4.0",
        ),
        in: .mock,
      )
    }

    // stamped at connect time so AM cross-app detection later honors grandfathering
    // instead of silently dropping a legacy customer's access
    let identity = try await child.parent.model.ensureBillingIdentity(in: self.db)
    expect(identity.legacyAmIapPaidAt).toEqual(.reference)
  }

  func testConnectDoesNotStampLegacyWhenNoQualifyingPurchase() async throws {
    let child = try await self.child()
    let vendorId = UUID()

    _ = try await withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      let code = await with(dependency: \.ephemeral)
        .createPendingAppConnection(child.id)
      return try await ConnectDevice_v2.resolve(
        with: .init(
          verificationCode: code,
          vendorId: vendorId,
          modelIdentifier: "iPhone14,2",
          appVersion: "1.5.0",
          iosVersion: "18.4.0",
        ),
        in: .mock,
      )
    }

    let identity = try await child.parent.model.billingIdentity(in: self.db)
    expect(identity?.legacyAmIapPaidAt).toBeNil()
  }
}
