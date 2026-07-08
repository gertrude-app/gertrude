import Dependencies
import Foundation
import GertieApp
import IOSAppsRoute
import PairQLClient

#if os(iOS)
  import UIKit
#endif

public struct AppEventClient: Sendable {
  public var log: @Sendable (
    _ app: GertrudeIOSApp,
    _ deviceId: UUID?,
    _ eventId: String,
    _ level: EventLevel,
    _ domain: String?,
    _ detail: String?,
  ) async throws -> Void

  #if DEBUG
    public var record: @Sendable (LoggedEvent) -> Void = { _ in }
  #endif

  public init(
    log: @escaping @Sendable (
      _ app: GertrudeIOSApp,
      _ deviceId: UUID?,
      _ eventId: String,
      _ level: EventLevel,
      _ domain: String?,
      _ detail: String?,
    ) async throws -> Void,
  ) {
    self.log = log
  }
}

#if DEBUG
  public struct LoggedEvent: Equatable, Sendable {
    public let app: GertrudeIOSApp
    public let level: EventLevel
    public let domain: String?
    public let eventId: String
    public let detail: String?

    public init(
      app: GertrudeIOSApp,
      level: EventLevel,
      domain: String?,
      eventId: String,
      detail: String?,
    ) {
      self.app = app
      self.level = level
      self.domain = domain
      self.eventId = eventId
      self.detail = detail
    }
  }
#endif

extension AppEventClient: TestDependencyKey {
  public static var testValue: Self {
    Self { _, _, _, _, _, _ in }
  }
}

extension AppEventClient: DependencyKey {
  public static var liveValue: Self {
    Self { app, deviceId, eventId, level, domain, detail in
      let iosVersion = await Self.iosVersion()
      let input = LogEventRequest(
        app: app,
        eventId: eventId,
        level: level,
        domain: domain,
        detail: detail,
        deviceId: deviceId,
        modelIdentifier: IOSDeviceInfo.modelIdentifier(),
        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0",
        iosVersion: iosVersion,
      )
      _ = try await Self.pairql.call(LogAppEvent.self, .unauthed(.logEvent(input)))
    }
  }
}

public extension DependencyValues {
  var appEvent: AppEventClient {
    get { self[AppEventClient.self] }
    set { self[AppEventClient.self] = newValue }
  }
}

private extension AppEventClient {
  static var apiBaseURL: URL {
    GertrudeIOSApp.apiBaseURL()
  }

  static let pairql = PairQLClient<IOSAppsRoute>(
    endpoint: { Self.apiBaseURL },
    timeout: 10,
  )

  @MainActor
  static func iosVersion() -> String {
    #if os(iOS)
      UIDevice.current.systemVersion
    #else
      ProcessInfo.processInfo.operatingSystemVersionString
    #endif
  }
}
