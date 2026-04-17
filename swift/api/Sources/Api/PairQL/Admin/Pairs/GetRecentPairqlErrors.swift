import DuetSQL
import PairQL

struct GetRecentPairqlErrors: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var sinceHours: Int
    var limit: Int
    var resultFilter: String?
  }

  struct Row: PairOutput {
    var id: UUID
    var createdAt: Date
    var domain: String
    var operation: String
    var durationMs: Int
    var result: String
    var errorId: String?
    var errorType: String?
    var errorMessage: String?
    var requestId: String
  }

  typealias Output = [Row]
}

extension GetRecentPairqlErrors: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let hours = max(1, input.sinceHours)
    let limit = max(1, min(input.limit, 500))
    let allowed: Set<String> = [
      "pql_error", "convertible_error", "unexpected_error", "not_found",
    ]
    let filter = input.resultFilter.flatMap { allowed.contains($0) ? $0 : nil }

    var bindings: [Postgres.Data] = [.int(hours)]
    if let filter {
      bindings.append(.string(filter))
    }
    bindings.append(.int(limit))

    let rows = try await context.db.customQuery(
      ErrorsQuery.self,
      withBindings: bindings,
    )
    return rows.map {
      Row(
        id: $0.id,
        createdAt: $0.createdAt,
        domain: $0.domain,
        operation: $0.operation,
        durationMs: $0.durationMs,
        result: $0.result,
        errorId: $0.errorId,
        errorType: $0.errorType,
        errorMessage: $0.errorMessage,
        requestId: $0.requestId,
      )
    }
  }
}

private struct ErrorsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count >= 2 else {
      return SQL.Statement("SELECT NULL WHERE FALSE")
    }
    let id = RouteTelemetry.columnName(.id)
    let createdAt = RouteTelemetry.columnName(.createdAt)
    let domain = RouteTelemetry.columnName(.domain)
    let operation = RouteTelemetry.columnName(.operation)
    let durationMs = RouteTelemetry.columnName(.durationMs)
    let result = RouteTelemetry.columnName(.result)
    let errorId = RouteTelemetry.columnName(.errorId)
    let errorType = RouteTelemetry.columnName(.errorType)
    let errorMessage = RouteTelemetry.columnName(.errorMessage)
    let requestId = RouteTelemetry.columnName(.requestId)

    var stmt = SQL.Statement("""
    SELECT
      \(id) AS id,
      \(createdAt) AS created_at,
      \(domain) AS domain,
      \(operation) AS operation,
      \(durationMs) AS duration_ms,
      \(result) AS result,
      \(errorId) AS error_id,
      \(errorType) AS error_type,
      \(errorMessage) AS error_message,
      \(requestId) AS request_id
    FROM \(table: RouteTelemetry.self)
    WHERE \(result) <> 'ok'
      AND \(createdAt) >=
    """)
    stmt.components.append(.sql(" now() - make_interval(hours => ("))
    stmt.components.append(.binding(bindings[0]))
    stmt.components.append(.sql(")::int)"))
    if bindings.count == 3 {
      stmt.components.append(.sql(" AND \(result) = "))
      stmt.components.append(.binding(bindings[1]))
    }
    stmt.components.append(.sql(" ORDER BY \(createdAt) DESC LIMIT "))
    stmt.components.append(.binding(bindings.last!))
    return stmt
  }

  var id: UUID
  var createdAt: Date
  var domain: String
  var operation: String
  var durationMs: Int
  var result: String
  var errorId: String?
  var errorType: String?
  var errorMessage: String?
  var requestId: String
}
