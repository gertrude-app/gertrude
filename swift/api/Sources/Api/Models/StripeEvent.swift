import DuetSQL

@DuetModel(schema: "system", table: "stripe_events")
struct StripeEvent: Codable, Sendable {
  var id: Id
  var json: String
  var stripeEventId: String?
  var handledAt: Date?
  var createdAt = Date()

  init(
    id: Id = .init(),
    json: String,
    stripeEventId: String? = nil,
    handledAt: Date? = nil,
  ) {
    self.id = id
    self.json = json
    self.stripeEventId = stripeEventId
    self.handledAt = handledAt
  }
}

extension StripeEvent {
  static func recordReceipt(
    json: String,
    stripeEventId: String?,
    in db: any DuetSQL.Client,
  ) async throws -> StripeEvent {
    try await db.findOrCreate(
      StripeEvent(json: json, stripeEventId: stripeEventId),
      conflictOn: [.stripeEventId],
    )
  }
}
