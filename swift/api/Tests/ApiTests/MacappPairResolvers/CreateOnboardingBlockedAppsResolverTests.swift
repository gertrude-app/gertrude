import DuetSQL
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CreateOnboardingBlockedAppsResolverTests: ApiTestCase, @unchecked Sendable {
  func testCreatesBlockedAppsForChild() async throws {
    let child = try await self.childWithComputer()

    let output = try await CreateOnboardingBlockedApps.resolve(
      with: ["com.apple.Music", "com.apple.Music", "", "nope", "com.slack.Slack"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let blockedApps = try await UserBlockedApp.query()
      .where(.childId == child.id)
      .all(in: self.db)
    expect(blockedApps).toHaveCount(2)
    expect(blockedApps.map(\.identifier)).toEqual(["com.apple.Music", "com.slack.Slack"])
    expect(blockedApps[0].schedule).toBeNil()
  }

  func testDoesNotDuplicateExistingBlockedApps() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(UserBlockedApp(
      identifier: "com.apple.Music",
      childId: child.id,
    ))

    let output = try await CreateOnboardingBlockedApps.resolve(
      with: ["com.apple.Music", "com.slack.Slack"],
      in: child.context,
    )

    expect(output).toEqual(.success)

    let blockedApps = try await UserBlockedApp.query()
      .where(.childId == child.id)
      .all(in: self.db)
    expect(blockedApps).toHaveCount(2)
  }
}
