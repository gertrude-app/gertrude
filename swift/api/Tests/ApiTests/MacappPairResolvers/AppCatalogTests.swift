import Dependencies
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
    let now = Date.reference.advanced(by: .days(1))

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

    _ = try await withDependencies {
      $0.date = .constant(now)
    } operation: {
      try await UploadAppIcon.resolve(
        with: .init(
          bundleId: "com.tinyspeck.slackmacgap",
          iconData: iconData,
          iconContentHash: expectedHash,
          appVersion: "4.2.1",
        ),
        in: child.context,
      )
    }

    let app = try await CatalogedApp.query()
      .where(.bundleId == "com.tinyspeck.slackmacgap")
      .first(in: self.db)
    expect(app.icon).toEqual(iconData)
    expect(app.iconContentHash).toEqual(expectedHash)
    expect(app.iconUploadedAt).toEqual(now)
    expect(app.iconSourceAppVersion).toEqual("4.2.1")
  }

  func testUploadAppIconDoesNotResetTimestampOrDowngradeSourceForSameHash() async throws {
    let child = try await self.childWithComputer()
    let originalUploadedAt = Date.reference
    try await self.db.create(CatalogedApp(
      bundleId: "com.tinyspeck.slackmacgap",
      name: "Slack",
      icon: Data("icon-data".utf8),
      iconContentHash: "abc123",
      iconUploadedAt: originalUploadedAt,
      iconSourceAppVersion: "4.2.1",
    ))

    _ = try await withDependencies {
      $0.date = .constant(originalUploadedAt + .days(10))
    } operation: {
      try await UploadAppIcon.resolve(
        with: .init(
          bundleId: "com.tinyspeck.slackmacgap",
          iconData: Data("icon-data".utf8),
          iconContentHash: "abc123",
          appVersion: "4.1.0",
        ),
        in: child.context,
      )
    }

    let app = try await CatalogedApp.query()
      .where(.bundleId == "com.tinyspeck.slackmacgap")
      .first(in: self.db)
    expect(app.iconUploadedAt).toEqual(originalUploadedAt)
    expect(app.iconSourceAppVersion).toEqual("4.2.1")
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

  func testLooseAppVersionComparison() {
    let cases: [(client: String, stored: String?, expected: ComparisonResult?)] = [
      ("16.84", "16.83", .orderedDescending),
      ("16.83", "16.84", .orderedAscending),
      ("1.0.1", "1.0", .orderedDescending),
      ("1.0", "1.0.0", .orderedSame),
      ("147.0.7727.138", "147.0.7727.137", .orderedDescending),
      ("147.0.7727.138", "148.0.0.1", .orderedAscending),
      ("2025.4", "2024", .orderedDescending),
      ("02.5.1", "2.5.0", .orderedDescending),
      ("6.7.7 (76486)", "6.7.6", .orderedDescending),
      ("v2.3.4", "2.3.4", .orderedSame),
      ("release-candidate", "release-beta", .orderedDescending),
      ("release-candidate", "release-candidate", .orderedSame),
      ("16.83", nil, .orderedDescending),
      ("", "16.83", nil),
    ]

    for testCase in cases {
      expect(LooseAppVersion.compare(testCase.client, testCase.stored))
        .toEqual(testCase.expected)
    }
  }

  func testRecentIconDoesNotUploadWhenHashDiffersWithoutAppVersion() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(CatalogedApp(
      bundleId: "com.tinyspeck.slackmacgap",
      name: "Slack",
      icon: Data("old-icon".utf8),
      iconContentHash: "old-hash",
      iconUploadedAt: .reference,
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "different-hash",
          ),
        ],
      ),
      in: child.context,
    )

    expect(output.needsIconUpload).toBeNil()
  }

  func testStaleIconUploadsWhenHashDiffersWithoutAppVersion() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(CatalogedApp(
      bundleId: "com.tinyspeck.slackmacgap",
      name: "Slack",
      icon: Data("old-icon".utf8),
      iconContentHash: "old-hash",
      iconUploadedAt: .reference - .days(91),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "different-hash",
          ),
        ],
      ),
      in: child.context,
    )

    expect(output.needsIconUpload).toEqual(["com.tinyspeck.slackmacgap"])
  }

  func testStaleIconDoesNotUploadWithoutClientAppVersionWhenSourceVersionExists() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(CatalogedApp(
      bundleId: "com.tinyspeck.slackmacgap",
      name: "Slack",
      icon: Data("old-icon".utf8),
      iconContentHash: "old-hash",
      iconUploadedAt: .reference - .days(91),
      iconSourceAppVersion: "4.2.0",
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "different-hash",
          ),
        ],
      ),
      in: child.context,
    )

    expect(output.needsIconUpload).toBeNil()
  }

  func testStaleIconUploadsWhenClientAppVersionIsNewer() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(CatalogedApp(
      bundleId: "com.tinyspeck.slackmacgap",
      name: "Slack",
      icon: Data("old-icon".utf8),
      iconContentHash: "old-hash",
      iconUploadedAt: .reference - .days(91),
      iconSourceAppVersion: "4.1.0",
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "different-hash",
            appVersion: "4.2.0",
          ),
        ],
      ),
      in: child.context,
    )

    expect(output.needsIconUpload).toEqual(["com.tinyspeck.slackmacgap"])
  }

  func testStaleIconDoesNotUploadWhenClientAppVersionIsNotNewer() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(CatalogedApp(
      bundleId: "com.tinyspeck.slackmacgap",
      name: "Slack",
      icon: Data("old-icon".utf8),
      iconContentHash: "old-hash",
      iconUploadedAt: .reference - .days(91),
      iconSourceAppVersion: "4.2.0",
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "different-hash",
            appVersion: "4.2.0",
          ),
        ],
      ),
      in: child.context,
    )

    expect(output.needsIconUpload).toBeNil()
  }

  func testStaleIconUploadsToCaptureMissingSourceAppVersion() async throws {
    let child = try await self.childWithComputer()
    try await self.db.create(CatalogedApp(
      bundleId: "com.tinyspeck.slackmacgap",
      name: "Slack",
      icon: Data("old-icon".utf8),
      iconContentHash: "old-hash",
      iconUploadedAt: .reference - .days(91),
    ))

    let output = try await CheckIn_v2.resolve(
      with: .init(
        appVersion: "2.9.0",
        filterVersion: "3.3.3",
        installedApps: [
          .init(
            bundleId: "com.tinyspeck.slackmacgap",
            name: "Slack",
            category: nil,
            iconContentHash: "different-hash",
            appVersion: "4.2.0",
          ),
        ],
      ),
      in: child.context,
    )

    expect(output.needsIconUpload).toEqual(["com.tinyspeck.slackmacgap"])
  }
}
