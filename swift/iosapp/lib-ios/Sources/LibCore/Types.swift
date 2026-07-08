import Foundation
import GertieApp

public enum MagicStrings {
  public static let gertrudeBundleIdLong: String = .gertrudeBundleIdLong
  public static let gertrudeBundleIdShort: String = .gertrudeBundleIdShort
  public static let gertrudeGroupId: String = .gertrudeGroupId

  // sentinal hostnames
  public static let readRulesSentinalHostname: String = "read-rules.xpc.gertrude.app"
  public static let refreshRulesSentinalHostname: String = "refresh-rules.xpc.gertrude.app"
  public static let dumpLogsSentinalHostname: String = "dump-logs.xpc.gertrude.app"
}

public extension String {
  static let gertrudeBundleIdLong = "WFN83LM943.com.netrivet.gertrude-ios.app"
  static let gertrudeBundleIdShort = "com.netrivet.gertrude-ios.app"
  static let gertrudeGroupId = "group.com.netrivet.gertrude-ios.app"
}

public extension UserDefaults {
  static var gertrude: UserDefaults {
    UserDefaults(suiteName: .gertrudeGroupId)!
  }
}

public extension String {
  static var pairqlBase: String {
    "\(String.gertrudeApi)/pairql/blocker"
  }

  static var gertrudeApi: String {
    GertrudeIOSApp.apiBaseURL().absoluteString
  }
}

public extension URL {
  static func profileDownload(deviceId: UUID) -> URL {
    URL(string: "\(String.gertrudeApi)/ios-profile/\(deviceId)")!
  }
}

public extension Array {
  func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map {
      Array(self[$0 ..< Swift.min($0 + size, count)])
    }
  }
}
