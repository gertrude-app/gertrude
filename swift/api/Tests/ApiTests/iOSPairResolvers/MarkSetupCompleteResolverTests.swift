import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class MarkSetupCompleteResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_marksProfileInstalledAndReturnsChildName() async throws {
    var child = try await self.childWithIOSDevice()
    child.device.isSupervised = true
    try await self.db.update(child.device)

    let output = try await MarkSetupComplete.resolve(in: child.context)
    expect(output).toEqual(.success)

    let updated = try await self.db.find(child.device.id)
    expect(updated.isProfileInstalled).toEqual(true)

    let events = try await IOSEvent.query()
      .where(.deviceId == child.device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events.first?.kind).toEqual(.supervision)
    expect(events.first?.detail).toEqual("profile_installed_confirmed")
  }

  func testIdempotent_alreadyCompleteReturnsSuccess() async throws {
    var child = try await self.childWithIOSDevice()
    child.device.isSupervised = true
    child.device.isProfileInstalled = true
    try await self.db.update(child.device)

    let output = try await MarkSetupComplete.resolve(in: child.context)

    expect(output).toEqual(.success)
  }

  func testNotSupervised_throwsError() async throws {
    let child = try await self.childWithIOSDevice()

    try await expectErrorFrom { try await MarkSetupComplete.resolve(in: child.context) }
      .toContain("400")
  }
}
