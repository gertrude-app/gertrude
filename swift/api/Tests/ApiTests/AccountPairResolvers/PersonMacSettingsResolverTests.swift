import Gertie
import XCTest
import XExpect

@testable import Api

final class PersonMacSettingsResolverTests: ApiTestCase, @unchecked Sendable {
  func testGetsMonitoringSettingsForPersonWithMac() async throws {
    let downtime = PlainTimeWindow(
      start: .init(hour: 21, minute: 30),
      end: .init(hour: 6, minute: 45),
    )
    let person = try await self.child(with: {
      $0.keyloggingEnabled = false
      $0.showSuspensionActivity = false
      $0.screenshotsEnabled = true
      $0.screenshotsResolution = 1440
      $0.screenshotsFrequency = 90
      $0.filteringDisabled = true
      $0.downtime = downtime
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
    expect(output.internetFiltering.downtime).toEqual(downtime)
    expect(output.hasMacDevices).toBeTrue()
  }

  func testGetsMacApps() async throws {
    let child = try await self.childWithComputer()
    let schedule = RuleSchedule(
      mode: .inactive,
      days: .all,
      window: .init(
        start: .init(hour: 8, minute: 0),
        end: .init(hour: 15, minute: 30),
      ),
    )
    let existingBlocked = try await self.db.create(BlockedMacApp(
      identifier: "com.example.Existing",
      childId: child.model.id,
    ))
    let existingUnrestricted = try await self.db.create(UnrestrictedMacApp(
      scope: .identifiedAppSlug("existing"),
      childId: child.model.id,
      schedule: schedule,
    ))

    let output = try await GetPersonMacSettings.resolve(
      with: .init(personId: child.model.id),
      in: self.accountContext(child.parent),
    )

    expect(output.apps.blocked.map(\.id)).toEqual([existingBlocked.id])
    expect(output.apps.blocked.map(\.identifier)).toEqual(["com.example.Existing"])
    expect(output.apps.unrestricted.map(\.id)).toEqual([existingUnrestricted.id])
    expect(output.apps.unrestricted.map(\.scope)).toEqual([.identifiedAppSlug("existing")])
    expect(output.apps.unrestricted.first?.schedule?.ruleSchedule).toEqual(schedule)
  }

  func testGetsPublicUnrestrictedAppsFromAssignedKeychains() async throws {
    let child = try await self.child()
    let schedule = RuleSchedule(
      mode: .active,
      days: .all,
      window: .init(
        start: .init(hour: 8, minute: 0),
        end: .init(hour: 15, minute: 30),
      ),
    )
    let publicKeychain = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "Public Apps",
      isPublic: true,
    ))
    let privateKeychain = try await self.db.create(Keychain(
      parentId: child.parent.model.id,
      name: "Private Apps",
      isPublic: false,
    ))
    try await self.db.create([
      ChildKeychain(
        childId: child.model.id,
        keychainId: publicKeychain.id,
        schedule: schedule,
      ),
      ChildKeychain(childId: child.model.id, keychainId: privateKeychain.id),
    ])
    try await self.db.create([
      Key(
        keychainId: publicKeychain.id,
        key: .skeleton(scope: .identifiedAppSlug("public-app")),
      ),
      Key(
        keychainId: publicKeychain.id,
        key: .domain(domain: "example.com", scope: .webBrowsers),
      ),
      Key(
        keychainId: privateKeychain.id,
        key: .skeleton(scope: .bundleId("com.example.Private")),
      ),
    ])

    let output = try await GetPersonMacSettings.resolve(
      with: .init(personId: child.model.id),
      in: self.accountContext(child.parent),
    )

    expect(output.apps.publicUnrestricted.map(\.keychainId)).toEqual([publicKeychain.id])
    expect(output.apps.publicUnrestricted.map(\.keychainName)).toEqual(["Public Apps"])
    expect(output.apps.publicUnrestricted.map(\.scope)).toEqual([
      .identifiedAppSlug("public-app"),
    ])
    expect(output.apps.publicUnrestricted.first?.schedule?.ruleSchedule).toEqual(schedule)
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

  func testGetsWarningsAndKeyCountsForAvailablePublicKeychains() async throws {
    let person = try await self.child()
    let keychainOwner = try await self.parent()
    let warning = "Image search results may include inappropriate content."
    let keychain = try await self.db.create(Keychain.random {
      $0.parentId = keychainOwner.id
      $0.isPublic = true
      $0.warning = warning
    })
    let ownPublicKeychain = try await self.db.create(Keychain.random {
      $0.parentId = person.parent.id
      $0.isPublic = true
    })
    try await self.db.create([
      Key(
        keychainId: keychain.id,
        key: .domain(domain: "one.example", scope: .webBrowsers),
      ),
      Key(
        keychainId: keychain.id,
        key: .domain(domain: "two.example", scope: .webBrowsers),
      ),
    ])

    let output = try await GetPersonMacSettings.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )
    let availableKeychain = output.internetFiltering.availableKeychains.first {
      $0.id == keychain.id
    }

    expect(availableKeychain?.warning).toEqual(warning)
    expect(availableKeychain?.isOwn).toEqual(false)
    expect(availableKeychain?.numKeys).toEqual(2)
    expect(
      output.internetFiltering.availableKeychains.first {
        $0.id == ownPublicKeychain.id
      }?.isOwn,
    ).toEqual(true)
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
