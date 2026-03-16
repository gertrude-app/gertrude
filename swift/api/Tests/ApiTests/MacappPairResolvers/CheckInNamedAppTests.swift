import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class CheckInNameAppsTests: ApiTestCase, @unchecked Sendable {
  func testNameTotallyUnknownApp() async throws {
    let app = RunningApp(
      bundleId: "com.\(UUID().lowercased)",
      bundleName: "Bundle Name \(UUID())",
      localizedName: "Localized Name \(UUID())",
      launchable: true,
    )

    try await self.nameApps([app])

    let retrieved = try await UnidentifiedApp.query()
      .where(.bundleId == app.bundleId)
      .first(in: self.db)

    expect(retrieved.localizedName!).toBe(app.localizedName!)
    expect(retrieved.bundleName!).toBe(app.bundleName!)
    expect(retrieved.launchable).toEqual(true)
    expect(retrieved.count).toEqual(1)
  }

  func testNameUnidentifiedApp() async throws {
    let app = RunningApp(
      bundleId: "com.\(UUID().lowercased)",
      bundleName: "Bundle Name \(UUID())",
      launchable: false,
    )
    try await self.db.create(UnidentifiedApp(bundleId: app.bundleId, count: 33))

    try await self.nameApps([app])

    let retrieved = try await UnidentifiedApp.query()
      .where(.bundleId == app.bundleId)
      .first(in: self.db)

    expect(retrieved.localizedName).toBeNil()
    expect(retrieved.bundleName!).toBe(app.bundleName!)
    expect(retrieved.launchable).toEqual(false)
    // doesn't increment count, because we send the same apps
    // over and over in the check-in
    expect(retrieved.count).toEqual(33)
  }

  func testDoesNotInsertAlreadyIdentifiedApp() async throws {
    let identifiedApp = try await self.db.create(IdentifiedApp.random)
    let bundleId = "com.\(UUID().lowercased)"
    try await self.db.create(AppBundleId(identifiedAppId: identifiedApp.id, bundleId: bundleId))

    let app = RunningApp(bundleId: bundleId, bundleName: "Some App", launchable: true)
    try await self.nameApps([app])

    let unidentified = try await UnidentifiedApp.query()
      .where(.bundleId == bundleId)
      .all(in: self.db)

    expect(unidentified.count).toEqual(0)
  }

  func nameApps(_ namedApps: [RunningApp]) async throws {
    let child = try await self.childWithComputer()
    _ = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: "3.3.3", namedApps: namedApps),
      in: child.context,
    )
  }
}
