import DuetSQL
import PairQL

struct PodcastOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var totalInstalls: Int
    var successfulSubscriptions: Int
    var conversionRate: Double
  }
}

extension PodcastOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let totalInstalls = try await context.db.count(
      DistinctDeviceEventCount.self,
      withBindings: [.string("27c4f26a")],
    )
    let subscriptionCount = try await context.db.count(
      DistinctDeviceEventCount.self,
      withBindings: [.string("a72104d7")],
    )
    let pastTrialInstallCount = try await context.db.count(
      PastTrialInstallCount.self,
      withBindings: [.string("27c4f26a")],
    )

    let rate = pastTrialInstallCount > 0
      ? (Double(subscriptionCount) / Double(pastTrialInstallCount) * 1000).rounded() / 10
      : 0.0

    return .init(
      totalInstalls: totalInstalls,
      successfulSubscriptions: subscriptionCount,
      conversionRate: rate,
    )
  }
}

private struct DistinctDeviceEventCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(PodcastEvent.columnName(.installId))) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(PodcastEvent.columnName(.eventId)) =
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    return stmt
  }

  var count: Int
}

private struct PastTrialInstallCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(PodcastEvent.columnName(.installId))) AS count
    FROM \(table: PodcastEvent.self)
    WHERE
      \(PodcastEvent.columnName(.createdAt)) < NOW() - INTERVAL '30 days'
      AND \(PodcastEvent.columnName(.eventId)) =
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    return stmt
  }

  var count: Int
}
