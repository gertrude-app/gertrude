import DuetSQL
import IOSRoute
import XCTest
import XExpect

@testable import Api

final class MarkSupervisionProfileInstalledResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPath_marksProfileInstalledAndReturnsSuccess() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(BlockerApp.Supervision(
      deviceId: child.device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
    ))

    let output = try await MarkSupervisionProfileInstalled.resolve(in: child.context)
    expect(output).toEqual(.success)

    let supervision = try await child.device.supervision(in: self.db)!
    expect(supervision.profileInstalledAt).not.toBeNil()

    let events = try await IOSEvent.query()
      .where(.deviceId == child.device.id)
      .all(in: self.db)
    expect(events).toHaveCount(1)
    expect(events.first?.kind).toEqual(.supervision)
    expect(events.first?.detail).toEqual("profile_installed_confirmed")
  }

  func testIdempotent_alreadyCompleteReturnsSuccess() async throws {
    let child = try await self.childWithIOSDevice()
    try await self.db.create(BlockerApp.Supervision(
      deviceId: child.device.id,
      claimCode: .random(in: 100_000 ... 999_999),
      claimCodeExpiresAt: .reference + .days(7),
      claimedAt: .reference,
      supervisedAt: .reference,
      profileInstalledAt: .reference,
    ))

    let output = try await MarkSupervisionProfileInstalled.resolve(in: child.context)
    expect(output).toEqual(.success)
  }

  func testNoSupervision_throwsError() async throws {
    let child = try await self.childWithIOSDevice()
    try await expectErrorFrom {
      try await MarkSupervisionProfileInstalled.resolve(in: child.context)
    }
    .toContain("400")
  }
}
