import XCTest
import XExpect

@testable import Api

final class AccountSetupResolverTests: ApiTestCase, @unchecked Sendable {
  func testNewAccountHasNoSetupChoicesOrProgress() async throws {
    let parent = try await self.parent()

    let output = try await GetAccountSetup.resolve(in: self.accountContext(parent))

    expect(output.selectedApps).toBeNil()
    expect(output.hasPeople).toBeFalse()
    expect(output.completedApps).toEqual([])
    expect(output.hasNotifications).toBeFalse()
  }

  func testCreatingANotificationCompletesNotificationSetup() async throws {
    let parent = try await self.parent()
    let method = try await self.db.create(Parent.NotificationMethod(
      parentId: parent.id,
      config: .email(email: "parent@example.com"),
    ))
    try await self.db.create(Parent.Notification(
      parentId: parent.id,
      methodId: method.id,
      trigger: .suspendFilterRequestSubmitted,
    ))

    let output = try await GetAccountSetup.resolve(in: self.accountContext(parent))

    expect(output.hasNotifications).toBeTrue()
  }

  func testSetupAppsAreSavedDedupedInCanonicalOrder() async throws {
    var parent = try await self.parent()

    _ = try await SetAccountSetupApps.resolve(
      with: .init(apps: [.music, .podcasts, .mac, .blocker, .music]),
      in: self.accountContext(parent),
    )

    parent.model = try await self.db.find(parent.id)
    expect(parent.model.setupApps).toEqual([.mac, .blocker, .music, .podcasts])
    let output = try await GetAccountSetup.resolve(in: self.accountContext(parent))
    expect(output.selectedApps).toEqual([.mac, .blocker, .music, .podcasts])
  }

  func testDecidingLaterStoresEmptyChoiceRatherThanNil() async throws {
    var parent = try await self.parent()

    _ = try await SetAccountSetupApps.resolve(
      with: .init(apps: []),
      in: self.accountContext(parent),
    )

    parent.model = try await self.db.find(parent.id)
    expect(parent.model.setupApps).toEqual([])
  }

  func testConnectedMacCompletesMacSetup() async throws {
    let child = try await self.childWithComputer()

    let output = try await GetAccountSetup.resolve(in: self.accountContext(child.parent))

    expect(output.hasPeople).toBeTrue()
    expect(output.completedApps).toEqual([.mac])
  }

  func testMacFirstConnectedToAnotherAccountCompletesMacSetup() async throws {
    let otherFamily = try await self.childWithComputer()
    let child = try await self.child()
    _ = try await self.db.create(ComputerUser.random {
      $0.childId = child.model.id
      $0.computerId = otherFamily.computer.id // computer record stays with the other account
    })

    let output = try await GetAccountSetup.resolve(in: self.accountContext(child.parent))

    expect(output.completedApps).toEqual([.mac])
  }

  func testConnectedBlockerCompletesBlockerSetup() async throws {
    let child = try await self.childWithIOSDevice()

    let output = try await GetAccountSetup.resolve(in: self.accountContext(child.parent))

    expect(output.completedApps).toEqual([.blocker])
  }

  func testConnectedMusicCompletesMusicSetup() async throws {
    let child = try await self.musicChild()

    let output = try await GetAccountSetup.resolve(in: self.accountContext(child.parent))

    expect(output.completedApps).toEqual([.music])
  }

  func testPersonWithoutDevicesHasNoCompletedApps() async throws {
    let child = try await self.child()

    let output = try await GetAccountSetup.resolve(in: self.accountContext(child.parent))

    expect(output.hasPeople).toBeTrue()
    expect(output.completedApps).toEqual([])
  }
}
