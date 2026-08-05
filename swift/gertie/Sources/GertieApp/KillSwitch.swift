import Foundation

public enum GertrudeIOSApp: String, Codable, CaseIterable, Sendable {
  case blocker
  case music
  case podcasts

  public static let productionAPIBaseURL = URL(string: "https://api.gertrude.app")!

  public static func apiBaseURL(
    file: StaticString = #fileID,
    line: UInt = #line,
  ) -> URL {
    self.resolveAPIBaseURL(
      Bundle.main.object(forInfoDictionaryKey: "API_ENDPOINT") as? String,
      file: file,
      line: line,
    )
  }

  private static func resolveAPIBaseURL(
    _ value: String?,
    file: StaticString = #fileID,
    line: UInt = #line,
    assertionFailure: (String, StaticString, UInt) -> Void = Self.debugAssertionFailure,
  ) -> URL {
    let endpoint = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if let url = URL(string: endpoint), url.scheme != nil, url.host != nil {
      return url
    }
    assertionFailure(
      "Missing or invalid API_ENDPOINT; falling back to \(self.productionAPIBaseURL.absoluteString)",
      file,
      line,
    )
    return self.productionAPIBaseURL
  }

  private static func debugAssertionFailure(
    _ message: String,
    file: StaticString,
    line: UInt,
  ) {
    #if DEBUG
      guard !self.isRunningTestsOrPreviews else { return }
      assertionFailure(message, file: file, line: line)
    #endif
  }

  private static var isRunningTestsOrPreviews: Bool {
    NSClassFromString("XCTestCase") != nil
      || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
      || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }
}

public struct KillSwitchCheckTiming: Codable, Equatable, Sendable {
  public var nextCheckAfter: Date?

  public init(nextCheckAfter: Date? = nil) {
    self.nextCheckAfter = nextCheckAfter
  }
}

public enum KillSwitchStatus: Codable, Equatable, Sendable {
  case current(KillSwitchCheckTiming = .init())
  case suggested(KillSwitchDirective)
  case required(KillSwitchDirective)
}

public struct KillSwitchCheckRequest: Codable, Equatable, Sendable {
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

public struct KillSwitchCheckResponse: Codable, Equatable, Sendable {
  public var status: KillSwitchStatus

  public init(status: KillSwitchStatus) {
    self.status = status
  }
}

public struct KillSwitchDirective: Codable, Equatable, Identifiable, Sendable {
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
