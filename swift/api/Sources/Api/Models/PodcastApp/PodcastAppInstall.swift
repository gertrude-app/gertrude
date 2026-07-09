import DuetSQL
import Foundation

extension PodcastApp {
  @DuetModel(schema: "podcast_app", table: "installs")
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

extension PodcastApp.Install: IOSAppInstall {
  static let trialPeriod: TimeInterval = .days(30)

  init(deviceId: IOSDevice.Id, appVersion: String) {
    self.init(id: .init(), deviceId: deviceId, appVersion: appVersion)
  }

  static var deviceIdColumn: CodingKeys { .deviceId }
  static var appVersionColumn: CodingKeys { .appVersion }
  static var updatedAtColumn: CodingKeys { .updatedAt }
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
