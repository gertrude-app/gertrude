import DuetSQL
import PairQL

struct PodcastInstallsList: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var page: Int
    var pageSize: Int?
  }

  struct Output: PairOutput {
    var installs: [InstallSummary]
    var totalCount: Int
    var page: Int
    var totalPages: Int
  }

  struct InstallSummary: PairNestable {
    var installId: UUID
    var deviceType: String
    var iosVersion: String
    var appVersion: String
    var firstLaunch: Date
    var eventCount: Int
    var feedCount: Int
    var isPaid: Bool
  }
}

extension PodcastInstallsList: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let pageSize = input.pageSize ?? 30
    let page = max(1, input.page)
    let offset = (page - 1) * pageSize

    let totalCount = try await context.db.count(DistinctInstallCount.self)
    let totalPages = max(1, Int(ceil(Double(totalCount) / Double(pageSize))))

    let installs = try await context.db.customQuery(
      InstallSummaryQuery.self,
      withBindings: [.int(pageSize), .int(offset)],
    )

    return .init(
      installs: installs.map { row in
        InstallSummary(
          installId: row.installId,
          deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
          iosVersion: row.iosVersion,
          appVersion: row.appVersion,
          firstLaunch: row.firstLaunch,
          eventCount: row.eventCount,
          feedCount: row.feedCount,
          isPaid: row.isPaid,
        )
      },
      totalCount: totalCount,
      page: page,
      totalPages: totalPages,
    )
  }
}

private struct DistinctInstallCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let installId = PodcastEvent.columnName(.installId)
    let eventId = PodcastEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(installId)) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(installId) IS NOT NULL
      AND \(eventId) = '27c4f26a'
    """)
  }

  var count: Int
}

private struct InstallSummaryQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count == 2 else {
      return SQL.Statement("SELECT NULL WHERE FALSE")
    }
    let limit = bindings[0]
    let offset = bindings[1]
    let installId = PodcastEvent.columnName(.installId)
    let modelIdentifier = PodcastEvent.columnName(.modelIdentifier)
    let iosVersion = PodcastEvent.columnName(.iosVersion)
    let appVersion = PodcastEvent.columnName(.appVersion)
    let createdAt = PodcastEvent.columnName(.createdAt)
    let eventId = PodcastEvent.columnName(.eventId)
    var stmt = SQL.Statement("""
    SELECT
      first_launch.install_id,
      first_launch.model_identifier,
      first_launch.ios_version,
      first_launch.app_version,
      first_launch.created_at AS first_launch,
      COALESCE(event_counts.event_count, 0) AS event_count,
      COALESCE(feed_counts.feed_count, 0) AS feed_count,
      CASE WHEN paid.install_id IS NOT NULL THEN true ELSE false END AS is_paid
    FROM (
      SELECT DISTINCT ON (\(installId))
        \(installId), \(modelIdentifier), \(iosVersion), \(appVersion), \(createdAt)
      FROM \(table: PodcastEvent.self)
      WHERE \(installId) IS NOT NULL
        AND \(eventId) = '27c4f26a'
      ORDER BY \(installId), \(createdAt) ASC
    ) first_launch
    LEFT JOIN (
      SELECT \(installId), COUNT(*) AS event_count
      FROM \(table: PodcastEvent.self)
      WHERE \(installId) IS NOT NULL
      GROUP BY \(installId)
    ) event_counts ON first_launch.install_id = event_counts.install_id
    LEFT JOIN (
      SELECT \(installId), COUNT(*) AS feed_count
      FROM \(table: PodcastEvent.self)
      WHERE \(installId) IS NOT NULL
        AND \(eventId) = '7785c87b'
      GROUP BY \(installId)
    ) feed_counts ON first_launch.install_id = feed_counts.install_id
    LEFT JOIN (
      SELECT DISTINCT \(installId)
      FROM \(table: PodcastEvent.self)
      WHERE \(eventId) = 'a72104d7'
    ) paid ON first_launch.install_id = paid.install_id
    ORDER BY first_launch.created_at DESC
    LIMIT\(" ")
    """)
    stmt.components.append(.binding(limit))
    stmt.components.append(.sql(" OFFSET "))
    stmt.components.append(.binding(offset))
    return stmt
  }

  var installId: UUID
  var modelIdentifier: String
  var iosVersion: String
  var appVersion: String
  var firstLaunch: Date
  var eventCount: Int
  var feedCount: Int
  var isPaid: Bool
}
