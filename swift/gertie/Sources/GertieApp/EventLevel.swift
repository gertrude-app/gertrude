import Foundation

public enum EventLevel: String, Equatable, Codable, Sendable, CaseIterable, Comparable {
  case debug
  case info
  case warn = "warning"
  case err = "error"
  case critical

  private var order: Int {
    switch self {
    case .debug: 0
    case .info: 1
    case .warn: 2
    case .err: 3
    case .critical: 4
    }
  }

  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.order < rhs.order
  }
}

public struct LogEventRequest: Equatable, Codable, Sendable {
  public var app: GertrudeIOSApp
  public var eventId: String
  public var level: EventLevel
  public var domain: String?
  public var detail: String?
  public var deviceId: UUID?
  public var modelIdentifier: String
  public var appVersion: String
  public var iosVersion: String

  public init(
    app: GertrudeIOSApp,
    eventId: String,
    level: EventLevel,
    domain: String? = nil,
    detail: String? = nil,
    deviceId: UUID?,
    modelIdentifier: String,
    appVersion: String,
    iosVersion: String,
  ) {
    self.app = app
    self.eventId = eventId
    self.level = level
    self.domain = domain
    self.detail = detail
    self.deviceId = deviceId
    self.modelIdentifier = modelIdentifier
    self.appVersion = appVersion
    self.iosVersion = iosVersion
  }
}
