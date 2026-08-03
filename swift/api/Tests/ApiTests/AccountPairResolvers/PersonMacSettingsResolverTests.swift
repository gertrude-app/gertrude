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
