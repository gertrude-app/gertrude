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
    var iosVersion: String
    var firstLaunch: Date
    var eventCount: Int
    var reachedOptOut: Bool
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
          iosVersion: row.iosVersion,
          firstLaunch: row.firstLaunch,
          eventCount: row.eventCount,
          reachedOptOut: row.reachedOptOut,
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
    let deviceId = IOSEvent.columnName(.deviceId)
    let modelIdentifier = IOSEvent.columnName(.modelIdentifier)
    let iosVersion = IOSEvent.columnName(.iosVersion)
    let createdAt = IOSEvent.columnName(.createdAt)
    let eventId = IOSEvent.columnName(.eventId)
    var stmt = SQL.Statement("""
    SELECT
      first_launch.device_id,
      first_launch.model_identifier,
      first_launch.ios_version,
      first_launch.created_at AS first_launch,
      event_counts.event_count,
      CASE WHEN opt_out.device_id IS NOT NULL THEN true ELSE false END AS reached_opt_out
    FROM (
      SELECT DISTINCT ON (\(deviceId))
        \(deviceId), \(modelIdentifier), \(iosVersion), \(createdAt)
      FROM \(table: IOSEvent.self)
      WHERE \(deviceId) IS NOT NULL
        AND \(eventId) = '8d35f043'
      ORDER BY \(deviceId), \(createdAt) ASC
    ) first_launch
    LEFT JOIN (
      SELECT \(deviceId), COUNT(*) AS event_count
      FROM \(table: IOSEvent.self)
      WHERE \(deviceId) IS NOT NULL
      GROUP BY \(deviceId)
    ) event_counts ON first_launch.device_id = event_counts.device_id
    LEFT JOIN (
      SELECT DISTINCT \(deviceId)
      FROM \(table: IOSEvent.self)
      WHERE \(eventId) = 'cdb31095'
    ) opt_out ON first_launch.device_id = opt_out.device_id
    ORDER BY first_launch.created_at DESC
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
  var reachedOptOut: Bool
}
