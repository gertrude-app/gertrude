import Dependencies
import DuetSQL
import PairQL

struct PodcastOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var totalInstalls: Int
    var activePodcastUsers: Int
    var iPhoneInstalls: Int
    var iPadInstalls: Int
    var statusBreakdown: StatusBreakdown
    var recentInstalls: [RecentInstall]
  }

  struct StatusBreakdown: PairNestable {
    var paid: Int
    var complimentary: Int
    var connected: Int
    var trial: Int
    var expired: Int
    var iap: Int
  }

  struct RecentInstall: PairNestable {
    var date: Date
    var deviceType: String
    var isPaid: Bool
  }
}

extension PodcastOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now

    let iPhoneInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPhone%")],
    )
    let iPadInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPad%")],
    )

    let activePodcastUsers = try await context.db.count(ActivePodcastUsersCount.self)

    let statusRows = try await context.db.customQuery(InstallStatusRowsQuery.self)
    var breakdown = StatusBreakdown(
      paid: 0,
      complimentary: 0,
      connected: 0,
      trial: 0,
      expired: 0,
      iap: 0,
    )
    for row in statusRows {
      switch try await PodcastInstallsList.status(
        deviceId: row.deviceId,
        firstLaunch: row.firstLaunch,
        connected: row.connected,
        isPaid: row.isPaid,
        at: now,
        in: context,
      ) {
      case "paid": breakdown.paid += 1
      case "complimentary": breakdown.complimentary += 1
      case "connected": breakdown.connected += 1
      case "trial": breakdown.trial += 1
      case "expired": breakdown.expired += 1
      case "iap": breakdown.iap += 1
      default: break
      }
    }

    let recentInstalls = try await context.db.customQuery(RecentInstallsQuery.self)
      .map { row in
        RecentInstall(
          date: row.date,
          deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
          isPaid: row.isPaid,
        )
      }

    return .init(
      totalInstalls: statusRows.count,
      activePodcastUsers: activePodcastUsers,
      iPhoneInstalls: iPhoneInstalls,
      iPadInstalls: iPadInstalls,
      statusBreakdown: breakdown,
      recentInstalls: recentInstalls,
    )
  }
}

private struct InstallStatusRowsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = PodcastEvent.columnName(.deviceId)
    let eventId = PodcastEvent.columnName(.eventId)
    let createdAt = PodcastEvent.columnName(.createdAt)
    let devPk = IOSDevice.columnName(.id)
    let devChildId = IOSDevice.columnName(.childId)
    return SQL.Statement("""
    SELECT
      first_launch.\(deviceId),
      first_launch.\(createdAt) AS first_launch,
      CASE WHEN paid.\(deviceId) IS NOT NULL THEN true ELSE false END AS is_paid,
      CASE WHEN dev.\(devChildId) IS NOT NULL THEN true ELSE false END AS connected
    FROM (
      SELECT DISTINCT ON (\(deviceId)) \(deviceId), \(createdAt)
      FROM \(table: PodcastEvent.self)
      WHERE \(eventId) = '27c4f26a'
      ORDER BY \(deviceId), \(createdAt) ASC
    ) first_launch
    LEFT JOIN (
      SELECT DISTINCT \(deviceId)
      FROM \(table: PodcastEvent.self)
      WHERE \(hostPurchasePodcastEventPredicateSQL)
    ) paid ON first_launch.\(deviceId) = paid.\(deviceId)
    LEFT JOIN \(table: IOSDevice.self) dev ON dev.\(devPk) = first_launch.\(deviceId)
    """)
  }

  var deviceId: UUID
  var firstLaunch: Date
  var isPaid: Bool
  var connected: Bool
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
      WHERE \(hostPurchasePodcastEventPredicateSQL)
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
        OR (\(hostPurchasePodcastEventPredicateSQL))
      )
    """)
  }

  var count: Int
}
