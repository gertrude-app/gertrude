import DuetSQL
import PairQL

struct PodcastOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var totalInstalls: Int
    var successfulSubscriptions: Int
    var activePodcastUsers: Int
    var conversionRate: Double
    var iPhoneInstalls: Int
    var iPadInstalls: Int
    var recentInstalls: [RecentInstall]
  }

  struct RecentInstall: PairNestable {
    var date: Date
    var deviceType: String
    var isPaid: Bool
  }
}

extension PodcastOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let totalInstalls = try await context.db.count(
      DistinctDeviceEventCount.self,
      withBindings: [.string("27c4f26a")],
    )
    let subscriptionCount = try await context.db.count(DistinctOriginalIDPaidCount.self)
    let pastTrialInstallCount = try await context.db.count(
      PastTrialInstallCount.self,
      withBindings: [.string("27c4f26a")],
    )
    let iPhoneInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPhone%")],
    )
    let iPadInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPad%")],
    )

    let activePodcastUsers = try await context.db.count(ActivePodcastUsersCount.self)

    let rate = pastTrialInstallCount > 0
      ? (Double(subscriptionCount) / Double(pastTrialInstallCount) * 1000).rounded() / 10
      : 0.0

    let recentInstalls = try await context.db.customQuery(RecentInstallsQuery.self)
      .map { row in
        RecentInstall(
          date: row.date,
          deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
          isPaid: row.isPaid,
        )
      }

    return .init(
      totalInstalls: totalInstalls,
      successfulSubscriptions: subscriptionCount,
      activePodcastUsers: activePodcastUsers,
      conversionRate: rate,
      iPhoneInstalls: iPhoneInstalls,
      iPadInstalls: iPadInstalls,
      recentInstalls: recentInstalls,
    )
  }
}

struct DistinctDeviceEventCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(PodcastEvent.columnName(.deviceId))) AS count
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

struct DistinctOriginalIDPaidCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT \(podcastOriginalIDExprSQL)) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(paidProductionPodcastEventPredicateSQL)
    """)
  }

  var count: Int
}

private struct PastTrialInstallCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT e.\(PodcastEvent.columnName(.deviceId))) AS count
    FROM \(table: PodcastEvent.self) AS e
    WHERE
      e.\(PodcastEvent.columnName(.createdAt)) < NOW() - INTERVAL '30 days'
      AND e.\(PodcastEvent.columnName(.eventId)) =\(" ")
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    stmt.components.append(.sql("""

      AND NOT EXISTS (
        SELECT 1 FROM \(table: PodcastEvent.self)
        WHERE \(PodcastEvent.columnName(.deviceId)) = e.\(PodcastEvent.columnName(.deviceId))
          AND \(paidSandboxPodcastEventPredicateSQL)
      )
    """))
    return stmt
  }

  var count: Int
}

private struct DeviceTypeInstallCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count == 2 else {
      return SQL.Statement("SELECT 0 AS count")
    }
    let eventId = bindings[0]
    let devicePattern = bindings[1]
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(PodcastEvent.columnName(.deviceId))) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(PodcastEvent.columnName(.eventId)) =\(" ")
    """)
    stmt.components.append(.binding(eventId))
    stmt.components.append(.sql(" AND \(PodcastEvent.columnName(.modelIdentifier)) LIKE "))
    stmt.components.append(.binding(devicePattern))
    return stmt
  }

  var count: Int
}

private struct RecentInstallsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = PodcastEvent.columnName(.deviceId)
    let eventId = PodcastEvent.columnName(.eventId)
    let createdAt = PodcastEvent.columnName(.createdAt)
    let modelIdentifier = PodcastEvent.columnName(.modelIdentifier)
    return SQL.Statement("""
    SELECT
      first_launch.\(createdAt) AS date,
      first_launch.\(modelIdentifier) AS model_identifier,
      CASE WHEN paid.\(deviceId) IS NOT NULL THEN TRUE ELSE FALSE END AS is_paid
    FROM (
      SELECT DISTINCT ON (\(deviceId)) \(deviceId), \(createdAt), \(modelIdentifier)
      FROM \(table: PodcastEvent.self)
      WHERE \(eventId) = '27c4f26a'
      ORDER BY \(deviceId), \(createdAt)
    ) first_launch
    LEFT JOIN (
      SELECT DISTINCT \(deviceId)
      FROM \(table: PodcastEvent.self)
      WHERE \(paidProductionPodcastEventPredicateSQL)
    ) paid ON first_launch.\(deviceId) = paid.\(deviceId)
    ORDER BY first_launch.\(createdAt) DESC
    """)
  }

  var date: Date
  var modelIdentifier: String
  var isPaid: Bool
}

private struct ActivePodcastUsersCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = PodcastEvent.columnName(.deviceId)
    let eventId = PodcastEvent.columnName(.eventId)
    let createdAt = PodcastEvent.columnName(.createdAt)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(deviceId)) AS count
    FROM \(table: PodcastEvent.self)
    WHERE (
        (\(eventId) = '27c4f26a' AND \(createdAt) >= NOW() - INTERVAL '30 days')
        OR (\(paidProductionPodcastEventPredicateSQL))
      )
    """)
  }

  var count: Int
}
