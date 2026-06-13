import DuetSQL
import Foundation

extension PodcastApp {
  struct Install: Codable, Sendable, Equatable {
    var id: Id
    var deviceId: IOSDevice.Id
    var appVersion: String
    var createdAt = Date()
    var updatedAt = Date()

    init(id: Id = .init(), deviceId: IOSDevice.Id, appVersion: String) {
      self.id = id
      self.deviceId = deviceId
      self.appVersion = appVersion
    }
  }
}

// extensions

extension PodcastApp.Install {
  static let trialPeriod: TimeInterval = .days(30)

  @discardableResult
  static func ensureExists(
    deviceId: IOSDevice.Id,
    modelIdentifier: String,
    iosVersion: String,
    appVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> PodcastApp.Install {
    try await db.withTransaction { txn in
      try await self.insertDeviceIfNeeded(
        id: deviceId,
        modelIdentifier: modelIdentifier,
        iosVersion: iosVersion,
        in: txn,
      )
      var device = try await txn.find(deviceId)
      var saveDevice = false
      if device.shouldUpdateModelIdentifier(to: modelIdentifier) {
        device.modelIdentifier = modelIdentifier
        saveDevice = true
      }
      if device.iosVersion != iosVersion {
        device.iosVersion = iosVersion
        saveDevice = true
      }
      if saveDevice {
        try await txn.update(device)
      }
      return try await self.upsert(deviceId: deviceId, appVersion: appVersion, in: txn)
    }
  }

  // TODO: generalize duet upsert
  private static func insertDeviceIfNeeded(
    id: IOSDevice.Id,
    modelIdentifier: String,
    iosVersion: String,
    in db: any DuetSQL.Client,
  ) async throws {
    typealias D = IOSDevice
    var stmt = SQL.Statement("""
      INSERT INTO \(table: D.self) (
        \(D.columnName(.id)),
        \(D.columnName(.modelIdentifier)),
        \(D.columnName(.iosVersion)),
        \(D.columnName(.createdAt)),
        \(D.columnName(.updatedAt))
      ) VALUES (
    """)
    stmt.components.append(.binding(.uuid(id)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.string(modelIdentifier)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.string(iosVersion)))
    stmt.components.append(.sql(", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"))
    stmt.components.append(.sql("""
      ON CONFLICT (\(D.columnName(.id))) DO NOTHING
    """))
    try await db.execute(statement: stmt)
  }

  // TODO: generalize duet upsert
  private static func upsert(
    deviceId: IOSDevice.Id,
    appVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> PodcastApp.Install {
    typealias I = PodcastApp.Install
    let install = I(deviceId: deviceId, appVersion: appVersion)
    var stmt = SQL.Statement("""
      INSERT INTO \(table: I.self) AS existing (
        \(I.columnName(.id)),
        \(I.columnName(.deviceId)),
        \(I.columnName(.appVersion)),
        \(I.columnName(.createdAt)),
        \(I.columnName(.updatedAt))
      ) VALUES (
    """)
    stmt.components.append(.binding(.id(install)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.uuid(deviceId)))
    stmt.components.append(.sql(", "))
    stmt.components.append(.binding(.string(appVersion)))
    stmt.components.append(.sql(", CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"))
    stmt.components.append(.sql("""
      ON CONFLICT (\(I.columnName(.deviceId)))
      DO UPDATE SET
        \(I.columnName(.appVersion)) = EXCLUDED.\(I.columnName(.appVersion)),
        \(I.columnName(.updatedAt)) = CASE
          WHEN existing.\(I.columnName(.appVersion))
            IS DISTINCT FROM EXCLUDED.\(I.columnName(.appVersion))
          THEN CURRENT_TIMESTAMP
          ELSE existing.\(I.columnName(.updatedAt))
        END
      RETURNING *
    """))
    guard let install = try await db.execute(statement: stmt, returning: I.self).first else {
      throw DuetSQLError.notFound("\(I.self)")
    }
    return install
  }

  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}

extension PodcastApp {
  enum LegacyIap {
    static let honoredYear: TimeInterval = .days(365)
    static let migrationApology: TimeInterval = .days(90)
    static let grantWindow: TimeInterval = honoredYear + migrationApology
    static let nagWindow: TimeInterval = .days(60)

    static func showMigrationNag(accessEndsAt: Date, now: Date) -> Bool {
      now >= accessEndsAt - self.nagWindow
    }
  }
}
