import Foundation

struct PodcastEvent: Codable, Sendable {
  var id: Id
  var eventId: String
  var kind: Kind
  var label: String
  var detail: String?
  var installId: UUID?
  var modelIdentifier: String
  var appVersion: String
  var iosVersion: String
  var createdAt = Date()

  init(
    id: Id = .init(),
    eventId: String,
    kind: Kind,
    label: String,
    detail: String? = nil,
    installId: UUID? = nil,
    modelIdentifier: String,
    appVersion: String,
    iosVersion: String,
  ) {
    self.id = id
    self.eventId = eventId
    self.kind = kind
    self.label = label
    self.detail = detail
    self.installId = installId
    self.modelIdentifier = modelIdentifier
    self.appVersion = appVersion
    self.iosVersion = iosVersion
  }
}

extension PodcastEvent {
  enum Kind: String, Sendable, Codable {
    case info
    case error
    case unexpected
    case subscription
  }
}
