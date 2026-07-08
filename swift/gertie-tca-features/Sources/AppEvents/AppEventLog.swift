import Dependencies
import Foundation
import GertieApp
import os.log

@discardableResult
public func postAppEvent(
  _ app: GertrudeIOSApp,
  _ level: EventLevel,
  _ domain: String?,
  _ eventId: String,
  detail: String?,
  deviceId: @escaping @Sendable () async -> UUID?,
) -> Task<Void, Never> {
  @Dependency(\.appEvent) var appEvent
  #if DEBUG
    appEvent.record(LoggedEvent(
      app: app,
      level: level,
      domain: domain,
      eventId: eventId,
      detail: detail,
    ))
  #endif
  return Task {
    @Dependency(\.context) var context
    guard context != .test else { return }
    let id = await deviceId()
    do {
      try await appEvent.log(app, id, eventId, level, domain, detail)
    } catch {
      os_log("[G•] error logging event %{public}s: %{public}s", eventId, String(reflecting: error))
    }
  }
}
