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
    var device: IOSDevice
    var saveDevice = false
    var install: PodcastApp.Install
    var saveInstall = false

    if var existing = try? await db.find(deviceId) {
      if existing.shouldUpdateModelIdentifier(to: modelIdentifier) {
        existing.modelIdentifier = modelIdentifier
        saveDevice = true
      }
      if existing.iosVersion != iosVersion {
        existing.iosVersion = iosVersion
        saveDevice = true
      }
      device = existing
    } else {
      saveDevice = true
      device = IOSDevice(
        id: deviceId,
        modelIdentifier: modelIdentifier,
        iosVersion: iosVersion,
      )
    }

    if var existing = try? await PodcastApp.Install.query()
      .where(.deviceId == deviceId)
      .first(in: db) {
      saveInstall = existing.appVersion != appVersion
      existing.appVersion = appVersion
      install = existing
    } else {
      install = PodcastApp.Install(deviceId: deviceId, appVersion: appVersion)
      saveInstall = true
    }

    if !saveDevice, !saveInstall {
      return install
    }

    return try await db.transaction { [saveDevice, saveInstall, device, install] txn in
      if saveDevice { try await txn.upsert(device) }
      if saveInstall { try await txn.upsert(install) }
      return install
    }
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
