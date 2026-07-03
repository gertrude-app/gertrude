import Foundation
import Gertie
import GertieApp
import XCTest
import XExpect

@testable import Api

final class KillSwitchCatalogTests: XCTestCase {
  func testNoPolicyReturnsCurrent() {
    let status = KillSwitchCatalog.resolve(
      app: .blocker,
      device: self.device(appVersion: "1.2.3"),
      now: .reference,
      policies: [],
    )

    expect(status).toEqual(.current(.init(nextCheckAfter: .reference + .hours(12))))
  }

  func testSuggestedPolicy() {
    let status = KillSwitchCatalog.resolve(
      app: .podcasts,
      device: self.device(appVersion: "1.2.9"),
      now: .reference,
      policies: [
        self.policy(
          app: .podcasts,
          suggestedBelow: "1.3.0",
          latestVersion: "1.4.0",
        ),
      ],
    )

    expect(status).toEqual(.suggested(.init(
      policyId: "policy",
      latestVersion: "1.4.0",
      minimumVersion: nil,
      requiredOn: nil,
      title: "Update available",
      message: "Please update.",
      appStoreUrl: "https://apps.apple.com/app/id123",
      remindAfter: .reference + .days(3),
      nextCheckAfter: .reference + .hours(12),
    )))
  }

  func testRequiredBeatsSuggested() {
    let status = KillSwitchCatalog.resolve(
      app: .music,
      device: self.device(appVersion: "1.1.0"),
      now: .reference,
      policies: [
        self.policy(
          app: .music,
          suggestedBelow: "1.4.0",
          requiredBelow: "1.2.0",
          latestVersion: "1.4.0",
          minimumVersion: "1.2.0",
          requiredOn: .reference + .days(7),
        ),
      ],
    )

    expect(status).toEqual(.required(.init(
      policyId: "policy",
      latestVersion: "1.4.0",
      minimumVersion: "1.2.0",
      requiredOn: .reference + .days(7),
      title: "Update available",
      message: "Please update.",
      appStoreUrl: "https://apps.apple.com/app/id123",
      remindAfter: .reference + .days(3),
      nextCheckAfter: .reference + .hours(12),
    )))
  }

  func testOtherAppPoliciesAreIgnored() {
    let status = KillSwitchCatalog.resolve(
      app: .blocker,
      device: self.device(appVersion: "1.0.0"),
      now: .reference,
      policies: [self.policy(app: .podcasts, requiredBelow: "9.0.0")],
    )

    expect(status).toEqual(.current(.init(nextCheckAfter: .reference + .hours(12))))
  }

  private func device(appVersion: String) -> KillSwitchCatalog.Device {
    .init(
      deviceId: UUID(1),
      appVersion: appVersion,
      buildNumber: "10",
      modelIdentifier: "iPhone16,1",
      iosVersion: "18.5",
      locale: "en_US",
    )
  }

  private func policy(
    app: GertrudeIOSApp,
    suggestedBelow: Semver? = nil,
    requiredBelow: Semver? = nil,
    latestVersion: String? = nil,
    minimumVersion: String? = nil,
    requiredOn: Date? = nil,
  ) -> KillSwitchCatalog.Policy {
    .init(
      policyId: "policy",
      app: app,
      suggestedBelow: suggestedBelow,
      requiredBelow: requiredBelow,
      latestVersion: latestVersion,
      minimumVersion: minimumVersion,
      requiredOn: requiredOn,
      title: "Update available",
      message: "Please update.",
      appStoreUrl: "https://apps.apple.com/app/id123",
      remindAfter: .days(3),
      nextCheckAfter: .hours(12),
    )
  }
}
