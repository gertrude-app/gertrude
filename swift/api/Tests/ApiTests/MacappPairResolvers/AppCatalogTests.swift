import DuetSQL
import Gertie
import MacAppRoute
import XCTest
import XExpect

@testable import Api

final class AppCatalogTests: ApiTestCase, @unchecked Sendable {
  override func setUp() async throws {
    try await super.setUp()
    try await self.db.delete(all: InstalledMacApp.self)
    try await self.db.delete(all: CatalogedApp.self)
  }

  func testInstalledAppsCreatesEntries() async throws {
    let child = try await self.childWithComputer()
    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: "productivity",
            iconContentHash: "abc123",
          ),
          .init(bundleId: "us.zoom.xos", name: "Zoom", category: nil, iconContentHash: "def456"),
        ],
      ),
      in: child.context,
    )

    let catalogedApps = try await CatalogedApp.query().all(in: self.db)
    expect(catalogedApps.count).toEqual(2)

    let slack = catalogedApps.first { $0.bundleId == "com.tinyspeck.slackmacgap" }!
    expect(slack.name).toBe("Slack")
    expect(slack.category!).toBe("productivity")

    let zoom = catalogedApps.first { $0.bundleId == "us.zoom.xos" }!
    expect(zoom.name).toBe("Zoom")
    expect(zoom.category).toBeNil()

    let installed = try await InstalledMacApp.query()
      .where(.childId == child.model.id)
      .where(.computerId == child.computer.id)
      .all(in: self.db)
    expect(installed.count).toEqual(2)

    expect(output.needsIconUpload).toEqual(["com.tinyspeck.slackmacgap", "us.zoom.xos"])
  }

  func testSecondCheckInReplacesInstalledApps() async throws {
    let child = try await self.childWithComputer()

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "abc",
          ),
          .init(bundleId: "us.zoom.xos", name: "Zoom", category: nil, iconContentHash: "def"),
        ],
      ),
      in: child.context,
    )

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "abc",
          ),
          .init(
            bundleId: "com.figma.Desktop",
            name: "Figma",
            category: nil,
            iconContentHash: "ghi",
          ),
        ],
      ),
      in: child.context,
    )

    let installed = try await InstalledMacApp.query()
      .where(.childId == child.model.id)
      .where(.computerId == child.computer.id)
      .all(in: self.db)
    expect(installed.count).toEqual(2)

    let cataloged = try await CatalogedApp.query().all(in: self.db)
    expect(cataloged.count).toEqual(3)
  }

  func testUploadAppIconStoresIconAndHash() async throws {
    let child = try await self.childWithComputer()
    let iconData = Data("fake-png-data".utf8)
    let expectedHash = "abc123"

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: expectedHash,
          ),
        ],
      ),
      in: child.context,
    )

    _ = try await UploadAppIcon.resolve(
      with: .init(
        bundleId: "com.tinyspeck.slackmacgap",
        iconData: iconData,
        iconContentHash: expectedHash,
      ),
      in: child.context,
    )

    let app = try await CatalogedApp.query()
      .where(.bundleId == "com.tinyspeck.slackmacgap")
      .first(in: self.db)
    expect(app.icon).toEqual(iconData)
    expect(app.iconContentHash).toEqual(expectedHash)
  }

  func testNoIconUploadNeededWhenHashesMatch() async throws {
    let child = try await self.childWithComputer()
    let iconData = Data("fake-png-data".utf8)

    _ = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "will-differ",
          ),
        ],
      ),
      in: child.context,
    )

    _ = try await UploadAppIcon.resolve(
      with: .init(
        bundleId: "com.tinyspeck.slackmacgap",
        iconData: iconData,
        iconContentHash: "will-differ",
      ),
      in: child.context,
    )

    let app = try await CatalogedApp.query()
      .where(.bundleId == "com.tinyspeck.slackmacgap")
      .first(in: self.db)
    let serverHash = app.iconContentHash!

    let output2 = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: serverHash,
          ),
        ],
      ),
      in: child.context,
    )

    expect(output2.needsIconUpload).toBeNil()
  }

  func testNilInstalledAppsDoesNotBreak() async throws {
    let child = try await self.childWithComputer()
    let output = try await CheckIn_v2.resolve(
      with: .init(appVersion: "1.0.0", filterVersion: "3.3.3"),
      in: child.context,
    )
    expect(output.needsIconUpload).toBeNil()
  }
}
