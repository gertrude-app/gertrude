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

extension MusicApp.Install: IOSAppInstall {
  init(deviceId: IOSDevice.Id, appVersion: String) {
    self.init(id: .init(), deviceId: deviceId, appVersion: appVersion)
  }

  static var deviceIdColumn: CodingKeys { .deviceId }
  static var appVersionColumn: CodingKeys { .appVersion }
  static var updatedAtColumn: CodingKeys { .updatedAt }
}
