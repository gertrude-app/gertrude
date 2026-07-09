import DuetSQL
import Foundation

extension BlockerApp {
  @DuetModel(schema: "blocker_app", table: "profile_settings")
  struct ProfileSettings: Codable, Sendable, Equatable {
    var id: Id
    var deviceId: IOSDevice.Id
    var isProfileLocked: Bool
    var allowAppRemoval: Bool
    var allowEraseContentAndSettings: Bool
    var allowAppInstallation: Bool
    var whitelistedAppBundleIds: [String]?
    var webAllowList: [Bookmark]?
    var createdAt = Date()
    var updatedAt = Date()

    init(
      id: Id = .init(),
      deviceId: IOSDevice.Id,
      isProfileLocked: Bool = true,
      allowAppRemoval: Bool = false,
      allowEraseContentAndSettings: Bool = false,
      allowAppInstallation: Bool = true,
      whitelistedAppBundleIds: [String]? = nil,
      webAllowList: [Bookmark]? = nil,
    ) {
      self.id = id
      self.deviceId = deviceId
      self.isProfileLocked = isProfileLocked
      self.allowAppRemoval = allowAppRemoval
      self.allowEraseContentAndSettings = allowEraseContentAndSettings
      self.allowAppInstallation = allowAppInstallation
      self.whitelistedAppBundleIds = whitelistedAppBundleIds
      self.webAllowList = webAllowList
    }
  }
}

extension BlockerApp.ProfileSettings {
  struct Bookmark: Codable, Sendable, Equatable {
    var url: String
    var title: String
  }
}

extension BlockerApp.ProfileSettings {
  static func ensure(
    for deviceId: IOSDevice.Id,
    in db: any DuetSQL.Client,
  ) async throws -> BlockerApp.ProfileSettings {
    try await db.findOrCreate(
      BlockerApp.ProfileSettings(deviceId: deviceId),
      conflictOn: [.deviceId],
    )
  }

  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await IOSDevice.query()
      .where(.id == self.deviceId)
      .first(in: db)
  }
}
