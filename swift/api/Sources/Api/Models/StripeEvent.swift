import DuetSQL

struct StripeEvent: Codable, Sendable {
  var id: Id
  var json: String
  var stripeEventId: String?
  var createdAt = Date()

  init(id: Id = .init(), json: String, stripeEventId: String? = nil) {
    self.id = id
    self.json = json
    self.stripeEventId = stripeEventId
  }
}
