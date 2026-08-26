import DuetSQL
import Foundation

extension MusicApp {
  @DuetModel(schema: "music_app", table: "installs")
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
  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }

  func token(in db: any DuetSQL.Client) async throws -> MusicApp.Token? {
    try await MusicApp.Token.query()
      .where(.installId == self.id)
      .first(in: db)
  }

  func hasToken(in db: any DuetSQL.Client) async throws -> Bool {
    try await MusicApp.Token.query()
      .where(.installId == self.id)
      .exists(in: db)
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
