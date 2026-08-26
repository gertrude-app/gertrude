import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class RequestPodcastsPinResetResolverTests: ApiTestCase, @unchecked Sendable {
  func testHappyPathReturnsConsumableCode() async throws {
    let child = try await self.childWithIOSDevice()
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: child.device.id, appVersion: "1.6.0"),
    )

    let output = try await withDependencies {
      $0.verificationCode = .liveValue
    } operation: {
      try await RequestPodcastsPinReset.resolve(
        with: .init(deviceId: child.device.id),
        in: self.accountContext(child.parent),
      )
    }

    expect(output.expiresAt).toEqual(.reference + .minutes(60))
    let consumed = await get(dependency: \.ephemeral).consumePinResetCode(output.code)
    expect(consumed).toEqual(install.id)
  }

  func testCannotResetPinForDeviceFromAnotherAccount() async throws {
    let child = try await self.childWithIOSDevice()
    let install = try await self.db.create(
      PodcastApp.Install(deviceId: child.device.id, appVersion: "1.6.0"),
    )
    try await self.db.create(PodcastApp.Token(installId: install.id))
    let otherParent = try await self.parent()

    try await expectErrorFrom {
      try await RequestPodcastsPinReset.resolve(
        with: .init(deviceId: child.device.id),
        in: self.accountContext(otherParent),
      )
    }.toContain("notFound")
  }
}
