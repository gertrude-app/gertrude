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
    var status: String
  }
}

extension PodcastOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let iPhoneInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPhone%")],
    )
    let iPadInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPad%")],
    )

    let activePodcastUsers = try await context.db.count(ActivePodcastUsersCount.self)

    let statusRows = try await context.db.customQuery(StatusBreakdownRowsQuery.self)
    var breakdown = StatusBreakdown(
      paid: 0,
      complimentary: 0,
      connected: 0,
      trial: 0,
      expired: 0,
      iap: 0,
    )
    for row in statusRows {
      switch row.status {
      case "paid": breakdown.paid += row.count
      case "complimentary": breakdown.complimentary += row.count
      case "connected": breakdown.connected += row.count
      case "trial": breakdown.trial += row.count
      case "expired": breakdown.expired += row.count
      case "iap": breakdown.iap += row.count
      default: break
      }
    }
    let totalInstalls = statusRows.reduce(0) { $0 + $1.count }

    let recentRows = try await context.db.customQuery(RecentInstallsQuery.self)
    let recentInstalls = recentRows.map { row in
      RecentInstall(
        date: row.date,
        deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
        status: row.status,
      )
    }

    return .init(
      totalInstalls: totalInstalls,
      activePodcastUsers: activePodcastUsers,
      iPhoneInstalls: iPhoneInstalls,
      iPadInstalls: iPadInstalls,
      statusBreakdown: breakdown,
      recentInstalls: recentInstalls,
    )
  }
}

private struct StatusBreakdownRowsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = PodcastEvent.columnName(.deviceId)
    let eventId = PodcastEvent.columnName(.eventId)
    let createdAt = PodcastEvent.columnName(.createdAt)
    let devPk = IOSDevice.columnName(.id)
    let devChildId = IOSDevice.columnName(.childId)
    let childPk = Child.columnName(.id)
    let childParentId = Child.columnName(.parentId)
    let subParentId = StripeSubscription.columnName(.parentId)
    let subStatus = StripeSubscription.columnName(.stripeStatus)
    let billingParentId = BillingIdentity.columnName(.parentId)
    let billingComplimentary = BillingIdentity.columnName(.isComplimentary)
    return SQL.Statement("""
    WITH install_statuses AS (
      SELECT
        CASE
          WHEN billing.\(billingComplimentary) = true THEN 'complimentary'
          WHEN sub.\(subStatus) IN ('active', 'past_due') THEN 'paid'
          WHEN dev.\(devChildId) IS NOT NULL THEN 'connected'
          WHEN paid.\(deviceId) IS NOT NULL THEN 'iap'
          WHEN first_launch.\(createdAt) + INTERVAL '30 days' > NOW() THEN 'trial'
          ELSE 'expired'
        END AS status
      FROM (
        SELECT DISTINCT ON (\(deviceId)) \(deviceId), \(createdAt)
        FROM \(table: PodcastEvent.self)
        WHERE \(eventId) = '27c4f26a'
          AND \(deviceId) IS NOT NULL
        ORDER BY \(deviceId), \(createdAt) ASC
      ) first_launch
      LEFT JOIN (
        SELECT DISTINCT \(deviceId)
        FROM \(table: PodcastEvent.self)
        WHERE \(hostPurchasePodcastEventPredicateSQL)
      ) paid ON first_launch.\(deviceId) = paid.\(deviceId)
      LEFT JOIN \(table: IOSDevice.self) dev ON dev.\(devPk) = first_launch.\(deviceId)
      LEFT JOIN \(table: Child.self) child ON child.\(childPk) = dev.\(devChildId)
      LEFT JOIN \(table: StripeSubscription.self) sub
        ON sub.\(subParentId) = child.\(childParentId)
      LEFT JOIN \(table: BillingIdentity.self) billing
        ON billing.\(billingParentId) = child.\(childParentId)
    )
    SELECT
      status,
      COUNT(*)::int AS count
    FROM install_statuses
    GROUP BY status
    """)
  }

  var status: String
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
    stmt.components.append(.sql("""
     AND \(PodcastEvent.columnName(.deviceId)) IS NOT NULL
     AND \(PodcastEvent.columnName(.modelIdentifier)) LIKE\(" ")
    """))
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
    let devPk = IOSDevice.columnName(.id)
    let devChildId = IOSDevice.columnName(.childId)
    let childPk = Child.columnName(.id)
    let childParentId = Child.columnName(.parentId)
    let subParentId = StripeSubscription.columnName(.parentId)
    let subStatus = StripeSubscription.columnName(.stripeStatus)
    return SQL.Statement("""
    SELECT
      first_launch.\(createdAt) AS date,
      first_launch.\(modelIdentifier) AS model_identifier,
      CASE
        WHEN dev.\(devChildId) IS NULL THEN 'trial'
        WHEN sub.\(subStatus) IN ('active', 'past_due') THEN 'paid'
        ELSE 'connected'
      END AS status
    FROM (
      SELECT DISTINCT ON (\(deviceId)) \(deviceId), \(createdAt), \(modelIdentifier)
      FROM \(table: PodcastEvent.self)
      WHERE \(eventId) = '27c4f26a'
        AND \(deviceId) IS NOT NULL
      ORDER BY \(deviceId), \(createdAt)
    ) first_launch
    LEFT JOIN \(table: IOSDevice.self) dev ON dev.\(devPk) = first_launch.\(deviceId)
    LEFT JOIN \(table: Child.self) child ON child.\(childPk) = dev.\(devChildId)
    LEFT JOIN \(table: StripeSubscription.self) sub
      ON sub.\(subParentId) = child.\(childParentId)
    ORDER BY first_launch.\(createdAt) DESC
    """)
  }

  var date: Date
  var modelIdentifier: String
  var status: String
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
      AND \(deviceId) IS NOT NULL
    """)
  }

  var count: Int
}
