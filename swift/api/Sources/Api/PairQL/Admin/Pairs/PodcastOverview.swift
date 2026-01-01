import DuetSQL
import PairQL

struct PodcastOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var totalInstalls: Int
    var successfulSubscriptions: Int
    var conversionRate: Double
    var iPhoneInstalls: Int
    var iPadInstalls: Int
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
    let iPhoneInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPhone%")],
    )
    let iPadInstalls = try await context.db.count(
      DeviceTypeInstallCount.self,
      withBindings: [.string("27c4f26a"), .string("%iPad%")],
    )

    let rate = pastTrialInstallCount > 0
      ? (Double(subscriptionCount) / Double(pastTrialInstallCount) * 1000).rounded() / 10
      : 0.0

    return .init(
      totalInstalls: totalInstalls,
      successfulSubscriptions: subscriptionCount,
      conversionRate: rate,
      iPhoneInstalls: iPhoneInstalls,
      iPadInstalls: iPadInstalls,
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

private struct DeviceTypeInstallCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count == 2 else {
      return SQL.Statement("SELECT 0 AS count")
    }
    let eventId = bindings[0]
    let devicePattern = bindings[1]
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(PodcastEvent.columnName(.installId))) AS count
    FROM \(table: PodcastEvent.self)
    WHERE \(PodcastEvent.columnName(.eventId)) =\(" ")
    """)
    stmt.components.append(.binding(eventId))
    stmt.components.append(.sql(" AND \(PodcastEvent.columnName(.deviceType)) LIKE "))
    stmt.components.append(.binding(devicePattern))
    return stmt
  }

  var count: Int
}
