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

extension StripeEvent {
  static func insertIdempotent(
    json: String,
    stripeEventId: String?,
    in db: any DuetSQL.Client,
  ) async throws -> StripeEvent? {
    typealias SE = StripeEvent
    let event = StripeEvent(json: json, stripeEventId: stripeEventId)
    var stmt = SQL.Statement("""
    INSERT INTO \(table: SE.self)
    (\(SE.columnName(.id)), \(SE.columnName(.json)), \
    \(SE.columnName(.stripeEventId)), \(SE.columnName(.createdAt)))
    VALUES (
    """)
    stmt.components.append(.binding(.id(event)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.string(json)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.string(stripeEventId)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.currentTimestamp))
    stmt.components.append(.sql("""
    )
    ON CONFLICT (\(SE.columnName(.stripeEventId))) DO NOTHING
    RETURNING \(SE.columnName(.id))
    """))
    let rows = try await db.execute(statement: stmt)
    return rows.isEmpty ? nil : event
  }
}
