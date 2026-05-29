import Dependencies
import IOSRoute
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
      $0.claimCode = Int.random(in: 100_000 ... 999_999)
      $0.claimCodeExpiresAt = .reference + .days(7)
      $0.claimedAt = nil
    })
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
}
