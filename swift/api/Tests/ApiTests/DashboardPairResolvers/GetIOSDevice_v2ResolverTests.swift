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
    })
    try await self.db.create(MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.music).toBeNil()
    expect(output.musicConnected).toEqual(false)
  }

  func testMusicConnected_trueWhenTokenExists() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
    })
    let install = try await self.db.create(
      MusicApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: install.id))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.music?.requiresPayment).toEqual(true)
    expect(output.musicConnected).toEqual(true)
  }

  func testBlocker_nilWhenInstallExistsButNoToken() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
    })
    // bare install, no token -> a ghost from app events, never really connected
    try await self.db.create(BlockerApp.Install(deviceId: device.id, appVersion: "1.0.0"))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.blocker).toBeNil()
  }

  func testBlocker_nilWhenSupervisionPendingButNoToken() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
    })
    try await self.db.create(BlockerApp.Install(deviceId: device.id, appVersion: "1.0.0"))
    // parent-claim seeds an install + supervision row, but the token isn't minted
    // until the device checks in -- a device stuck mid-claim shouldn't show the UI
    try await self.db.create(BlockerApp.Supervision(deviceId: device.id))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.blocker).toBeNil()
  }

  func testBlocker_populatedWhenTokenExists() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
    })
    let install = try await self.db.create(
      BlockerApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(BlockerApp.Token(installId: install.id))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.blocker).not.toBeNil()
  }

  func testExtendedControls_populatedForComplimentarySupervised() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id, isComplimentary: true))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let install = try await self.db.create(
      BlockerApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(BlockerApp.Token(installId: install.id))
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference, // <-- supervised, required for exposure
    ))
    var settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: self.db)
    settings.whitelistedAppBundleIds = ["com.apple.mobilesafari"]
    settings.webAllowList = [.init(url: "https://gertrude.app", title: "Gertrude")]
    try await self.db.update(settings)

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    let controls = output.blocker?.extendedSupervisionControls
    expect(controls?.whitelistedAppBundleIds).toEqual(["com.apple.mobilesafari"])
    expect(controls?.webAllowList?.map(\.url)).toEqual(["https://gertrude.app"])
    expect(controls?.webAllowList?.map(\.title)).toEqual(["Gertrude"])
  }

  func testExtendedControls_nilWithoutCapability() async throws {
    let parent = try await self.parent() // no billing identity -> free plan
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let install = try await self.db.create(
      BlockerApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(BlockerApp.Token(installId: install.id))
    try await self.db.create(BlockerApp.Supervision(
      deviceId: device.id,
      supervisedAt: .reference,
    ))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.blocker?.isSupervised).toEqual(true)
    expect(output.blocker?.extendedSupervisionControls).toBeNil()
  }

  func testExtendedControls_nilWhenUnsupervised() async throws {
    let parent = try await self.parent()
    try await self.db.create(BillingIdentity(parentId: parent.id, isComplimentary: true))
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random { $0.childId = child.id })
    let install = try await self.db.create(
      BlockerApp.Install(deviceId: device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(BlockerApp.Token(installId: install.id))

    let output = try await GetIOSDevice_v2.resolve(with: device.id, in: parent.context)

    expect(output.blocker?.isSupervised).toEqual(false)
    expect(output.blocker?.extendedSupervisionControls).toBeNil()
  }

  func testAmInstall_populatedWhenTokenExists() async throws {
    let parent = try await self.parent()
    let child = try await self.db.create(Child.random { $0.parentId = parent.id })
    let device = try await self.db.create(IOSDevice.random {
      $0.childId = child.id
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
