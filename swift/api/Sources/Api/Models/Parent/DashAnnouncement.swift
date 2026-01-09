import Dependencies
import Duet

struct DashAnnouncement: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var kind: Kind
  var icon: String?
  var html: String
  var learnMoreUrl: String?
  var createdAt = Date()
  var deletedAt: Date

  enum Kind: String, Codable, Sendable {
    case news
    case warning
  }

  init(
    id: Id? = nil,
    parentId: Parent.Id,
    kind: Kind = .news,
    icon: String? = nil,
    html: String,
    learnMoreUrl: String? = nil,
    deletedAt: Date? = nil,
  ) {
    self.id = id ?? .init(get(dependency: \.uuid)())
    self.parentId = parentId
    self.kind = kind
    self.icon = icon
    self.html = html
    self.learnMoreUrl = learnMoreUrl
    self.deletedAt = deletedAt ?? Date(addingDays: 30)
  }
}
