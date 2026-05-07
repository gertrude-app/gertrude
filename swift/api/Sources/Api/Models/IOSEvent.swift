import Foundation

struct IOSEvent: Codable, Sendable {
  var id: Id
  var eventId: String
  var kind: Kind
  var detail: String?
  var deviceId: IOSDevice.Id?
  var modelIdentifier: String
  var iosVersion: String
  var createdAt = Date()

  init(
    id: Id = .init(),
    eventId: String,
    kind: Kind,
    detail: String? = nil,
    deviceId: IOSDevice.Id? = nil,
    modelIdentifier: String,
    iosVersion: String,
  ) {
    self.id = id
    self.eventId = eventId
    self.kind = kind
    self.detail = detail
    self.deviceId = deviceId
    self.modelIdentifier = modelIdentifier
    self.iosVersion = iosVersion
  }
}

extension IOSEvent {
  enum Kind: String, Sendable, Codable {
    case info
    case onboarding
    case filter
    case error
    case supervision
    case checkin
  }
}
