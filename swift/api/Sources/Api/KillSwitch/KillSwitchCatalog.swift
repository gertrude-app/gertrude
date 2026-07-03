import Foundation
import Gertie
import GertieApp

enum KillSwitchCatalog {
  struct Device: Sendable {
    var deviceId: UUID
    var appVersion: String
    var buildNumber: String?
    var modelIdentifier: String
    var iosVersion: String
    var locale: String
  }

  struct Policy: Sendable {
    var policyId: String
    var app: GertrudeIOSApp
    var suggestedBelow: Semver?
    var requiredBelow: Semver?
    var latestVersion: String?
    var minimumVersion: String?
    var requiredOn: Date?
    var title: String
    var message: String
    var appStoreUrl: String
    var remindAfter: TimeInterval?
    var nextCheckAfter: TimeInterval?

    init(
      policyId: String,
      app: GertrudeIOSApp,
      suggestedBelow: Semver? = nil,
      requiredBelow: Semver? = nil,
      latestVersion: String? = nil,
      minimumVersion: String? = nil,
      requiredOn: Date? = nil,
      title: String,
      message: String,
      appStoreUrl: String,
      remindAfter: TimeInterval? = nil,
      nextCheckAfter: TimeInterval? = nil,
    ) {
      self.policyId = policyId
      self.app = app
      self.suggestedBelow = suggestedBelow
      self.requiredBelow = requiredBelow
      self.latestVersion = latestVersion
      self.minimumVersion = minimumVersion
      self.requiredOn = requiredOn
      self.title = title
      self.message = message
      self.appStoreUrl = appStoreUrl
      self.remindAfter = remindAfter
      self.nextCheckAfter = nextCheckAfter
    }
  }

  static let policies: [Policy] = []

  static func resolve(
    app: GertrudeIOSApp,
    device: Device,
    now: Date,
    policies: [Policy] = Self.policies,
  ) -> KillSwitchStatus {
    guard let appVersion = Semver(device.appVersion) else {
      return .current(.init(nextCheckAfter: now + .hours(12)))
    }
    let policies = policies.filter { $0.app == app }

    if let policy = policies.first(where: { policy in
      policy.requiredBelow.map { appVersion < $0 } ?? false
    }) {
      return .required(Self.directive(policy, now: now))
    }

    if let policy = policies.first(where: { policy in
      policy.suggestedBelow.map { appVersion < $0 } ?? false
    }) {
      return .suggested(Self.directive(policy, now: now))
    }

    return .current(.init(nextCheckAfter: now + .hours(12)))
  }

  private static func directive(_ policy: Policy, now: Date) -> KillSwitchDirective {
    .init(
      policyId: policy.policyId,
      latestVersion: policy.latestVersion,
      minimumVersion: policy.minimumVersion,
      requiredOn: policy.requiredOn,
      title: policy.title,
      message: policy.message,
      appStoreUrl: policy.appStoreUrl,
      remindAfter: policy.remindAfter.map { now + $0 },
      nextCheckAfter: policy.nextCheckAfter.map { now + $0 },
    )
  }
}
