import DuetSQL
import PairQL

struct IOSOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var adjustedLaunches: Int
    var parentFalseStarts: Int
    var totalSuccess: Int
    var standardSuccess: Int
    var supervisedSuccess: Int
    var stuckIn18PlusPath: Int
    var successRate: Double
    var recentInstalls: [RecentInstall]
  }

  struct RecentInstall: PairNestable {
    var date: Date
    var status: String
    var deviceType: String
  }
}

extension IOSOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let firstLaunches = try await context.db.count(
      DistinctVendorCount.self,
      withBindings: [.string("8d35f043")],
    )

    let totalSuccess = try await context.db.count(
      DistinctVendorCount.self,
      withBindings: [.string("cdb31095")],
    )

    let standardSuccess = try await context.db.count(StandardSuccessCount.self)
    let supervisedSuccess = try await context.db.count(SupervisedSuccessCount.self)
    let stuckIn18PlusPath = try await context.db.count(StuckIn18PlusCount.self)
    let parentFalseStarts = try await context.db.count(ParentDeviceDropoffCount.self)

    let adjustedLaunches = firstLaunches - parentFalseStarts
    let successRate = adjustedLaunches > 0
      ? (Double(totalSuccess) / Double(adjustedLaunches) * 1000).rounded() / 10
      : 0.0

    let recentInstalls = try await context.db.customQuery(RecentInstallsQuery.self)
      .map { row in
        RecentInstall(
          date: row.date,
          status: row.succeeded ? "success" : "incomplete",
          deviceType: row.deviceType,
        )
      }

    return .init(
      adjustedLaunches: adjustedLaunches,
      parentFalseStarts: parentFalseStarts,
      totalSuccess: totalSuccess,
      standardSuccess: standardSuccess,
      supervisedSuccess: supervisedSuccess,
      stuckIn18PlusPath: stuckIn18PlusPath,
      successRate: successRate,
      recentInstalls: recentInstalls,
    )
  }
}

private struct DistinctVendorCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(IOSEvent.columnName(.vendorId))) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(IOSEvent.columnName(.vendorId)) IS NOT NULL
      AND \(IOSEvent.columnName(.eventId)) =
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    return stmt
  }

  var count: Int
}

private struct StandardSuccessCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let vendorId = IOSEvent.columnName(.vendorId)
    let eventId = IOSEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(vendorId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(vendorId) IS NOT NULL
      AND \(eventId) = 'cdb31095'
      AND \(vendorId) IN (
        SELECT \(vendorId) FROM \(table: IOSEvent.self) WHERE \(eventId) = '4a0c585f'
      )
      AND \(vendorId) NOT IN (
        SELECT \(vendorId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct SupervisedSuccessCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let vendorId = IOSEvent.columnName(.vendorId)
    let eventId = IOSEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(vendorId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(vendorId) IS NOT NULL
      AND \(eventId) = 'cdb31095'
      AND \(vendorId) IN (
        SELECT \(vendorId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct StuckIn18PlusCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let vendorId = IOSEvent.columnName(.vendorId)
    let eventId = IOSEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(vendorId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(vendorId) IS NOT NULL
      AND \(eventId) = 'a21c9040'
      AND \(vendorId) NOT IN (
        SELECT \(vendorId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'cdb31095'
      )
    """)
  }

  var count: Int
}

private struct ParentDeviceDropoffCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let vendorId = IOSEvent.columnName(.vendorId)
    let eventId = IOSEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(vendorId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(vendorId) IS NOT NULL
      AND \(eventId) = '30fac4e6'
      AND \(vendorId) NOT IN (
        SELECT \(vendorId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'cdb31095'
      )
    """)
  }

  var count: Int
}

private struct RecentInstallsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let vendorId = IOSEvent.columnName(.vendorId)
    let eventId = IOSEvent.columnName(.eventId)
    let createdAt = IOSEvent.columnName(.createdAt)
    let deviceType = IOSEvent.columnName(.deviceType)
    return SQL.Statement("""
    SELECT
      first_launch.\(createdAt) AS date,
      first_launch.\(deviceType) AS device_type,
      CASE WHEN success.\(vendorId) IS NOT NULL THEN TRUE ELSE FALSE END AS succeeded
    FROM (
      SELECT DISTINCT ON (\(vendorId)) \(vendorId), \(createdAt), \(deviceType)
      FROM \(table: IOSEvent.self)
      WHERE \(vendorId) IS NOT NULL AND \(eventId) = '8d35f043'
      ORDER BY \(vendorId), \(createdAt)
    ) first_launch
    LEFT JOIN (
      SELECT DISTINCT \(vendorId)
      FROM \(table: IOSEvent.self)
      WHERE \(vendorId) IS NOT NULL AND \(eventId) = 'cdb31095'
    ) success ON first_launch.\(vendorId) = success.\(vendorId)
    ORDER BY first_launch.\(createdAt) DESC
    """)
  }

  var date: Date
  var deviceType: String
  var succeeded: Bool
}
