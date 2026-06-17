import DuetSQL
import Foundation

extension MusicApp {
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

extension MusicApp.Install {
  @discardableResult
  static func ensureExists(
    deviceId: IOSDevice.Id,
    modelIdentifier: String,
    iosVersion: String,
    appVersion: String,
    in db: any DuetSQL.Client,
  ) async throws -> MusicApp.Install {
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
  ) async throws -> MusicApp.Install {
    try await db.upsert(
      MusicApp.Install(deviceId: deviceId, appVersion: appVersion),
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
