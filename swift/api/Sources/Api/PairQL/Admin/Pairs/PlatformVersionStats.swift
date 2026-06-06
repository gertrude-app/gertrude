import DuetSQL
import PairQL

struct PlatformVersionStats: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var activeDays: Int
    var macos: Platform
    var ios: Platform
  }

  struct Platform: PairNestable {
    var total: Int
    var versions: [VersionCount]
  }

  struct VersionCount: PairNestable {
    var version: String
    var count: Int
  }
}

extension PlatformVersionStats: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let macVersions = try await context.db.customQuery(ActiveMacOSVersionsQuery.self)
      .map { VersionCount(version: $0.version, count: $0.count) }
    let iosVersions = try await context.db.customQuery(ActiveIOSVersionsQuery.self)
      .map { VersionCount(version: $0.version, count: $0.count) }

    return .init(
      activeDays: 30,
      macos: .init(
        total: macVersions.reduce(0) { $0 + $1.count },
        versions: macVersions,
      ),
      ios: .init(
        total: iosVersions.reduce(0) { $0 + $1.count },
        versions: iosVersions,
      ),
    )
  }
}

private struct ActiveMacOSVersionsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let screenshotComputerUserId = Screenshot.columnName(.computerUserId)
    let screenshotCreatedAt = Screenshot.columnName(.createdAt)
    let keystrokeComputerUserId = KeystrokeLine.columnName(.computerUserId)
    let keystrokeCreatedAt = KeystrokeLine.columnName(.createdAt)
    let interestingComputerUserId = InterestingEvent.columnName(.computerUserId)
    let interestingCreatedAt = InterestingEvent.columnName(.createdAt)
    let securityComputerUserId = SecurityEvent.columnName(.computerUserId)
    let securityCreatedAt = SecurityEvent.columnName(.createdAt)
    let computerUserId = ComputerUser.columnName(.id)
    let computerUserComputerId = ComputerUser.columnName(.computerId)
    let computerId = Computer.columnName(.id)
    let osVersion = Computer.columnName(.osVersion)

    return SQL.Statement("""
    WITH active_versions AS (
      SELECT DISTINCT
        c.\(computerId) AS computer_id,
        CASE
          WHEN SPLIT_PART(c.\(osVersion), '.', 1) = '10'
            THEN SPLIT_PART(c.\(osVersion), '.', 1) || '.' || SPLIT_PART(c.\(osVersion), '.', 2)
          ELSE SPLIT_PART(c.\(osVersion), '.', 1)
        END AS version
      FROM \(table: Computer.self) c
      JOIN \(table: ComputerUser.self) cu
        ON cu.\(computerUserComputerId) = c.\(computerId)
      WHERE NULLIF(c.\(osVersion), '') IS NOT NULL
        AND (
          EXISTS (
            SELECT 1
            FROM \(table: Screenshot.self) s
            WHERE s.\(screenshotComputerUserId) = cu.\(computerUserId)
              AND s.\(screenshotCreatedAt) >= CURRENT_TIMESTAMP - INTERVAL '30 days'
          )
          OR EXISTS (
            SELECT 1
            FROM \(table: KeystrokeLine.self) k
            WHERE k.\(keystrokeComputerUserId) = cu.\(computerUserId)
              AND k.\(keystrokeCreatedAt) >= CURRENT_TIMESTAMP - INTERVAL '30 days'
          )
          OR EXISTS (
            SELECT 1
            FROM \(table: InterestingEvent.self) ie
            WHERE ie.\(interestingComputerUserId) = cu.\(computerUserId)
              AND ie.\(interestingCreatedAt) >= CURRENT_TIMESTAMP - INTERVAL '30 days'
          )
          OR EXISTS (
            SELECT 1
            FROM \(table: SecurityEvent.self) se
            WHERE se.\(securityComputerUserId) = cu.\(computerUserId)
              AND se.\(securityCreatedAt) >= CURRENT_TIMESTAMP - INTERVAL '30 days'
          )
        )
    )
    SELECT
      version,
      COUNT(*)::int AS count
    FROM active_versions
    GROUP BY version
    ORDER BY string_to_array(version, '.')::int[] DESC
    """)
  }

  var version: String
  var count: Int
}

private struct ActiveIOSVersionsQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let iosEventDeviceId = IOSEvent.columnName(.deviceId)
    let iosEventCreatedAt = IOSEvent.columnName(.createdAt)
    let podcastEventDeviceId = PodcastEvent.columnName(.deviceId)
    let podcastEventCreatedAt = PodcastEvent.columnName(.createdAt)
    let deviceId = IOSDevice.columnName(.id)
    let iosVersion = IOSDevice.columnName(.iosVersion)

    return SQL.Statement("""
    WITH active_devices AS (
      SELECT
        d.\(deviceId) AS device_id,
        d.\(iosVersion) AS ios_version
      FROM \(table: IOSDevice.self) d
      WHERE NULLIF(d.\(iosVersion), '') IS NOT NULL
        AND (
          EXISTS (
            SELECT 1
            FROM \(table: IOSEvent.self) e
            WHERE e.\(iosEventDeviceId) = d.\(deviceId)
              AND e.\(iosEventCreatedAt) >= CURRENT_TIMESTAMP - INTERVAL '30 days'
          )
          OR EXISTS (
            SELECT 1
            FROM \(table: PodcastEvent.self) p
            WHERE p.\(podcastEventDeviceId) = d.\(deviceId)
              AND p.\(podcastEventCreatedAt) >= CURRENT_TIMESTAMP - INTERVAL '30 days'
          )
        )
    )
    SELECT
      SPLIT_PART(ios_version, '.', 1) AS version,
      COUNT(*)::int AS count
    FROM active_devices
    GROUP BY SPLIT_PART(ios_version, '.', 1)
    ORDER BY CASE
      WHEN SPLIT_PART(ios_version, '.', 1) ~ '^[0-9]+$'
        THEN SPLIT_PART(ios_version, '.', 1)::int
      ELSE -1
    END DESC
    """)
  }

  var version: String
  var count: Int
}
