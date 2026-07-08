import AppEvents
import Dependencies
import Foundation
import GertieApp

public enum LogDomain: String {
  case checkin
  case controller
  case filter
  case onboarding
  case storage
  case supervision
}

@discardableResult
public func log(
  _ level: EventLevel,
  _ domain: LogDomain,
  _ eventId: String,
  detail: String? = nil,
) -> Task<Void, Never> {
  postAppEvent(.blocker, level, domain.rawValue, eventId, detail: detail, deviceId: currentDeviceId)
}

@discardableResult
public func log(
  _ level: EventLevel,
  _ eventId: String,
  detail: String? = nil,
) -> Task<Void, Never> {
  postAppEvent(.blocker, level, nil, eventId, detail: detail, deviceId: currentDeviceId)
}

private func currentDeviceId() async -> UUID? {
  @Dependency(\.device) var device
  return await device.deviceId()
}
