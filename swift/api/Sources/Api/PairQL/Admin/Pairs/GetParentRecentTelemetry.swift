import DuetSQL
import Foundation
import PairQL

struct GetParentRecentTelemetry: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var parentId: Parent.Id
    var sinceHours: Int
    var limit: Int
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
    var ipAddress: String?
    var userAgent: String?
    var numRequestBytes: Int?
    var numResponseBytes: Int?
  }

  typealias Output = [Row]
}

extension GetParentRecentTelemetry: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let hours = max(1, input.sinceHours)
    let limit = max(1, min(input.limit, 200))
    let bindings: [Postgres.Data] = [
      .uuid(input.parentId),
      .int(hours),
      .int(limit),
    ]
    let rows = try await context.db.customQuery(
      ParentTelemetryQuery.self,
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
        ipAddress: $0.ipAddress,
        userAgent: $0.userAgent,
        numRequestBytes: $0.numRequestBytes,
        numResponseBytes: $0.numResponseBytes,
      )
    }
  }
}

private struct ParentTelemetryQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count == 3 else {
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
    let parentId = RouteTelemetry.columnName(.parentId)
    let ipAddress = RouteTelemetry.columnName(.ipAddress)
    let userAgent = RouteTelemetry.columnName(.userAgent)
    let numRequestBytes = RouteTelemetry.columnName(.numRequestBytes)
    let numResponseBytes = RouteTelemetry.columnName(.numResponseBytes)

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
      \(requestId) AS request_id,
      \(ipAddress) AS ip_address,
      \(userAgent) AS user_agent,
      \(numRequestBytes) AS num_request_bytes,
      \(numResponseBytes) AS num_response_bytes
    FROM \(table: RouteTelemetry.self)
    WHERE \(parentId) =
    """)
    stmt.components.append(.sql(" "))
    stmt.components.append(.binding(bindings[0]))
    stmt.components.append(.sql(" AND \(createdAt) >= now() - make_interval(hours => ("))
    stmt.components.append(.binding(bindings[1]))
    stmt.components.append(.sql(")::int) ORDER BY \(createdAt) DESC LIMIT "))
    stmt.components.append(.binding(bindings[2]))
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
  var ipAddress: String?
  var userAgent: String?
  var numRequestBytes: Int?
  var numResponseBytes: Int?
}
