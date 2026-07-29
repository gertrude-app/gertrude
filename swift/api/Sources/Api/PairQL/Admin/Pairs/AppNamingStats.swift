import DuetSQL
import PairQL

struct AppNamingStats: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var total: Int
    var above100k: Int
    var above50k: Int
    var above10k: Int
    var above1k: Int
  }
}

extension AppNamingStats: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let stats = try await context.db.customQuery(AppNamingStatsQuery.self).first
    return .init(
      total: stats?.total ?? 0,
      above100k: stats?.above100k ?? 0,
      above50k: stats?.above50k ?? 0,
      above10k: stats?.above10k ?? 0,
      above1k: stats?.above1k ?? 0,
    )
  }
}

private struct AppNamingStatsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let count = UnidentifiedApp.columnName(.count)
    return SQL.Statement("""
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE \(count) >= 100000)::int AS above100k,
      COUNT(*) FILTER (WHERE \(count) >= 50000)::int AS above50k,
      COUNT(*) FILTER (WHERE \(count) >= 10000)::int AS above10k,
      COUNT(*) FILTER (WHERE \(count) >= 1000)::int AS above1k
    FROM \(table: UnidentifiedApp.self)
    WHERE \(count) >= 1
    """)
  }

  var total: Int
  var above100k: Int
  var above50k: Int
  var above10k: Int
  var above1k: Int
}
