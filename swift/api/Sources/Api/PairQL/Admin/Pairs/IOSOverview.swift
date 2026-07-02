import DuetSQL
import PairQL

struct IOSOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var adjustedLaunches: Int
    var parentFalseStarts: Int
    var totalSuccess: Int
    var screenTimeSuccess: Int
    var configuratorSuccess: Int
    var gertrudeSupervisionSuccess: Int
    var nonSupervisedConnectionSuccess: Int
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

    let screenTimeSuccess = try await context.db.count(ScreenTimeSuccessCount.self)
    let configuratorSuccess = try await context.db.count(ConfiguratorSuccessCount.self)
    let gertrudeSupervisionSuccess = try await context.db
      .count(GertrudeSupervisionSuccessCount.self)
    let nonSupervisedConnectionSuccess = try await context.db
      .count(NonSupervisedConnectionSuccessCount.self)
    let totalSuccess = screenTimeSuccess + configuratorSuccess
      + gertrudeSupervisionSuccess + nonSupervisedConnectionSuccess
    let stuckIn18PlusPath = try await context.db.count(StuckIn18PlusCount.self)
    let parentFalseStarts = try await context.db.count(ParentDeviceDropoffCount.self)

    let adjustedLaunches = firstLaunches - parentFalseStarts
    let successRate = adjustedLaunches > 0
      ? (Double(totalSuccess) / Double(adjustedLaunches) * 1000).rounded() / 10
      : 0.0

    let recentInstalls = try await context.db.customQuery(RecentInstallsQuery.self)
      .map { row in
        let status = if row.succeeded || row.configurated || row.supervised || row.connected {
          "success"
        } else {
          "incomplete"
        }
        return RecentInstall(
          date: row.date,
          status: status,
          deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
        )
      }

    return .init(
      adjustedLaunches: adjustedLaunches,
      parentFalseStarts: parentFalseStarts,
      totalSuccess: totalSuccess,
      screenTimeSuccess: screenTimeSuccess,
      configuratorSuccess: configuratorSuccess,
      gertrudeSupervisionSuccess: gertrudeSupervisionSuccess,
      nonSupervisedConnectionSuccess: nonSupervisedConnectionSuccess,
      stuckIn18PlusPath: stuckIn18PlusPath,
      successRate: successRate,
      recentInstalls: recentInstalls,
    )
  }
}

private struct DistinctVendorCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(IOSEvent.columnName(.deviceId))) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(IOSEvent.columnName(.deviceId)) IS NOT NULL
      AND \(IOSEvent.columnName(.eventId)) =
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    return stmt
  }

  var count: Int
}

private struct ScreenTimeSuccessCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = IOSEvent.columnName(.deviceId)
    let eventId = IOSEvent.columnName(.eventId)
    let sDeviceId = BlockerApp.Supervision.columnName(.deviceId)
    let sProfileInstalledAt = BlockerApp.Supervision.columnName(.profileInstalledAt)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(deviceId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(deviceId) IS NOT NULL
      AND \(eventId) = 'cdb31095'
      AND \(deviceId) IN (
        SELECT \(deviceId) FROM \(table: IOSEvent.self) WHERE \(eventId) = '4a0c585f'
      )
      AND \(deviceId) NOT IN (
        SELECT \(deviceId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'bad8adcc'
      )
      AND \(deviceId) NOT IN (
        SELECT \(sDeviceId) FROM \(table: BlockerApp.Supervision.self)
        WHERE \(sProfileInstalledAt) IS NOT NULL
      )
    """)
  }

  var count: Int
}

private struct ConfiguratorSuccessCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = IOSEvent.columnName(.deviceId)
    let eventId = IOSEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(deviceId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(deviceId) IS NOT NULL
      AND \(eventId) = '8d35f043'
      AND \(deviceId) IN (
        SELECT \(deviceId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct GertrudeSupervisionSuccessCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = IOSEvent.columnName(.deviceId)
    let eventId = IOSEvent.columnName(.eventId)
    let sDeviceId = BlockerApp.Supervision.columnName(.deviceId)
    let sProfileInstalledAt = BlockerApp.Supervision.columnName(.profileInstalledAt)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(deviceId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(deviceId) IS NOT NULL
      AND \(eventId) = '8d35f043'
      AND \(deviceId) IN (
        SELECT \(sDeviceId) FROM \(table: BlockerApp.Supervision.self)
        WHERE \(sProfileInstalledAt) IS NOT NULL
      )
      AND \(deviceId) NOT IN (
        SELECT \(deviceId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct StuckIn18PlusCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = IOSEvent.columnName(.deviceId)
    let eventId = IOSEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(deviceId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(deviceId) IS NOT NULL
      AND \(eventId) = 'a21c9040'
      AND \(deviceId) NOT IN (
        SELECT \(deviceId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'cdb31095'
      )
    """)
  }

  var count: Int
}

private struct ParentDeviceDropoffCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = IOSEvent.columnName(.deviceId)
    let eventId = IOSEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(deviceId)) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(deviceId) IS NOT NULL
      AND \(eventId) = '30fac4e6'
      AND \(deviceId) NOT IN (
        SELECT \(deviceId) FROM \(table: IOSEvent.self) WHERE \(eventId) = 'cdb31095'
      )
    """)
  }

  var count: Int
}

private struct RecentInstallsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = IOSEvent.columnName(.deviceId)
    let eventId = IOSEvent.columnName(.eventId)
    let createdAt = IOSEvent.columnName(.createdAt)
    let modelIdentifier = IOSEvent.columnName(.modelIdentifier)
    let iId = BlockerApp.Install.columnName(.id)
    let iDeviceId = BlockerApp.Install.columnName(.deviceId)
    let tInstallId = BlockerApp.Token.columnName(.installId)
    let sDeviceId = BlockerApp.Supervision.columnName(.deviceId)
    let profileInstalledAt = BlockerApp.Supervision.columnName(.profileInstalledAt)
    return SQL.Statement("""
    SELECT
      first_launch.\(createdAt) AS date,
      first_launch.\(modelIdentifier) AS model_identifier,
      CASE WHEN success.\(deviceId) IS NOT NULL THEN TRUE ELSE FALSE END AS succeeded,
      CASE WHEN cfg.\(deviceId) IS NOT NULL THEN TRUE ELSE FALSE END AS configurated,
      CASE WHEN sup.\(sDeviceId) IS NOT NULL THEN TRUE ELSE FALSE END AS supervised,
      CASE WHEN token_installs.\(iDeviceId) IS NOT NULL THEN TRUE ELSE FALSE END AS connected
    FROM (
      SELECT DISTINCT ON (\(deviceId)) \(deviceId), \(createdAt), \(modelIdentifier)
      FROM \(table: IOSEvent.self)
      WHERE \(deviceId) IS NOT NULL AND \(eventId) = '8d35f043'
      ORDER BY \(deviceId), \(createdAt)
    ) first_launch
    LEFT JOIN (
      SELECT DISTINCT \(deviceId)
      FROM \(table: IOSEvent.self)
      WHERE \(deviceId) IS NOT NULL AND \(eventId) = 'cdb31095'
    ) success ON first_launch.\(deviceId) = success.\(deviceId)
    LEFT JOIN (
      SELECT DISTINCT \(deviceId)
      FROM \(table: IOSEvent.self)
      WHERE \(deviceId) IS NOT NULL AND \(eventId) = 'bad8adcc'
    ) cfg ON first_launch.\(deviceId) = cfg.\(deviceId)
    LEFT JOIN (
      SELECT \(sDeviceId)
      FROM \(table: BlockerApp.Supervision.self)
      WHERE \(profileInstalledAt) IS NOT NULL
    ) sup ON first_launch.\(deviceId) = sup.\(sDeviceId)
    LEFT JOIN (
      SELECT DISTINCT i.\(iDeviceId)
      FROM \(table: BlockerApp.Install.self) i
      INNER JOIN \(table: BlockerApp.Token.self) t ON t.\(tInstallId) = i.\(iId)
    ) token_installs ON first_launch.\(deviceId) = token_installs.\(iDeviceId)
    ORDER BY first_launch.\(createdAt) DESC
    """)
  }

  var date: Date
  var modelIdentifier: String
  var succeeded: Bool
  var configurated: Bool
  var supervised: Bool
  var connected: Bool
}
