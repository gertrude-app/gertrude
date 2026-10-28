import Gertie
import XCTest
import XExpect

final class BlockedAppTests: XCTestCase {
  func testBlockedAppBlocksIfNameExactMatch() {
    let blocked = BlockedApp(identifier: "PhotoBooth")
    expect(blocked.blocks(app: .init(bundleId: "", bundleName: "PhotoBooth"), at: Date()))
      .toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "PhotoBooth"), at: Date()))
      .toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "PhotoBooth2"), at: Date()))
      .toBeFalse()
    expect(blocked.blocks(app: .init(bundleId: "", bundleName: "PhotoBooth2"), at: Date()))
      .toBeFalse()
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "FaceSkype"), at: Date()))
      .toBeFalse()
  }

  func testBlockedAppBlocksIfIdentifierEqualsBundleId() {
    let blocked = BlockedApp(identifier: "weird")
    expect(blocked.blocks(app: .init(bundleId: "weird"), at: Date())).toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "com.weird"), at: Date())).toBeFalse()
  }

  func testBlockedAppTrimsWhitespaceFromIdentifier() {
    let blocked = BlockedApp(identifier: "Firefox ")
    expect(blocked.blocks(app: .init(bundleId: "", localizedName: "Firefox"), at: Date()))
      .toBeTrue()
    expect(blocked.blocks(app: .init(bundleId: "", bundleName: "Firefox"), at: Date()))
      .toBeTrue()
    let blocked2 = BlockedApp(identifier: " com.app ")
    expect(blocked2.blocks(app: .init(bundleId: "1234ABC.com.app"), at: Date())).toBeTrue()
  }

  func testIdentifierWithDotTestedAsBundleIdFragment() {
    let blocked = BlockedApp(identifier: "com.app")
    expect(blocked.blocks(app: .init(bundleId: "com.not-match"), at: Date())).toBeFalse()
    // exact match blocked
    expect(blocked.blocks(app: .init(bundleId: "com.app"), at: Date())).toBeTrue()
    // block if identifier looks like a bundle id (i.e., has a dot)
    // and is CONTAINED in the real bundle id
    expect(blocked.blocks(app: .init(bundleId: "1234ABC.com.app"), at: Date())).toBeTrue()
  }

  func testSiriIdentifiersCoverLauncherRuntimeAndUIService() {
    for identifier in SiriBundleId.allCases {
      let blocked = BlockedApp(identifier: identifier.rawValue)
      for running in SiriBundleId.allCases {
        expect(blocked.blocks(app: .init(bundleId: running.rawValue), at: Date())).toBeTrue()
      }
    }
  }

  func testSiriLauncherDoesNotBlockUnrelatedAppleServices() {
    let blocked = BlockedApp(identifier: SiriBundleId.launcher.rawValue)
    for identifier in [
      "com.apple.assistantd",
      "com.apple.assistant_service",
      "com.apple.siriinferenced",
      "com.apple.SiriTTSTrainingAgent",
      "com.apple.notificationcenterui",
      "com.apple.systemuiserver",
    ] {
      expect(blocked.blocks(app: .init(bundleId: identifier), at: Date())).toBeFalse()
    }
  }

  func testSiriAliasesRespectActiveScheduleAndDays() {
    let blocked = BlockedApp(
      identifier: SiriBundleId.launcher.rawValue,
      schedule: .init(mode: .active, days: .only(.monday), window: "09:00-17:00"),
    )
    for identifier in SiriBundleId.allCases {
      let app = RunningApp(bundleId: identifier.rawValue)
      expect(blocked.blocks(app: app, at: .day(.monday, at: "10:00"))).toBeTrue()
      expect(blocked.blocks(app: app, at: .day(.monday, at: "18:00"))).toBeFalse()
      expect(blocked.blocks(app: app, at: .day(.tuesday, at: "10:00"))).toBeFalse()
    }
  }

  func testSiriAliasesRespectInactiveSchedule() {
    let blocked = BlockedApp(
      identifier: SiriBundleId.launcher.rawValue,
      schedule: .init(mode: .inactive, days: .all, window: "09:00-17:00"),
    )
    let app = RunningApp(bundleId: SiriBundleId.app.rawValue)
    expect(blocked.blocks(app: app, at: .day(.monday, at: "10:00"))).toBeFalse()
    expect(blocked.blocks(app: app, at: .day(.monday, at: "18:00"))).toBeTrue()
  }

  func testSiriRulesKeepIndependentSchedules() {
    let blocked = [
      BlockedApp(
        identifier: SiriBundleId.launcher.rawValue,
        schedule: .init(mode: .active, days: .all, window: "09:00-10:00"),
      ),
      BlockedApp(
        identifier: SiriBundleId.app.rawValue,
        schedule: .init(mode: .active, days: .all, window: "11:00-12:00"),
      ),
    ]
    let app = RunningApp(bundleId: SiriBundleId.uiService.rawValue)
    expect(blocked.blocks(app: app, at: .day(.monday, at: "09:30"))).toBeTrue()
    expect(blocked.blocks(app: app, at: .day(.monday, at: "10:30"))).toBeFalse()
    expect(blocked.blocks(app: app, at: .day(.monday, at: "11:30"))).toBeTrue()
  }
}
