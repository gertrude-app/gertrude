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
  }

  func testSetupAppsAreSavedDedupedInCanonicalOrder() async throws {
    var parent = try await self.parent()

    _ = try await SetAccountSetupApps.resolve(
      with: .init(apps: [.music, .mac, .music]),
      in: self.accountContext(parent),
    )

    parent.model = try await self.db.find(parent.id)
    expect(parent.model.setupApps).toEqual([.mac, .music])
    let output = try await GetAccountSetup.resolve(in: self.accountContext(parent))
    expect(output.selectedApps).toEqual([.mac, .music])
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
