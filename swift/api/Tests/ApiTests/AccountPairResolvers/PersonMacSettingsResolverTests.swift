import Foundation
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

  func testUpdatesMonitoringSettingsAndNotifiesMacAppsOnce() async throws {
    let person = try await self.child(with: {
      $0.keyloggingEnabled = true
      $0.showSuspensionActivity = true
      $0.screenshotsEnabled = true
      $0.screenshotsResolution = 1000
      $0.screenshotsFrequency = 60
      $0.filteringDisabled = false
    })

    let output = try await UpdatePersonMacMonitoringSettings.resolve(
      with: .init(
        personId: person.id,
        keyloggingEnabled: false,
        showSuspensionActivity: false,
        screenshotsEnabled: false,
        screenshotsResolution: 800,
        screenshotsFrequency: 120,
      ),
      in: self.accountContext(person.parent),
    )

    let updated = try await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(updated.keyloggingEnabled).toBeFalse()
    expect(updated.showSuspensionActivity).toBeFalse()
    expect(updated.screenshotsEnabled).toBeFalse()
    expect(updated.screenshotsResolution).toEqual(800)
    expect(updated.screenshotsFrequency).toEqual(120)
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testAcceptsUnchangedMonitoringSettingsWithoutNotifyingMacApps() async throws {
    let person = try await self.child(with: {
      $0.keyloggingEnabled = false
      $0.showSuspensionActivity = true
      $0.screenshotsEnabled = true
      $0.screenshotsResolution = 1200
      $0.screenshotsFrequency = 60
    })

    let output = try await UpdatePersonMacMonitoringSettings.resolve(
      with: .init(
        personId: person.id,
        keyloggingEnabled: false,
        showSuspensionActivity: true,
        screenshotsEnabled: true,
        screenshotsResolution: 1200,
        screenshotsFrequency: 60,
      ),
      in: self.accountContext(person.parent),
    )

    expect(output).toEqual(.success)
    expect(sent.websocketMessages).toBeEmpty()
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
  }

  func testUpdatesInternetFilteringAndNotifiesMacApps() async throws {
    let person = try await self.child(with: {
      $0.screenshotsEnabled = true
    }).withDevice(computer: {
      $0.filterVersion = .init("2.9.0")!
    })

    let output = try await UpdatePersonMacInternetFiltering.resolve(
      with: .init(
        personId: person.id,
        filteringEnabled: false,
        keychains: [],
        alwaysBlockedGroupIds: [],
        customAlwaysBlockedDomains: [],
      ),
      in: self.accountContext(person.parent),
    )

    let updated = try await self.db.find(person.id)
    expect(output).toEqual(.success)
    expect(updated.filteringDisabled).toBeTrue()
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testUpdatesInternetFilteringKeychains() async throws {
    let person = try await self.child().withDevice(computer: {
      $0.filterVersion = .init("2.9.0")!
    })
    let first = try await self.db.create(Keychain.random {
      $0.parentId = person.parent.id
    })
    let second = try await self.db.create(Keychain.random {
      $0.parentId = person.parent.id
    })

    _ = try await UpdatePersonMacInternetFiltering.resolve(
      with: .init(
        personId: person.id,
        filteringEnabled: true,
        keychains: [.init(id: first.id, schedule: nil), .init(id: second.id, schedule: nil)],
        alwaysBlockedGroupIds: [],
        customAlwaysBlockedDomains: [],
      ),
      in: self.accountContext(person.parent),
    )

    let assigned = try await ChildKeychain.query()
      .all(in: self.db)
      .filter { $0.childId == person.model.id }
    expect(Set(assigned.map(\.keychainId))).toEqual(Set([first.id, second.id]))
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testUpdatesKeychainSchedule() async throws {
    let person = try await self.child().withDevice(computer: {
      $0.filterVersion = .init("2.9.0")!
    })
    let keychain = try await self.db.create(Keychain.random {
      $0.parentId = person.parent.id
    })
    let schedule = GetPersonMacSettings.KeychainSchedule(.init(
      mode: .active,
      days: .weekdays,
      window: .init(start: .init(hour: 8, minute: 0), end: .init(hour: 16, minute: 0)),
    ))

    _ = try await UpdatePersonMacInternetFiltering.resolve(
      with: .init(
        personId: person.id,
        filteringEnabled: true,
        keychains: [.init(id: keychain.id, schedule: schedule)],
        alwaysBlockedGroupIds: [],
        customAlwaysBlockedDomains: [],
      ),
      in: self.accountContext(person.parent),
    )

    let assignment = try await ChildKeychain.query()
      .all(in: self.db)
      .first { $0.childId == person.model.id && $0.keychainId == keychain.id }
    expect(assignment?.schedule).toEqual(schedule.ruleSchedule)
  }

  func testUpdatesAlwaysBlockedGroups() async throws {
    let person = try await self.child().withDevice(computer: {
      $0.filterVersion = .init("2.9.1")!
    })
    let adultContent = try await self.db.create(AlwaysBlockedGroup(
      name: "Adult content",
      description: "Block adult websites.",
      longDescription: "Blocks adult websites.",
    ))
    let socialMedia = try await self.db.create(AlwaysBlockedGroup(
      name: "Social media",
      description: "Block social media websites.",
      longDescription: "Blocks social media websites.",
    ))

    _ = try await UpdatePersonMacInternetFiltering.resolve(
      with: .init(
        personId: person.id,
        filteringEnabled: true,
        keychains: [],
        alwaysBlockedGroupIds: [adultContent.id, socialMedia.id],
        customAlwaysBlockedDomains: [],
      ),
      in: self.accountContext(person.parent),
    )

    let assigned = try await ChildAlwaysBlockedGroup.query()
      .all(in: self.db)
      .filter { $0.childId == person.model.id }
    expect(Set(assigned.map(\.groupId))).toEqual(Set([adultContent.id, socialMedia.id]))
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])

    let settings = try await GetPersonMacSettings.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )
    expect(settings.internetFiltering.supportsAlwaysBlocked).toBeTrue()
    expect(settings.internetFiltering.availableAlwaysBlockedGroups.map(\.id)).toEqual([
      adultContent.id,
      socialMedia.id,
    ])
    expect(Set(settings.internetFiltering.alwaysBlockedGroupIds)).toEqual(
      Set([adultContent.id, socialMedia.id]),
    )
  }

  func testUpdatesCustomAlwaysBlockedDomainsWithoutRemovingLegacyRules() async throws {
    let person = try await self.child().withDevice(computer: {
      $0.filterVersion = .init("2.9.1")!
    })
    try await self.db.create([
      ChildAlwaysBlockedRule(
        childId: person.id,
        rule: .hostnameOrSubdomain(value: " Reddit.COM "),
      ),
      ChildAlwaysBlockedRule(
        childId: person.id,
        rule: .urlContains(value: "legacy-rule"),
      ),
    ])

    let initialSettings = try await GetPersonMacSettings.resolve(
      with: .init(personId: person.id),
      in: self.accountContext(person.parent),
    )
    expect(initialSettings.internetFiltering.customAlwaysBlockedDomains).toEqual([
      "reddit.com",
    ])

    _ = try await UpdatePersonMacInternetFiltering.resolve(
      with: .init(
        personId: person.id,
        filteringEnabled: true,
        keychains: [],
        alwaysBlockedGroupIds: [],
        customAlwaysBlockedDomains: ["discord.com", "example.com"],
      ),
      in: self.accountContext(person.parent),
    )

    let updatedRules = try await ChildAlwaysBlockedRule.query()
      .all(in: self.db)
      .filter { $0.childId == person.model.id }
    let updatedDomains = updatedRules.compactMap { model -> String? in
      guard case .hostnameOrSubdomain(let domain) = model.rule else { return nil }
      return domain
    }
    expect(Set(updatedDomains)).toEqual(Set(["discord.com", "example.com"]))
    expect(updatedRules.contains { $0.rule == .urlContains(value: "legacy-rule") }).toBeTrue()
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testRejectsDisablingInternetFilteringWithoutScreenshotMonitoring() async throws {
    let person = try await self.child(with: {
      $0.screenshotsEnabled = false
    }).withDevice(computer: {
      $0.filterVersion = .init("2.9.0")!
    })

    try await expectErrorFrom {
      try await UpdatePersonMacInternetFiltering.resolve(
        with: .init(
          personId: person.id,
          filteringEnabled: false,
          keychains: [],
          alwaysBlockedGroupIds: [],
          customAlwaysBlockedDomains: [],
        ),
        in: self.accountContext(person.parent),
      )
    }.toContain("Internet filtering can only be disabled while screenshots are enabled")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.filteringDisabled).toBeFalse()
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testRejectsDisablingInternetFilteringForOutdatedMac() async throws {
    let person = try await self.child().withDevice(computer: {
      $0.filterVersion = .init("2.8.9")!
    })

    try await expectErrorFrom {
      try await UpdatePersonMacInternetFiltering.resolve(
        with: .init(
          personId: person.id,
          filteringEnabled: false,
          keychains: [],
          alwaysBlockedGroupIds: [],
          customAlwaysBlockedDomains: [],
        ),
        in: self.accountContext(person.parent),
      )
    }.toContain("Update every connected Mac before disabling internet filtering")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.filteringDisabled).toBeFalse()
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testCannotUpdateMonitoringSettingsForPersonFromAnotherAccount() async throws {
    let person = try await self.child()
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await UpdatePersonMacMonitoringSettings.resolve(
        with: .init(
          personId: person.id,
          keyloggingEnabled: false,
          showSuspensionActivity: false,
          screenshotsEnabled: false,
          screenshotsResolution: 800,
          screenshotsFrequency: 120,
        ),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.keyloggingEnabled).toBeTrue()
    expect(unchanged.showSuspensionActivity).toBeTrue()
    expect(unchanged.screenshotsEnabled).toBeTrue()
    expect(unchanged.screenshotsResolution).toEqual(1000)
    expect(unchanged.screenshotsFrequency).toEqual(180)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testRejectsDisablingScreenshotsWhenFilteringIsDisabled() async throws {
    let person = try await self.child(with: {
      $0.keyloggingEnabled = true
      $0.showSuspensionActivity = true
      $0.screenshotsEnabled = true
      $0.screenshotsResolution = 1000
      $0.screenshotsFrequency = 180
      $0.filteringDisabled = true
    })

    try await expectErrorFrom {
      try await UpdatePersonMacMonitoringSettings.resolve(
        with: .init(
          personId: person.id,
          keyloggingEnabled: false,
          showSuspensionActivity: false,
          screenshotsEnabled: false,
          screenshotsResolution: 800,
          screenshotsFrequency: 120,
        ),
        in: self.accountContext(person.parent),
      )
    }.toContain("Screenshots must stay enabled while internet filtering is disabled")

    let unchanged = try await self.db.find(person.id)
    expect(unchanged.keyloggingEnabled).toBeTrue()
    expect(unchanged.showSuspensionActivity).toBeTrue()
    expect(unchanged.screenshotsEnabled).toBeTrue()
    expect(unchanged.screenshotsResolution).toEqual(1000)
    expect(unchanged.screenshotsFrequency).toEqual(180)
    expect(sent.websocketMessages).toBeEmpty()
  }

  func testCanRepairDisabledScreenshotsWhenFilteringIsDisabled() async throws {
    let person = try await self.child(with: {
      $0.keyloggingEnabled = true
      $0.screenshotsEnabled = false
      $0.filteringDisabled = true
    })

    _ = try await UpdatePersonMacMonitoringSettings.resolve(
      with: .init(
        personId: person.id,
        keyloggingEnabled: false,
        showSuspensionActivity: person.showSuspensionActivity,
        screenshotsEnabled: true,
        screenshotsResolution: person.screenshotsResolution,
        screenshotsFrequency: person.screenshotsFrequency,
      ),
      in: self.accountContext(person.parent),
    )

    let updated = try await self.db.find(person.id)
    expect(updated.keyloggingEnabled).toBeFalse()
    expect(updated.screenshotsEnabled).toBeTrue()
    expect(sent.websocketMessages).toEqual([
      .init(.userUpdated, to: .user(person.id)),
    ])
  }

  func testHidesSuspensionActivityWhenEmphasisIsDisabled() async throws {
    var person = try await self.childWithComputer()
    var keylog = KeystrokeLine.random
    keylog.computerUserId = person.computerUser.id
    keylog.filterSuspended = true
    keylog.createdAt = .reference
    try await self.db.create(keylog)

    let range = DateRange(
      start: (Date.reference - .days(1)).isoString,
      end: (Date.reference + .days(1)).isoString,
    )
    let emphasized = try await GetPersonDayActivity.resolve(
      with: .init(personId: person.id, range: range),
      in: self.accountContext(person.parent),
    )

    guard case .keylog(let emphasizedKeylog) = emphasized.items.first else {
      XCTFail("Expected a keylog")
      return
    }
    expect(emphasizedKeylog.duringSuspension).toBeTrue()

    person.model.showSuspensionActivity = false
    try await self.db.update(person.model)
    let unembellished = try await GetPersonDayActivity.resolve(
      with: .init(personId: person.id, range: range),
      in: self.accountContext(person.parent),
    )

    guard case .keylog(let unembellishedKeylog) = unembellished.items.first else {
      XCTFail("Expected a keylog")
      return
    }
    expect(unembellishedKeylog.duringSuspension).toBeFalse()

    let combined = try await GetDayActivity.resolve(
      with: .init(range: range),
      in: self.accountContext(person.parent),
    )

    guard case .keylog(let combinedKeylog) = combined.people.first?.items.first else {
      XCTFail("Expected a keylog")
      return
    }
    expect(combinedKeylog.duringSuspension).toBeFalse()
  }

  func testEnforcesMinimumScreenshotConfigurationValues() async throws {
    let person = try await self.child()

    _ = try await UpdatePersonMacMonitoringSettings.resolve(
      with: .init(
        personId: person.id,
        keyloggingEnabled: person.keyloggingEnabled,
        showSuspensionActivity: person.showSuspensionActivity,
        screenshotsEnabled: person.screenshotsEnabled,
        screenshotsResolution: 0,
        screenshotsFrequency: 1,
      ),
      in: self.accountContext(person.parent),
    )

    let updated = try await self.db.find(person.id)
    expect(updated.screenshotsResolution).toEqual(1)
    expect(updated.screenshotsFrequency).toEqual(10)
  }
}
