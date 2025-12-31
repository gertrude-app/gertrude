import DuetSQL
import PairQL

struct IOSDetailedStats: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var dateRange: DateRange
    var overview: Overview
    var outcomes: Outcomes
    var successBreakdown: SuccessBreakdown
    var installFailures: InstallFailures
    var cacheClearing: CacheClearing
    var devices: Devices
    var topRegions: [RegionCount]
    var topIOSVersions: [VersionCount]
    var funnelEvents: [EventCount]
    var dropoffEvents: [EventCount]
    var errorEvents: [EventCount]
  }

  struct DateRange: PairNestable {
    var start: Date
    var end: Date
    var totalDays: Int
  }

  struct Overview: PairNestable {
    var firstLaunches: Int
    var parentFalseStarts: Int
    var adjustedLaunches: Int
    var totalSuccess: Int
    var successPct: Double
  }

  struct Outcomes: PairNestable {
    var success: OutcomeItem
    var parentDevice: OutcomeItem
    var childOnboardingIssue: OutcomeItem
    var stuckIn18Plus: OutcomeItem
    var fullInstallFailed: OutcomeItem
    var earlyDrop: OutcomeItem
  }

  struct OutcomeItem: PairNestable {
    var count: Int
    var pct: Double
  }

  struct SuccessBreakdown: PairNestable {
    var screenTime: SuccessItem
    var supervision: SuccessItem
  }

  struct SuccessItem: PairNestable {
    var count: Int
    var pctOfSuccess: Double
    var pctOfLaunch: Double
  }

  struct InstallFailures: PairNestable {
    var invalidAccountType: Int
    var authCanceled: Int
    var authRestricted: Int
    var filterInstallFailed: Int
    var total: Int
  }

  struct CacheClearing: PairNestable {
    var started: Int
    var completed: Int
    var errors: Int
    var successRate: Double
    var onboardingStarted: Int
    var onboardingCompleted: Int
    var infoStarted: Int
    var infoCompleted: Int
  }

  struct Devices: PairNestable {
    var iphone: DeviceCount
    var ipad: DeviceCount
  }

  struct DeviceCount: PairNestable {
    var count: Int
    var pct: Double
  }

  struct RegionCount: PairNestable {
    var region: String
    var name: String
    var count: Int
  }

  struct VersionCount: PairNestable {
    var version: String
    var count: Int
  }

  struct EventCount: PairNestable {
    var id: String
    var name: String
    var count: Int
  }
}

extension IOSDetailedStats: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let firstLaunches = try await distinctVendorCount(for: "8d35f043", in: context)
    let totalSuccess = try await distinctVendorCount(for: "cdb31095", in: context)
    let parentFalseStarts = try await context.db.count(ParentDeviceDropoffCount.self)
    let stuckIn18Plus = try await context.db.count(StuckIn18PlusCount.self)
    let standardSuccess = try await context.db.count(StandardSuccessCount.self)
    let supervisedSuccess = try await context.db.count(SupervisedSuccessCount.self)
    let childOnboardingIssue = try await context.db.count(ChildOnboardingIssueCount.self)

    let invalidAccountType = try await authFailureCount(for: "2bcf3d96", in: context)
    let authCanceled = try await authFailureCount(for: "e220a765", in: context)
    let authRestricted = try await authFailureCount(for: "6f0a66e4", in: context)
    let filterInstallFailed = try await context.db.count(FilterInstallFailedCount.self)
    let fullInstallFailedUnique = try await context.db.count(CombinedInstallFailureCount.self)

    let adjustedLaunches = firstLaunches - parentFalseStarts
    let earlyDrop = firstLaunches - totalSuccess - parentFalseStarts
      - childOnboardingIssue - stuckIn18Plus - fullInstallFailedUnique
    let earlyDropClamped = max(0, earlyDrop)

    let cacheStartedOnboarding = try await context.db.count(
      CacheEventCount.self,
      withBindings: [.string("ea3f9c37"), .string("%onboarding%")],
    )
    let cacheStartedInfo = try await context.db.count(
      CacheEventCount.self,
      withBindings: [.string("ea3f9c37"), .string("%info%")],
    )
    let cacheCompletedOnboarding = try await context.db.count(
      CacheEventCount.self,
      withBindings: [.string("cb9cf096"), .string("%onboarding%")],
    )
    let cacheCompletedInfo = try await context.db.count(
      CacheEventCount.self,
      withBindings: [.string("cb9cf096"), .string("%info%")],
    )
    let cacheErrors = try await distinctVendorCount(for: "ae941213", in: context)

    let cacheStarted = cacheStartedOnboarding + cacheStartedInfo
    let cacheCompleted = cacheCompletedOnboarding + cacheCompletedInfo

    let iphoneCount = try await context.db.count(
      DeviceTypeCount.self,
      withBindings: [.string("iPhone%")],
    )
    let ipadCount = try await context.db.count(
      DeviceTypeCount.self,
      withBindings: [.string("iPad%")],
    )
    let totalDevices = iphoneCount + ipadCount

    let topRegions = try await context.db.customQuery(TopRegionsQuery.self)
    let topVersions = try await context.db.customQuery(TopVersionsQuery.self)

    let dateRangeResult = try await context.db.customQuery(DateRangeQuery.self).first

    func pct(_ value: Int, of total: Int) -> Double {
      total > 0 ? (Double(value) / Double(total) * 1000).rounded() / 10 : 0.0
    }

    return try await Output(
      dateRange: DateRange(
        start: dateRangeResult?.minDate ?? Date(),
        end: dateRangeResult?.maxDate ?? Date(),
        totalDays: dateRangeResult.map {
          Calendar.current.dateComponents([.day], from: $0.minDate, to: $0.maxDate).day ?? 0
        } ?? 0,
      ),
      overview: Overview(
        firstLaunches: firstLaunches,
        parentFalseStarts: parentFalseStarts,
        adjustedLaunches: adjustedLaunches,
        totalSuccess: totalSuccess,
        successPct: pct(totalSuccess, of: adjustedLaunches),
      ),
      outcomes: Outcomes(
        success: OutcomeItem(count: totalSuccess, pct: pct(totalSuccess, of: firstLaunches)),
        parentDevice: OutcomeItem(
          count: parentFalseStarts,
          pct: pct(parentFalseStarts, of: firstLaunches),
        ),
        childOnboardingIssue: OutcomeItem(
          count: childOnboardingIssue,
          pct: pct(childOnboardingIssue, of: firstLaunches),
        ),
        stuckIn18Plus: OutcomeItem(
          count: stuckIn18Plus,
          pct: pct(stuckIn18Plus, of: firstLaunches),
        ),
        fullInstallFailed: OutcomeItem(
          count: fullInstallFailedUnique,
          pct: pct(fullInstallFailedUnique, of: firstLaunches),
        ),
        earlyDrop: OutcomeItem(
          count: earlyDropClamped,
          pct: pct(earlyDropClamped, of: firstLaunches),
        ),
      ),
      successBreakdown: SuccessBreakdown(
        screenTime: SuccessItem(
          count: standardSuccess,
          pctOfSuccess: pct(standardSuccess, of: totalSuccess),
          pctOfLaunch: pct(standardSuccess, of: firstLaunches),
        ),
        supervision: SuccessItem(
          count: supervisedSuccess,
          pctOfSuccess: pct(supervisedSuccess, of: totalSuccess),
          pctOfLaunch: pct(supervisedSuccess, of: firstLaunches),
        ),
      ),
      installFailures: InstallFailures(
        invalidAccountType: invalidAccountType,
        authCanceled: authCanceled,
        authRestricted: authRestricted,
        filterInstallFailed: filterInstallFailed,
        total: fullInstallFailedUnique,
      ),
      cacheClearing: CacheClearing(
        started: cacheStarted,
        completed: cacheCompleted,
        errors: cacheErrors,
        successRate: pct(cacheCompleted, of: cacheStarted),
        onboardingStarted: cacheStartedOnboarding,
        onboardingCompleted: cacheCompletedOnboarding,
        infoStarted: cacheStartedInfo,
        infoCompleted: cacheCompletedInfo,
      ),
      devices: Devices(
        iphone: DeviceCount(count: iphoneCount, pct: pct(iphoneCount, of: totalDevices)),
        ipad: DeviceCount(count: ipadCount, pct: pct(ipadCount, of: totalDevices)),
      ),
      topRegions: topRegions.map { row in
        RegionCount(
          region: row.region,
          name: Self.regionName(for: row.region),
          count: row.count,
        )
      },
      topIOSVersions: topVersions.map { row in
        VersionCount(version: row.version, count: row.count)
      },
      funnelEvents: [
        EventCount(id: "8d35f043", name: "First launch", count: firstLaunches),
        EventCount(
          id: "6f97eb1b",
          name: "Hi There screen passed",
          count: self.distinctVendorCount(for: "6f97eb1b", in: context),
        ),
        EventCount(
          id: "666d5e0f",
          name: "Confirmed child's device",
          count: self.distinctVendorCount(for: "666d5e0f", in: context),
        ),
        EventCount(
          id: "e17137b0",
          name: "Confirmed minor device",
          count: self.distinctVendorCount(for: "e17137b0", in: context),
        ),
        EventCount(
          id: "7d0fd46e",
          name: "Confirmed in Apple Family",
          count: self.distinctVendorCount(for: "7d0fd46e", in: context),
        ),
        EventCount(
          id: "87601352",
          name: "Pre-auth screen",
          count: self.distinctVendorCount(for: "87601352", in: context),
        ),
        EventCount(
          id: "4a0c585f",
          name: "Auth succeeded",
          count: self.distinctVendorCount(for: "4a0c585f", in: context),
        ),
        EventCount(
          id: "47bee21e",
          name: "Pre-install screen",
          count: self.distinctVendorCount(for: "47bee21e", in: context),
        ),
        EventCount(id: "cdb31095", name: "Opt-out block groups (SUCCESS)", count: totalSuccess),
      ],
      dropoffEvents: [
        EventCount(
          id: "30fac4e6",
          name: "Said this is parent device",
          count: self.distinctVendorCount(for: "30fac4e6", in: context),
        ),
        EventCount(
          id: "3c4772ad",
          name: "Child already onboarding",
          count: self.distinctVendorCount(for: "3c4772ad", in: context),
        ),
        EventCount(
          id: "a21c9040",
          name: "Entered major (18+) path",
          count: self.distinctVendorCount(for: "a21c9040", in: context),
        ),
        EventCount(
          id: "daa8c7fd",
          name: "Said not in Apple Family",
          count: self.distinctVendorCount(for: "daa8c7fd", in: context),
        ),
      ],
      errorEvents: [
        EventCount(
          id: "2bcf3d96",
          name: "Invalid account type (18+ issue)",
          count: invalidAccountType,
        ),
        EventCount(id: "e220a765", name: "Auth canceled", count: authCanceled),
        EventCount(id: "6f0a66e4", name: "Auth restricted", count: authRestricted),
        EventCount(
          id: "004d0d89",
          name: "Filter install failed",
          count: self.distinctVendorCount(for: "004d0d89", in: context),
        ),
      ],
    )
  }

  private static func distinctVendorCount(
    for eventId: String,
    in context: Context,
  ) async throws -> Int {
    try await context.db.count(DistinctVendorCountQuery.self, withBindings: [.string(eventId)])
  }

  private static func authFailureCount(
    for eventId: String,
    in context: Context,
  ) async throws -> Int {
    try await context.db.count(
      AuthFailureCountExcludingSuccess.self,
      withBindings: [.string(eventId)],
    )
  }

  private static func regionName(for code: String) -> String {
    let names: [String: String] = [
      "US": "United States",
      "GB": "United Kingdom",
      "CA": "Canada",
      "AU": "Australia",
      "FR": "France",
      "DE": "Germany",
      "CN": "China",
      "JP": "Japan",
      "IN": "India",
      "BR": "Brazil",
      "MX": "Mexico",
      "ES": "Spain",
      "IT": "Italy",
      "NL": "Netherlands",
      "SE": "Sweden",
      "NO": "Norway",
      "DK": "Denmark",
      "FI": "Finland",
      "NZ": "New Zealand",
      "IE": "Ireland",
      "CH": "Switzerland",
      "AT": "Austria",
      "BE": "Belgium",
      "PL": "Poland",
      "PT": "Portugal",
      "IL": "Israel",
      "ZA": "South Africa",
      "SG": "Singapore",
      "HK": "Hong Kong",
      "KR": "South Korea",
      "TW": "Taiwan",
      "PH": "Philippines",
      "MY": "Malaysia",
      "ID": "Indonesia",
      "TH": "Thailand",
      "VN": "Vietnam",
      "AR": "Argentina",
      "CL": "Chile",
      "CO": "Colombia",
      "PE": "Peru",
      "RU": "Russia",
      "UA": "Ukraine",
      "CZ": "Czech Republic",
      "RO": "Romania",
      "HU": "Hungary",
      "GR": "Greece",
      "TR": "Turkey",
      "AE": "UAE",
      "SA": "Saudi Arabia",
      "EG": "Egypt",
      "NG": "Nigeria",
      "KE": "Kenya",
    ]
    return names[code] ?? code
  }
}

private struct DistinctVendorCountQuery: CustomCountable {
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

private struct AuthFailureCountExcludingSuccess: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard let eventId = bindings.first else {
      return SQL.Statement("SELECT 0 AS count WHERE FALSE")
    }
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id =
    """)
    stmt.components.append(.binding(eventId))
    stmt.components.append(.sql("""
     AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'cdb31095'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = '30fac4e6'
      )
    """))
    return stmt
  }

  var count: Int
}

private struct CombinedInstallFailureCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id IN ('2bcf3d96', 'e220a765', '6f0a66e4', '004d0d89')
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'cdb31095'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = '30fac4e6'
      )
    """)
  }

  var count: Int
}

private struct StandardSuccessCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = 'cdb31095'
      AND vendor_id IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = '4a0c585f'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct SupervisedSuccessCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = 'cdb31095'
      AND vendor_id IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'bad8adcc'
      )
    """)
  }

  var count: Int
}

private struct StuckIn18PlusCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = 'a21c9040'
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'cdb31095'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self)
        WHERE event_id IN ('2bcf3d96', 'e220a765', '6f0a66e4', '9a3f1e5b')
      )
    """)
  }

  var count: Int
}

private struct ParentDeviceDropoffCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = '30fac4e6'
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'cdb31095'
      )
    """)
  }

  var count: Int
}

private struct ChildOnboardingIssueCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = '3c4772ad'
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'cdb31095'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'a21c9040'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self)
        WHERE event_id IN ('2bcf3d96', 'e220a765', '6f0a66e4', '9a3f1e5b')
      )
    """)
  }

  var count: Int
}

private struct FilterInstallFailedCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = '004d0d89'
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = 'cdb31095'
      )
      AND vendor_id NOT IN (
        SELECT vendor_id FROM \(table: IOSEvent.self) WHERE event_id = '30fac4e6'
      )
    """)
  }

  var count: Int
}

private struct CacheEventCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id =
    """)
    if let eventId = bindings.first {
      stmt.components.append(.binding(eventId))
    }
    stmt.components.append(.sql(" AND detail LIKE "))
    if bindings.count > 1 {
      stmt.components.append(.binding(bindings[1]))
    }
    return stmt
  }

  var count: Int
}

private struct DeviceTypeCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard let pattern = bindings.first else {
      return SQL.Statement("SELECT 0 AS count WHERE FALSE")
    }
    var stmt = SQL.Statement("""
    SELECT COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = '8d35f043'
      AND device_type LIKE\(" ")
    """)
    stmt.components.append(.binding(pattern))
    return stmt
  }

  var count: Int
}

private struct TopRegionsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT
      COALESCE(SUBSTRING(detail FROM 'region: `([A-Z]{2})`'), 'Unknown') AS region,
      COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = '8d35f043'
      AND detail IS NOT NULL
    GROUP BY region
    ORDER BY count DESC
    LIMIT 10
    """)
  }

  var region: String
  var count: Int
}

private struct TopVersionsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT
      ios_version AS version,
      COUNT(DISTINCT vendor_id) AS count
    FROM \(table: IOSEvent.self)
    WHERE vendor_id IS NOT NULL
      AND event_id = '8d35f043'
    GROUP BY ios_version
    ORDER BY
      CAST(SPLIT_PART(ios_version, '.', 1) AS INTEGER) DESC,
      CAST(COALESCE(NULLIF(SPLIT_PART(ios_version, '.', 2), ''), '0') AS INTEGER) DESC,
      count DESC
    LIMIT 10
    """)
  }

  var version: String
  var count: Int
}

private struct DateRangeQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT
      MIN(created_at) AS min_date,
      MAX(created_at) AS max_date
    FROM \(table: IOSEvent.self)
    WHERE event_id = '8d35f043'
    """)
  }

  var minDate: Date
  var maxDate: Date
}
