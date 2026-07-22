import Dependencies
import DuetSQL
import PairQL

struct MusicInstallsList: Pair {
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
    var albumCount: Int
    var status: String
  }
}

extension MusicInstallsList: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    @Dependency(\.date.now) var now
    let pageSize = input.pageSize ?? 30
    let page = max(1, input.page)
    let offset = (page - 1) * pageSize

    let totalCount = try await context.db.count(MusicInstallCount.self)
    let totalPages = max(1, Int(ceil(Double(totalCount) / Double(pageSize))))

    let rows = try await context.db.customQuery(
      MusicInstallSummaryQuery.self,
      withBindings: [.int(pageSize), .int(offset)],
    )

    var installs: [InstallSummary] = []
    for row in rows {
      try await installs.append(InstallSummary(
        deviceId: row.deviceId,
        deviceType: ModelIdentifier.deviceType(from: row.modelIdentifier),
        modelName: ModelIdentifier.marketingName(for: row.modelIdentifier),
        iosVersion: row.iosVersion,
        appVersion: row.appVersion,
        firstLaunch: row.firstLaunch,
        albumCount: row.albumCount,
        status: Self.status(
          deviceId: IOSDevice.Id(row.deviceId),
          connected: row.connected,
          at: now,
          in: context,
        ),
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
    deviceId: IOSDevice.Id,
    connected: Bool,
    at now: Date,
    in context: Context,
  ) async throws -> String {
    guard connected else {
      return "unclaimed"
    }
    guard let device = try? await context.db.find(deviceId) as IOSDevice,
          let child = try await device.child(in: context.db) else {
      return "connected"
    }
    let parent = try await child.parent(in: context.db)
    let snapshot = try await parent.billingAccountSnapshot(in: context.db, at: now)
    return Self.status(connected: connected, snapshot: snapshot)
  }

  static func status(
    connected: Bool,
    snapshot: BillingAccountSnapshot?,
  ) -> String {
    guard connected else {
      return "unclaimed"
    }
    guard let snapshot else {
      return "connected"
    }
    if snapshot.planStatus == .complimentary {
      return "complimentary"
    }
    return snapshot.can(.useGertrudeMusic) ? "paid" : "connected"
  }
}

private struct MusicInstallCount: CustomCountable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    SQL.Statement("""
    SELECT COUNT(*) AS count
    FROM \(table: MusicApp.Install.self)
    """)
  }

  var count: Int
}

private struct MusicInstallSummaryQuery: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    guard bindings.count == 2 else {
      return SQL.Statement("SELECT NULL WHERE FALSE")
    }
    let limit = bindings[0]
    let offset = bindings[1]
    let installDevice = MusicApp.Install.columnName(.deviceId)
    let installAppVersion = MusicApp.Install.columnName(.appVersion)
    let installCreated = MusicApp.Install.columnName(.createdAt)
    let installId = MusicApp.Install.columnName(.id)
    let deviceId = IOSDevice.columnName(.id)
    let deviceChild = IOSDevice.columnName(.childId)
    let deviceModel = IOSDevice.columnName(.modelIdentifier)
    let deviceIos = IOSDevice.columnName(.iosVersion)
    let tokenInstall = MusicApp.Token.columnName(.installId)
    let albumChild = Music.ApprovedAlbum.columnName(.childId)
    var stmt = SQL.Statement("""
    SELECT
      i.\(installDevice) AS device_id,
      d.\(deviceModel) AS model_identifier,
      d.\(deviceIos) AS ios_version,
      i.\(installAppVersion) AS app_version,
      i.\(installCreated) AS first_launch,
      CASE WHEN t.\(tokenInstall) IS NOT NULL THEN true ELSE false END AS connected,
      COALESCE(albums.album_count, 0)::int AS album_count
    FROM \(table: MusicApp.Install.self) i
    JOIN \(table: IOSDevice.self) d ON d.\(deviceId) = i.\(installDevice)
    LEFT JOIN \(table: MusicApp.Token.self) t ON t.\(tokenInstall) = i.\(installId)
    LEFT JOIN LATERAL (
      SELECT COUNT(*)::int AS album_count
      FROM \(table: Music.ApprovedAlbum.self) aa
      WHERE aa.\(albumChild) = d.\(deviceChild)
    ) albums ON true
    ORDER BY i.\(installCreated) DESC
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
  var connected: Bool
  var albumCount: Int
}
