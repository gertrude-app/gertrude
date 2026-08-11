import XCTest
import XExpect

@testable import Api

final class PersonMacSettingsResolverTests: ApiTestCase, @unchecked Sendable {
  func testGetsMonitoringSettingsForPersonWithMac() async throws {
    let person = try await self.child(with: {
      $0.keyloggingEnabled = false
      $0.showSuspensionActivity = false
      $0.screenshotsEnabled = true
      $0.screenshotsResolution = 1440
      $0.screenshotsFrequency = 90
      $0.filteringDisabled = true
    }).withDevice()

    let output = try await GetPersonMacSettings.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )

    expect(output.keyloggingEnabled).toBeFalse()
    expect(output.showSuspensionActivity).toBeFalse()
    expect(output.screenshots.enabled).toBeTrue()
    expect(output.screenshots.resolution).toEqual(1440)
    expect(output.screenshots.frequency).toEqual(90)
    expect(output.screenshots.canBeDisabled).toBeFalse()
    expect(output.internetFiltering.enabled).toBeFalse()
    expect(output.internetFiltering.canBeDisabled).toBeFalse()
    expect(output.hasMacDevices).toBeTrue()
  }

  func testGetsMonitoringSettingsForPersonWithoutMac() async throws {
    let person = try await self.child()

    let output = try await GetPersonMacSettings.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )

    expect(output.keyloggingEnabled).toBeTrue()
    expect(output.showSuspensionActivity).toBeTrue()
    expect(output.screenshots.enabled).toBeTrue()
    expect(output.screenshots.resolution).toEqual(1000)
    expect(output.screenshots.frequency).toEqual(180)
    expect(output.screenshots.canBeDisabled).toBeTrue()
    expect(output.internetFiltering.enabled).toBeTrue()
    expect(output.internetFiltering.canBeDisabled).toBeFalse()
    expect(output.hasMacDevices).toBeFalse()
  }

  func testGetsWarningsForAvailablePublicKeychains() async throws {
    let person = try await self.child()
    let keychainOwner = try await self.parent()
    let warning = "Image search results may include inappropriate content."
    let keychain = try await self.db.create(Keychain.random {
      $0.parentId = keychainOwner.id
      $0.isPublic = true
      $0.warning = warning
    })

    let output = try await GetPersonMacSettings.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )

    expect(output.internetFiltering.availableKeychains.first { $0.id == keychain.id }?.warning)
      .toEqual(warning)
  }

  func testCannotGetMacSettingsForPersonFromAnotherAccount() async throws {
    let person = try await self.child()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await GetPersonMacSettings.resolve(
        with: .init(personId: person.id),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")
  }

  func testGetsInternetFilteringCapabilityFromAllConnectedMacVersions() async throws {
    let child = try await self.child()
    let person = try await child.withDevice(computer: {
      $0.filterVersion = .init("2.9.0")!
    })
    _ = try await child.withDevice(computer: {
      $0.filterVersion = .init("2.9.1")!
    })

    let output = try await GetPersonMacSettings.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )

    expect(output.internetFiltering.enabled).toBeTrue()
    expect(output.internetFiltering.canBeDisabled).toBeTrue()
    expect(output.internetFiltering.supportsAlwaysBlocked).toBeFalse()
  }
}
