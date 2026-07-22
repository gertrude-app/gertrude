import Dependencies
import DuetSQL
import PairQL
import PodcastRoute

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
    var deviceId: UUID
    var deviceType: String
    var modelName: String
    var iosVersion: String
    var appVersion: String
    var firstLaunch: Date
    var feedCount: Int
    var status: String
  }
}

extension PodcastInstallsList: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now
    let pageSize = input.pageSize ?? 30
    let page = max(1, input.page)
    let offset = (page - 1) * pageSize

    let totalCount = try await context.db.count(DistinctInstallCount.self)
    let totalPages = max(1, Int(ceil(Double(totalCount) / Double(pageSize))))

    let rows = try await context.db.customQuery(
      InstallSummaryQuery.self,
      withBindings: [.int(pageSize), .int(offset)],
    )

    var installs: [InstallSummary] = []
    for row in rows {
      let status = try await Self.status(
        deviceId: row.deviceId,
        firstLaunch: row.firstLaunch,
        connected: row.connected,
        isPaid: row.isPaid,
        at: now,
        in: context,
      )
      installs.append(InstallSummary(
        deviceId: row.deviceId,
        deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
        modelName: ModelIdentifier.marketingName(for: row.modelIdentifier),
        iosVersion: row.iosVersion,
        appVersion: row.appVersion,
        firstLaunch: row.firstLaunch,
        feedCount: row.feedCount,
        status: status,
      ))
    }

    return .init(
      installs: installs,
      totalCount: totalCount,
      page: page,
      totalPages: totalPages,
    )
  }

  static func status(
    deviceId: UUID,
    firstLaunch: Date,
    connected: Bool,
    isPaid: Bool,
    at now: Date,
    in context: Context,
  ) async throws -> String {
    if connected {
      try await self.connectedStatus(
        deviceId: deviceId,
        firstLaunch: firstLaunch,
        at: now,
        in: context,
      )
    } else if isPaid {
      "iap"
    } else if firstLaunch + PodcastApp.Install.trialPeriod > now {
      "trial"
    } else {
      "expired"
    }
  }

  static func connectedStatus(
    deviceId: UUID,
    firstLaunch: Date,
    at now: Date,
    in context: Context,
  ) async throws -> String {
    guard let device = try? await context.db.find(IOSDevice.Id(deviceId)) as IOSDevice,
          let child = try await device.child(in: context.db) else {
      return "connected"
    }
    let parent = try await child.parent(in: context.db)
    let snapshot = try await parent.billingAccountSnapshot(in: context.db, at: now)
    guard let install = try await device.podcastInstall(in: context.db) else {
      switch snapshot.planStatus {
      case .complimentary: return "complimentary"
      case .full(.current), .medium(.current), .light(.current): return "paid"
      default: return firstLaunch + PodcastApp.Install.trialPeriod > now ? "connected" : "expired"
      }
    }
    switch snapshot.amSubscriptionState(forInstall: install) {
    case .complimentary: return "complimentary"
    case .active: return "paid"
    case .legacyGrandfathered, .legacyExpired: return "iap"
    case .amTrial, .fullTrial: return "connected"
    case .unpaid: return "expired"
    }
  }
}

private struct DistinctInstallCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let deviceId = PodcastEvent.columnName(.deviceId)
    let eventId = PodcastEvent.columnName(.eventId)
    return SQL.Statement("""
    SELECT COUNT(DISTINCT \(deviceId)) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(eventId) = '27c4f26a'
      AND \(deviceId) IS NOT NULL
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
    let deviceId = PodcastEvent.columnName(.deviceId)
    let modelIdentifier = PodcastEvent.columnName(.modelIdentifier)
    let iosVersion = PodcastEvent.columnName(.iosVersion)
    let appVersion = PodcastEvent.columnName(.appVersion)
    let createdAt = PodcastEvent.columnName(.createdAt)
    let eventId = PodcastEvent.columnName(.eventId)
    let devPk = IOSDevice.columnName(.id)
    let devChildId = IOSDevice.columnName(.childId)
    var stmt = SQL.Statement("""
    SELECT
      first_launch.\(deviceId),
      first_launch.\(modelIdentifier),
      first_launch.\(iosVersion),
      first_launch.\(appVersion),
      first_launch.\(createdAt) AS first_launch,
      COALESCE(feed_counts.feed_count, 0) AS feed_count,
      CASE WHEN paid.\(deviceId) IS NOT NULL THEN true ELSE false END AS is_paid,
      CASE WHEN dev.\(devChildId) IS NOT NULL THEN true ELSE false END AS connected
    FROM (
      SELECT DISTINCT ON (\(deviceId))
        \(deviceId), \(modelIdentifier), \(iosVersion), \(appVersion), \(createdAt)
      FROM \(table: PodcastEvent.self)
      WHERE \(eventId) = '27c4f26a'
        AND \(deviceId) IS NOT NULL
      ORDER BY \(deviceId), \(createdAt) ASC
    ) first_launch
    LEFT JOIN (
      SELECT \(deviceId), COUNT(*) AS feed_count
      FROM \(table: PodcastEvent.self)
      WHERE \(eventId) = '7785c87b'
      GROUP BY \(deviceId)
    ) feed_counts ON first_launch.\(deviceId) = feed_counts.\(deviceId)
    LEFT JOIN (
      SELECT DISTINCT \(deviceId)
      FROM \(table: PodcastEvent.self)
      WHERE \(hostPurchasePodcastEventPredicateSQL)
    ) paid ON first_launch.\(deviceId) = paid.\(deviceId)
    LEFT JOIN \(table: IOSDevice.self) dev ON dev.\(devPk) = first_launch.\(deviceId)
    ORDER BY first_launch.\(createdAt) DESC
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
  var appVersion: String
  var firstLaunch: Date
  var feedCount: Int
  var isPaid: Bool
  var connected: Bool
}
