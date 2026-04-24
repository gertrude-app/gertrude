import Dependencies
import Duet

struct MarketingEmailSend: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var campaign: String
  var createdAt = Date()

  init(id: Id? = nil, parentId: Parent.Id, campaign: String) {
    self.id = id ?? .init(get(dependency: \.uuid)())
    self.parentId = parentId
    self.campaign = campaign
  }
}
