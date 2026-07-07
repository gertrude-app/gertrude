import Foundation
import GertieApp

struct PodcastEvent: Codable, Sendable {
  var id: Id
  var eventId: String
  var level: EventLevel
  var domain: String?
  var detail: String?
  var deviceId: IOSDevice.Id?
  var modelIdentifier: String
  var appVersion: String
  var iosVersion: String
  var createdAt = Date()

  init(
    id: Id = .init(),
    eventId: String,
    level: EventLevel = .info,
    domain: String? = nil,
    detail: String? = nil,
    deviceId: IOSDevice.Id?,
    modelIdentifier: String,
    appVersion: String,
    iosVersion: String,
  ) {
    self.id = id
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
