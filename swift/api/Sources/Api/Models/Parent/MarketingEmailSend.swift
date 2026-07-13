import Dependencies
import DuetSQL

@DuetModel(schema: "parent", table: "marketing_email_sends")
struct MarketingEmailSend: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var campaign: String
  var variant: String
  var createdAt = Date()

  init(id: Id? = nil, parentId: Parent.Id, campaign: String, variant: String = "v1") {
    self.id = id ?? .init(get(dependency: \.uuid)())
    self.parentId = parentId
    self.campaign = campaign
    self.variant = variant
  }
}
