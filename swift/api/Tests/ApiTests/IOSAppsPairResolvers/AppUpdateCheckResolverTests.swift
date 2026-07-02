import DuetSQL
import GertieApp
import IOSAppsRoute
import XCTest
import XExpect

@testable import Api

final class AppUpdateCheckResolverTests: ApiTestCase, @unchecked Sendable {
  func testReturnsStatusWithoutWritingInstallMetadata() async throws {
    let input = AppUpdateCheckRequest(
      app: .blocker,
      deviceId: UUID(11),
      appVersion: "1.8.0",
      buildNumber: "100",
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.5",
      locale: "en_US",
    )

    let output = try await AppUpdateCheck.resolve(with: input, in: .mock)

    let expected: AppUpdateStatus = .current(.init(nextCheckAfter: .reference + .hours(12)))
    expect(output.status).toEqual(expected)
    let json = try output.json()
    expect(json.contains("\"nextCheckAfter\":\"2001-01-01T12:00:00Z\"")).toEqual(true)

    // the unauthenticated endpoint is pure-read: it must not create device/install rows
    let installs = try await BlockerApp.Install.query()
      .where(.deviceId == IOSDevice.Id(input.deviceId))
      .all(in: self.db)
    expect(installs.isEmpty).toEqual(true)
  }
}
