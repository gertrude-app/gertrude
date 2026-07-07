import Dependencies
import Foundation
import GertieApp
import GertieTcaFeatures

enum LogDomain: String {
  case claim
  case library
  case playback
  case download
  case pin
  case subs = "subscription"
  case setup
  case review
}

enum DbEventKind: String {
  case info
  case unexpected
  case error
  case subscription
  case debug
}

@discardableResult
func log(
  _ level: EventLevel,
  _ domain: LogDomain,
  _ eventId: String,
  detail: String? = nil,
) -> Task<Void, Never> {
  logEvent(level, domain, eventId, detail: detail)
}

@discardableResult
func log(
  _ level: EventLevel,
  _ eventId: String,
  detail: String? = nil,
) -> Task<Void, Never> {
  logEvent(level, nil, eventId, detail: detail)
}

@discardableResult
private func logEvent(
  _ level: EventLevel,
  _ domain: LogDomain?,
  _ eventId: String,
  detail: String?,
) -> Task<Void, Never> {
  Task {
    dep(\.db).insertEvent(
      kind: localKind(level, domain),
      detail: detail,
      apiId: level == .debug ? nil : eventId,
    )
    await sendAppEvent(level, domain?.rawValue, eventId, detail)
  }
}

func sendAppEvent(
  _ level: EventLevel,
  _ domain: String?,
  _ eventId: String,
  _ detail: String?,
) async {
  await postAppEvent(
    .podcasts, level, domain, eventId,
    detail: detail,
  ) { dep(\.keychain).loadDeviceId() }.value
}

private func localKind(_ level: EventLevel, _ domain: LogDomain?) -> DbEventKind {
  if domain == .subs {
    return .subscription
  }
  switch level {
  case .debug: return .debug
  case .info: return .info
  case .warn: return .unexpected
  case .err, .critical: return .error
  }
}
