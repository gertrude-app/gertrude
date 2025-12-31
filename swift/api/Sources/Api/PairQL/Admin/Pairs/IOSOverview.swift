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
  }
}

extension IOSOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let firstLaunches = try await context.db.customQuery(
      DistinctVendorCount.self,
      withBindings: [.string("8d35f043")],
    ).first?.count ?? 0

    let totalSuccess = try await context.db.customQuery(
      DistinctVendorCount.self,
      withBindings: [.string("cdb31095")],
    ).first?.count ?? 0

    let standardSuccess = try await context.db.customQuery(
      StandardSuccessCount.self,
    ).first?.count ?? 0

    let supervisedSuccess = try await context.db.customQuery(
      SupervisedSuccessCount.self,
    ).first?.count ?? 0

    let stuckIn18PlusPath = try await context.db.customQuery(
      StuckIn18PlusCount.self,
    ).first?.count ?? 0

    let parentFalseStarts = try await context.db.customQuery(
      ParentDeviceDropoffCount.self,
    ).first?.count ?? 0

    let adjustedLaunches = firstLaunches - parentFalseStarts
    let successRate = adjustedLaunches > 0
      ? (Double(totalSuccess) / Double(adjustedLaunches) * 1000).rounded() / 10
      : 0.0

    return .init(
      adjustedLaunches: adjustedLaunches,
      parentFalseStarts: parentFalseStarts,
      totalSuccess: totalSuccess,
      standardSuccess: standardSuccess,
      supervisedSuccess: supervisedSuccess,
      stuckIn18PlusPath: stuckIn18PlusPath,
      successRate: successRate,
    )
  }
}

private struct DistinctVendorCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT \(IOSEvent.columnName(.vendorId))) AS count
    FROM \(IOSEvent.qualifiedTableName)
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

private struct StandardSuccessCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(IOSEvent.qualifiedTableName)
    WHERE vendor_id IS NOT NULL
      AND event_id = 'cdb31095'
      AND vendor_id IN (
        SELECT vendor_id FROM \(IOSEvent.qualifiedTableName) WHERE event_id = '4a0c585f'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(IOSEvent.qualifiedTableName) WHERE event_id = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct SupervisedSuccessCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(IOSEvent.qualifiedTableName)
    WHERE vendor_id IS NOT NULL
      AND event_id = 'cdb31095'
      AND vendor_id IN (
        SELECT vendor_id FROM \(IOSEvent.qualifiedTableName) WHERE event_id = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct StuckIn18PlusCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(IOSEvent.qualifiedTableName)
    WHERE vendor_id IS NOT NULL
      AND event_id = 'a21c9040'
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(IOSEvent.qualifiedTableName) WHERE event_id = 'cdb31095'
      )
    """)
  }

  var count: Int
}

private struct ParentDeviceDropoffCount: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(IOSEvent.qualifiedTableName)
    WHERE vendor_id IS NOT NULL
      AND event_id = '30fac4e6'
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(IOSEvent.qualifiedTableName) WHERE event_id = 'cdb31095'
      )
    """)
  }

  var count: Int
}
