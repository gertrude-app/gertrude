import Foundation

public enum GertrudeIOSApp: String, Codable, CaseIterable, Sendable {
  case blocker
  case music
  case podcasts
}

public struct AppUpdateCheckTiming: Codable, Equatable, Sendable {
  public var nextCheckAfter: Date?

  public init(nextCheckAfter: Date? = nil) {
    self.nextCheckAfter = nextCheckAfter
  }
}

public enum AppUpdateStatus: Codable, Equatable, Sendable {
  case current(AppUpdateCheckTiming = .init())
  case suggested(AppUpdateDirective)
  case required(AppUpdateDirective)
}

public struct AppUpdateCheckRequest: Codable, Equatable, Sendable {
  public var app: GertrudeIOSApp
  public var deviceId: UUID
  public var appVersion: String
  public var buildNumber: String?
  public var modelIdentifier: String
  public var iosVersion: String
  public var locale: String

  public init(
    app: GertrudeIOSApp,
    deviceId: UUID,
    appVersion: String,
    buildNumber: String? = nil,
    modelIdentifier: String,
    iosVersion: String,
    locale: String,
  ) {
    self.app = app
    self.deviceId = deviceId
    self.appVersion = appVersion
    self.buildNumber = buildNumber
    self.modelIdentifier = modelIdentifier
    self.iosVersion = iosVersion
    self.locale = locale
  }
}

public struct AppUpdateCheckResponse: Codable, Equatable, Sendable {
  public var status: AppUpdateStatus

  public init(status: AppUpdateStatus) {
    self.status = status
  }
}

public struct AppUpdateDirective: Codable, Equatable, Identifiable, Sendable {
  public var policyId: String
  public var latestVersion: String?
  public var minimumVersion: String?
  public var requiredOn: Date?
  public var title: String
  public var message: String
  public var appStoreUrl: String
  public var remindAfter: Date?
  public var nextCheckAfter: Date?
  public var id: String { self.policyId }

  public init(
    policyId: String,
    latestVersion: String? = nil,
    minimumVersion: String? = nil,
    requiredOn: Date? = nil,
    title: String,
    message: String,
    appStoreUrl: String,
    remindAfter: Date? = nil,
    nextCheckAfter: Date? = nil,
  ) {
    self.policyId = policyId
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
