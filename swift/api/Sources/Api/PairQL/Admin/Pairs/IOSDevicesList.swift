import DuetSQL
import PairQL

struct IOSDevicesList: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var page: Int
    var pageSize: Int?
  }

  struct Output: PairOutput {
    var devices: [DeviceSummary]
    var totalCount: Int
    var page: Int
    var totalPages: Int
  }

  struct DeviceSummary: PairNestable {
    var vendorId: UUID
    var deviceType: String
    var modelName: String
    var iosVersion: String
    var firstLaunch: Date
    var eventCount: Int
    var status: String
  }
}

extension IOSDevicesList: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let pageSize = input.pageSize ?? 30
    let page = max(1, input.page)
    let offset = (page - 1) * pageSize

    let totalCount = try await context.db.count(DistinctDeviceCount.self)
    let totalPages = max(1, Int(ceil(Double(totalCount) / Double(pageSize))))

    let devices = try await context.db.customQuery(
      DeviceSummaryQuery.self,
      withBindings: [.int(pageSize), .int(offset)],
    )

    return .init(
      devices: devices.map { row in
        DeviceSummary(
          vendorId: row.deviceId,
          deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
          modelName: ModelIdentifier.marketingName(for: row.modelIdentifier),
          iosVersion: row.iosVersion,
          firstLaunch: row.firstLaunch,
          eventCount: row.eventCount,
          status: row.status,
        )
      },
      totalCount: totalCount,
      page: page,
      totalPages: totalPages,
    )
  }
}

private struct DistinctDeviceCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT \(IOSEvent.columnName(.deviceId))) AS count
    FROM \(table: IOSEvent.self)
    WHERE \(IOSEvent.columnName(.deviceId)) IS NOT NULL
      AND \(IOSEvent.columnName(.eventId)) = '8d35f043'
    """)
  }

  var count: Int
}

private struct DeviceSummaryQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count == 2 else {
      return SQL.Statement("SELECT NULL WHERE FALSE")
    }
    let limit = bindings[0]
    let offset = bindings[1]
    let eDeviceId = IOSEvent.columnName(.deviceId)
    let eModelId = IOSEvent.columnName(.modelIdentifier)
    let eIosVer = IOSEvent.columnName(.iosVersion)
    let eCreatedAt = IOSEvent.columnName(.createdAt)
    let eEventId = IOSEvent.columnName(.eventId)
    let dId = IOSDevice.columnName(.id)
    let sDeviceId = BlockerApp.Supervision.columnName(.deviceId)
    let sId = BlockerApp.Supervision.columnName(.id)
    let sProfileInstalledAt = BlockerApp.Supervision.columnName(.profileInstalledAt)
    let sSupervisedAt = BlockerApp.Supervision.columnName(.supervisedAt)
    let sClaimedAt = BlockerApp.Supervision.columnName(.claimedAt)
    let tDeviceId = BlockerApp.Token.columnName(.deviceId)
    var stmt = SQL.Statement("""
    SELECT
      fl.\(eDeviceId),
      fl.\(eModelId),
      fl.\(eIosVer),
      fl.\(eCreatedAt) AS first_launch,
      ec.event_count,
      CASE
        WHEN s.\(sProfileInstalledAt) IS NOT NULL THEN 'supervised'
        WHEN s.\(sSupervisedAt) IS NOT NULL THEN 'missingProfile'
        WHEN s.\(sClaimedAt) IS NOT NULL THEN 'claimed'
        WHEN s.\(sId) IS NOT NULL THEN 'pendingClaim'
        WHEN tk.\(tDeviceId) IS NOT NULL AND s.\(sId) IS NULL THEN 'connected'
        WHEN cfg.\(eDeviceId) IS NOT NULL THEN 'configurated'
        WHEN st.\(eDeviceId) IS NOT NULL THEN 'screenTime'
        WHEN oo.\(eDeviceId) IS NOT NULL THEN 'complete'
        ELSE 'incomplete'
      END AS status
    FROM (
      SELECT DISTINCT ON (\(eDeviceId))
        \(eDeviceId), \(eModelId), \(eIosVer), \(eCreatedAt)
      FROM \(table: IOSEvent.self)
      WHERE \(eDeviceId) IS NOT NULL
        AND \(eEventId) = '8d35f043'
      ORDER BY \(eDeviceId), \(eCreatedAt) ASC
    ) fl
    LEFT JOIN (
      SELECT \(eDeviceId), COUNT(*) AS event_count
      FROM \(table: IOSEvent.self)
      WHERE \(eDeviceId) IS NOT NULL
      GROUP BY \(eDeviceId)
    ) ec ON fl.\(eDeviceId) = ec.\(eDeviceId)
    LEFT JOIN (
      SELECT DISTINCT \(eDeviceId)
      FROM \(table: IOSEvent.self)
      WHERE \(eEventId) = 'cdb31095'
    ) oo ON fl.\(eDeviceId) = oo.\(eDeviceId)
    LEFT JOIN \(table: IOSDevice.self) d ON d.\(dId) = fl.\(eDeviceId)
    LEFT JOIN \(table: BlockerApp.Supervision.self) s ON s.\(sDeviceId) = d.\(dId)
    LEFT JOIN \(table: BlockerApp.Token.self) tk ON tk.\(tDeviceId) = d.\(dId)
    LEFT JOIN (
      SELECT DISTINCT \(eDeviceId)
      FROM \(table: IOSEvent.self)
      WHERE \(eEventId) = 'bad8adcc'
    ) cfg ON fl.\(eDeviceId) = cfg.\(eDeviceId)
    LEFT JOIN (
      SELECT DISTINCT \(eDeviceId)
      FROM \(table: IOSEvent.self)
      WHERE \(eEventId) = '4a0c585f'
    ) st ON fl.\(eDeviceId) = st.\(eDeviceId)
    ORDER BY fl.\(eCreatedAt) DESC
    LIMIT\(" ")
    """)
    stmt.components.append(.binding(limit))
    stmt.components.append(.sql(" OFFSET "))
    stmt.components.append(.binding(offset))
    return stmt
  }

  var deviceId: UUID
  var modelIdentifier: String
  var iosVersion: String
  var firstLaunch: Date
  var eventCount: Int
  var status: String
}
