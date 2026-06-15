import Dependencies
import DuetSQL
import PodcastRoute
import XCTest
import XExpect

@testable import Api

final class GetIOSDevice_v2ResolverTests: ApiTestCase, @unchecked Sendable {
  func testAmInstall_nilWhenInstallExistsButNoToken() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimedAt = .reference
    })
    try await self.db.create(PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.am).toBeNil()
  }

  func testMusicConnected_falseWhenInstallExistsButNoToken() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimedAt = .reference
    })
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.musicConnected).toEqual(false)
  }

  func testMusicConnected_trueWhenTokenExists() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimedAt = .reference
    })
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: install.id))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.musicConnected).toEqual(true)
  }

  func testAmInstall_populatedWhenTokenExists() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
      $0.claimedAt = .reference
    })
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: device.id, appVersion: "1.6.0"),
    )
    try await self.db.create(PodcastApp.Token(installId: install.id))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    let persisted = try await self.db.find(install.id)
    expect(output.am?.subscription)
      .toEqual(.amTrial(expiresAt: persisted.createdAt + .days(30)))
  }
}
