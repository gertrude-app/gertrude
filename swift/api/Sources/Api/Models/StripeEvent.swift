import DuetSQL

@DuetModel(schema: "system", table: "stripe_events")
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

extension StripeEvent {
  static func insertIdempotent(
    json: String,
    stripeEventId: String?,
    in db: any DuetSQL.Client,
  ) async throws -> StripeEvent? {
    try await db.create(
      StripeEvent(json: json, stripeEventId: stripeEventId),
      ignoringConflictOn: [.stripeEventId],
    )
  }
}
