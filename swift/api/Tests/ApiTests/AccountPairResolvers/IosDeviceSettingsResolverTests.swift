import XCTest
import XExpect

@testable import Api

final class IosDeviceSettingsResolverTests: ApiTestCase, @unchecked Sendable {
  func testGetsBlockGroupCatalogAndEnabledGroups() async throws {
    let child = try await self.childWithIOSDevice()
    let group = try await self.db.create(BlockerApp.BlockGroup(
      name: "Test Group",
      description: "short",
      longDescription: "long",
    ))
    try await self.db.create(BlockerApp.DeviceBlockGroup(
      deviceId: child.device.id,
      blockGroupId: group.id,
    ))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    expect(output.deviceId).toEqual(child.device.id)
    expect(output.personId).toEqual(child.model.id)
    let blocker = try XCTUnwrap(output.blocker)
    expect(blocker.enabledBlockGroupIds).toEqual([group.id])
    expect(blocker.allBlockGroups.map(\.id).contains(group.id)).toBeTrue()
    let catalogEntry = blocker.allBlockGroups.first { $0.id == group.id }
    expect(catalogEntry?.name).toEqual("Test Group")
    expect(catalogEntry?.longDescription).toEqual("long") // UI shows this in the `?` expander
    expect(catalogEntry?.optIn).toEqual(false)
  }

  func testIncludesOptInGroupsInCatalog() async throws {
    let child = try await self.childWithIOSDevice()
    let optIn = try await self.db.create(BlockerApp.BlockGroup(
      name: "Opt In Group",
      description: "short",
      longDescription: "long",
      optIn: true,
    ))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    // dash shows opt-in groups so parents can choose them, unlike the app's own list
    let blocker = try XCTUnwrap(output.blocker)
    expect(blocker.allBlockGroups.first { $0.id == optIn.id }?.optIn).toEqual(true)
  }

  func testProfileSettingsDefaultsAndSupervisionFlag() async throws {
    let child = try await self.childWithIOSDevice()

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    let blocker = try XCTUnwrap(output.blocker)
    expect(blocker.isSupervised).toBeFalse()
    expect(blocker.profileSettings.preventProtectionRemoval).toBeTrue()
    expect(blocker.profileSettings.allowDeletingApps).toBeFalse()
    expect(blocker.profileSettings.allowFactoryReset).toBeFalse()
    expect(blocker.profileSettings.allowInstallingApps).toBeTrue()
  }

  func testReportsSupervisedDevice() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(BlockerApp.Supervision(
      deviceId: child.device.id,
      supervisedAt: Date(),
    ))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    expect(try XCTUnwrap(output.blocker).isSupervised).toBeTrue()
  }

  func testBlockerNilWhenInstallHasNoToken() async throws {
    let child = try await self.child()
    let device = try await self.db.create(IOSDevice.mock { $0.childId = child.model.id })
    // a Music/Podcasts claim binds the child and seeds block groups, but blocker unconnected
    try await self.db.create(BlockerApp.Install.mock { $0.deviceId = device.id })
    try await device.ensureBlockerBlockGroups(in: self.db)

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: device.id),
      in: self.accountContext(child.parent),
    )

    expect(output.deviceId).toEqual(device.id)
    expect(output.blocker).toBeNil() // settings would be a lie, blocker isn't connected
  }

  func testBlockerNilWhenNoInstallAtAll() async throws {
    let child = try await self.child()
    let device = try await self.db.create(IOSDevice.mock { $0.childId = child.model.id })

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: device.id),
      in: self.accountContext(child.parent),
    )

    expect(output.blocker).toBeNil()
  }

  func testPodcastsNilWhenNoInstall() async throws {
    let child = try await self.childWithIOSDevice()

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    expect(output.podcasts).toBeNil()
  }

  func testPodcastsNilWhenInstallHasNoToken() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(PodcastApp.Install(deviceId: child.device.id, appVersion: "1.6.0"))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    expect(output.podcasts).toBeNil() // matches dash: install alone isn't "connected"
  }

  func testPodcastsCarriesSubscriptionWhenConnected() async throws {
    let child = try await self.childWithIOSDevice()
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: child.device.id, appVersion: "1.6.0"),
    )
    try await self.db.create(PodcastApp.Token(installId: install.id))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    let podcasts = try XCTUnwrap(output.podcasts)
    // fresh install, so the device-level 30-day AM trial is the live entitlement
    guard case .amTrial = podcasts.subscription else {
      XCTFail("expected amTrial, got \(podcasts.subscription)")
      return
    }
  }

  func testMusicNilWhenNotConnected() async throws {
    let child = try await self.childWithIOSDevice()
    // an install with no token isn't connected, same rule as blocker and podcasts
    try await self.db.create(MusicApp.Install(deviceId: child.device.id, appVersion: "1.0.0"))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    expect(output.music).toBeNil()
  }

  func testMusicRequiresPaymentOnUnentitledAccount() async throws {
    let child = try await self.childWithIOSDevice()
    let install = try await self.db.create(
      MusicApp.Install(deviceId: child.device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: install.id))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    expect(try XCTUnwrap(output.music).requiresPayment).toBeTrue()
  }

  func testMusicDoesNotRequirePaymentOnEntitledAccount() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.addPaidSubscription(for: child.parent.model.id, tier: .medium)
    let install = try await self.db.create(
      MusicApp.Install(deviceId: child.device.id, appVersion: "1.0.0"),
    )
    try await self.db.create(MusicApp.Token(installId: install.id))

    let output = try await GetIosDeviceSettings.resolve(
      with: .init(deviceId: child.device.id),
      in: self.accountContext(child.parent),
    )

    expect(try XCTUnwrap(output.music).requiresPayment).toBeFalse()
  }

  func testCannotGetSettingsForDeviceFromAnotherAccount() async throws {
    let child = try await self.childWithIOSDevice()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await GetIosDeviceSettings.resolve(
        with: .init(deviceId: child.device.id),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")
  }

  func testUpdateBlockedGroupsReplacesEnabledSet() async throws {
    let child = try await self.childWithIOSDevice()
    let stale = try await self.db.create(BlockerApp.BlockGroup(
      name: "Stale",
      description: "short",
      longDescription: "long",
    ))
    let wanted = try await self.db.create(BlockerApp.BlockGroup(
      name: "Wanted",
      description: "short",
      longDescription: "long",
    ))
    try await self.db.create(BlockerApp.DeviceBlockGroup(
      deviceId: child.device.id,
      blockGroupId: stale.id,
    ))

    _ = try await UpdateIosDeviceBlockedGroups.resolve(
      with: .init(deviceId: child.device.id, enabledBlockGroupIds: [wanted.id]),
      in: self.accountContext(child.parent),
    )

    let enabled = try await child.device.blockGroups(in: self.db)
    expect(enabled.map(\.id)).toEqual([wanted.id]) // stale pivot removed, not merged
  }

  func testCannotUpdateBlockedGroupsForDeviceFromAnotherAccount() async throws {
    let child = try await self.childWithIOSDevice()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      _ = try await UpdateIosDeviceBlockedGroups.resolve(
        with: .init(deviceId: child.device.id, enabledBlockGroupIds: []),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")
  }

  func testUpdateProfileSettingsPersistsFlags() async throws {
    let child = try await self.childWithIOSDevice()

    _ = try await UpdateIosDeviceProfileSettings.resolve(
      with: .init(
        deviceId: child.device.id,
        preventProtectionRemoval: false,
        allowDeletingApps: true,
        allowFactoryReset: true,
        allowInstallingApps: false,
      ),
      in: self.accountContext(child.parent),
    )

    let settings = try await BlockerApp.ProfileSettings
      .ensure(for: child.device.id, in: self.db)
    expect(settings.isProfileLocked).toBeFalse()
    expect(settings.allowAppRemoval).toBeTrue()
    expect(settings.allowEraseContentAndSettings).toBeTrue()
    expect(settings.allowAppInstallation).toBeFalse()
  }

  func testCannotUpdateProfileSettingsForDeviceFromAnotherAccount() async throws {
    let child = try await self.childWithIOSDevice()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      _ = try await UpdateIosDeviceProfileSettings.resolve(
        with: .init(
          deviceId: child.device.id,
          preventProtectionRemoval: false,
          allowDeletingApps: true,
          allowFactoryReset: true,
          allowInstallingApps: false,
        ),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")
  }
}
