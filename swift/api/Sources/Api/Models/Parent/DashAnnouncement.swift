import Dependencies
import DuetSQL

@DuetModel(schema: "parent", table: "dash_announcements")
struct DashAnnouncement: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var campaign: String?
  var kind: Kind
  var icon: String?
  var html: String
  var action: Action?
  var createdAt = Date()
  var deletedAt: Date

  enum Kind: String, Codable, Sendable {
    case news
    case warning
  }

  struct Action: Codable, Equatable, Sendable {
    var label: String
    var url: String
  }

  init(
    id: Id? = nil,
    parentId: Parent.Id,
    campaign: String? = nil,
    kind: Kind = .news,
    icon: String? = nil,
    html: String,
    action: Action? = nil,
    deletedAt: Date? = nil,
  ) {
    self.id = id ?? .init(get(dependency: \.uuid)())
    self.parentId = parentId
    self.campaign = campaign
    self.kind = kind
    self.icon = icon
    self.html = html
    self.action = action
    self.deletedAt = deletedAt ?? Date(addingDays: 30)
  }
}
