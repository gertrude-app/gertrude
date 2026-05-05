import DuetSQL
import PairQL

struct GetPairqlTelemetrySummary: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var sinceHours: Int
  }

  struct Row: PairOutput {
    var domain: String
    var operation: String
    var requestCount: Int
    var p50Ms: Int
    var p95Ms: Int
    var p99Ms: Int
    var maxMs: Int
    var okCount: Int
    var pqlErrorCount: Int
    var convertibleErrorCount: Int
    var unexpectedErrorCount: Int
    var notFoundCount: Int
    var avgRequestBytes: Int
    var avgResponseBytes: Int
    var maxResponseBytes: Int
  }

  typealias Output = [Row]
}

extension GetPairqlTelemetrySummary: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let hours = max(1, input.sinceHours)
    let rows = try await context.db.customQuery(
      SummaryQuery.self,
      withBindings: [.int(hours)],
    )
    return rows.map { row in
      Row(
        domain: row.domain,
        operation: row.operation,
        requestCount: row.requestCount,
        p50Ms: Int(row.p50Ms.rounded()),
        p95Ms: Int(row.p95Ms.rounded()),
        p99Ms: Int(row.p99Ms.rounded()),
        maxMs: row.maxMs,
        okCount: row.okCount,
        pqlErrorCount: row.pqlErrorCount,
        convertibleErrorCount: row.convertibleErrorCount,
        unexpectedErrorCount: row.unexpectedErrorCount,
        notFoundCount: row.notFoundCount,
        avgRequestBytes: row.avgRequestBytes,
        avgResponseBytes: row.avgResponseBytes,
        maxResponseBytes: row.maxResponseBytes,
      )
    }
  }
}

private struct SummaryQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard let hoursBinding = bindings.first else {
      return SQL.Statement("SELECT NULL WHERE FALSE")
    }
    let domain = RouteTelemetry.columnName(.domain)
    let operation = RouteTelemetry.columnName(.operation)
    let durationMs = RouteTelemetry.columnName(.durationMs)
    let result = RouteTelemetry.columnName(.result)
    let createdAt = RouteTelemetry.columnName(.createdAt)
    let numRequestBytes = RouteTelemetry.columnName(.numRequestBytes)
    let numResponseBytes = RouteTelemetry.columnName(.numResponseBytes)
    var stmt = SQL.Statement("""
    SELECT
      \(domain) AS domain,
      \(operation) AS operation,
      COUNT(*)::int AS request_count,
      COALESCE(percentile_cont(0.50) WITHIN GROUP (ORDER BY \(durationMs)), 0) AS p50_ms,
      COALESCE(percentile_cont(0.95) WITHIN GROUP (ORDER BY \(durationMs)), 0) AS p95_ms,
      COALESCE(percentile_cont(0.99) WITHIN GROUP (ORDER BY \(durationMs)), 0) AS p99_ms,
      COALESCE(MAX(\(durationMs)), 0)::int AS max_ms,
      COUNT(*) FILTER (WHERE \(result) = 'ok')::int AS ok_count,
      COUNT(*) FILTER (WHERE \(result) = 'pql_error')::int AS pql_error_count,
      COUNT(*) FILTER (WHERE \(result) = 'convertible_error')::int AS convertible_error_count,
      COUNT(*) FILTER (WHERE \(result) = 'unexpected_error')::int AS unexpected_error_count,
      COUNT(*) FILTER (WHERE \(result) = 'not_found')::int AS not_found_count,
      COALESCE(AVG(\(numRequestBytes)), 0)::int AS avg_request_bytes,
      COALESCE(AVG(\(numResponseBytes)), 0)::int AS avg_response_bytes,
      COALESCE(MAX(\(numResponseBytes)), 0)::int AS max_response_bytes
    FROM \(table: RouteTelemetry.self)
    WHERE \(createdAt) >=
    """)
    stmt.components.append(.sql(" now() - make_interval(hours => ("))
    stmt.components.append(.binding(hoursBinding))
    stmt.components.append(.sql(
      ")::int) GROUP BY \(domain), \(operation) ORDER BY p95_ms DESC",
    ))
    return stmt
  }

  var domain: String
  var operation: String
  var requestCount: Int
  var p50Ms: Double
  var p95Ms: Double
  var p99Ms: Double
  var maxMs: Int
  var okCount: Int
  var pqlErrorCount: Int
  var convertibleErrorCount: Int
  var unexpectedErrorCount: Int
  var notFoundCount: Int
  var avgRequestBytes: Int
  var avgResponseBytes: Int
  var maxResponseBytes: Int
}
