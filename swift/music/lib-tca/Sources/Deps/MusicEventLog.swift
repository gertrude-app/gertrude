import Dependencies
import Foundation
import GertieApp
import GertieTcaFeatures

enum LogDomain: String {
  case playback
  case library
  case setup
  case subs = "subscription"
}

@discardableResult
func log(
  _ level: EventLevel,
  _ domain: LogDomain,
  _ eventId: String,
  detail: String? = nil,
) -> Task<Void, Never> {
  postAppEvent(.music, level, domain.rawValue, eventId, detail: detail, deviceId: currentDeviceId)
}

@discardableResult
func log(
  _ level: EventLevel,
  _ eventId: String,
  detail: String? = nil,
) -> Task<Void, Never> {
  postAppEvent(.music, level, nil, eventId, detail: detail, deviceId: currentDeviceId)
}

private func currentDeviceId() async -> UUID? {
  @Dependency(\.device) var device
  return await device.vendorId()
}
