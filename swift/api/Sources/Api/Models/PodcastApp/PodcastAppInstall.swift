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

  private static func insertDeviceIfNeeded(
    id: IOSDevice.Id,
    modelIdentifier: String,
    iosVersion: String,
    in db: any DuetSQL.Client,
  ) async throws {
    try await db.create(
      IOSDevice(id: id, modelIdentifier: modelIdentifier, iosVersion: iosVersion),
      ignoringConflictOn: [.id],
    )
  }

  private static func upsert(
    deviceId: IOSDevice.Id,
    appVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> PodcastApp.Install {
    try await db.upsert(
      PodcastApp.Install(deviceId: deviceId, appVersion: appVersion),
      conflictOn: [.deviceId],
      do: .updateRaw { c in
        """
        \(c.col(.appVersion)) = \(c.excluded(.appVersion)),
        \(c.col(.updatedAt)) = CASE
          WHEN \(c.target(.appVersion)) IS DISTINCT FROM \(c.excluded(.appVersion))
          THEN CURRENT_TIMESTAMP
          ELSE \(c.target(.updatedAt))
        END
        """
      },
    )
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
