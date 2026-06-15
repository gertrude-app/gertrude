import DuetSQL
import Foundation
import XCTest
import XExpect

@testable import Api

final class MusicAppInstallTests: ApiTestCase, @unchecked Sendable {
  func testEnsureExistsCreatesDeviceAndInstall() async throws {
    let deviceId = IOSDevice.Id(UUID())

    let install = try await MusicApp.Install.ensureExists(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      in: self.db,
    )

    let device = try await self.db.find(deviceId)
    expect(device.modelIdentifier).toEqual("iPhone15,2")
    expect(device.iosVersion).toEqual("18.2")

    let persisted = try await self.db.find(install.id)
    expect(persisted.deviceId).toEqual(deviceId)
    expect(persisted.appVersion).toEqual("1.0.0")
  }

  func testEnsureExistsUpdatesExistingRowsWithoutDuplicatingInstall() async throws {
    let deviceId = IOSDevice.Id(UUID())

    _ = try await MusicApp.Install.ensureExists(
      deviceId: deviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      in: self.db,
    )
    let first = try await MusicApp.Install.query()
      .where(.deviceId == deviceId)
      .first(in: self.db)

    _ = try await MusicApp.Install.ensureExists(
      deviceId: deviceId,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.3",
      appVersion: "1.0.1",
      in: self.db,
    )

    let installs = try await MusicApp.Install.query()
      .where(.deviceId == deviceId)
      .all(in: self.db)
    expect(installs).toHaveCount(1)
    expect(installs[0].id).toEqual(first.id)
    expect(installs[0].createdAt).toEqual(first.createdAt)
    expect(installs[0].appVersion).toEqual("1.0.1")

    let device = try await self.db.find(deviceId)
    expect(device.modelIdentifier).toEqual("iPhone16,1")
    expect(device.iosVersion).toEqual("18.3")
  }

  func testConnectedDeviceIdsReturnsOnlyDevicesWithTokens() async throws {
    let connectedDeviceId = IOSDevice.Id(UUID())
    let unconnectedDeviceId = IOSDevice.Id(UUID())
    let missingDeviceId = IOSDevice.Id(UUID())

    let connectedInstall = try await MusicApp.Install.ensureExists(
      deviceId: connectedDeviceId,
      modelIdentifier: "iPhone15,2",
      iosVersion: "18.2",
      appVersion: "1.0.0",
      in: self.db,
    )
    _ = try await MusicApp.Install.ensureExists(
      deviceId: unconnectedDeviceId,
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.3",
      appVersion: "1.0.0",
      in: self.db,
    )
    try await self.db.create(MusicApp.Token(installId: connectedInstall.id))

    let connected = try await MusicApp.Token.connectedDeviceIds(
      among: [connectedDeviceId, unconnectedDeviceId, missingDeviceId],
      in: self.db,
    )

    expect(connected).toEqual(Set([connectedDeviceId]))
  }
}
