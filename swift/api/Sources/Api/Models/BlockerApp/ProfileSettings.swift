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
    var allowItunes: Bool?
    var allowMusicService: Bool?
    var allowRadioService: Bool?
    var allowNews: Bool?
    var allowBookstore: Bool?
    var allowExplicitContent: Bool?
    var ratingMovies: Int?
    var ratingTvShows: Int?
    var allowSafari: Bool?
    var allowSpotlightInternetResults: Bool?
    var allowDefinitionLookup: Bool?
    var allowAutomaticAppDownloads: Bool?
    var allowAppClips: Bool?
    var allowSystemAppRemoval: Bool?
    var allowAssistant: Bool?
    var allowGameCenter: Bool?
    var forceDelayedSoftwareUpdates: Bool?
    var enforcedSoftwareUpdateDelay: Int?
    var forceAutomaticDateAndTime: Bool?
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
      allowItunes: Bool? = nil,
      allowMusicService: Bool? = nil,
      allowRadioService: Bool? = nil,
      allowNews: Bool? = nil,
      allowBookstore: Bool? = nil,
      allowExplicitContent: Bool? = nil,
      ratingMovies: Int? = nil,
      ratingTvShows: Int? = nil,
      allowSafari: Bool? = nil,
      allowSpotlightInternetResults: Bool? = nil,
      allowDefinitionLookup: Bool? = nil,
      allowAutomaticAppDownloads: Bool? = nil,
      allowAppClips: Bool? = nil,
      allowSystemAppRemoval: Bool? = nil,
      allowAssistant: Bool? = nil,
      allowGameCenter: Bool? = nil,
      forceDelayedSoftwareUpdates: Bool? = nil,
      enforcedSoftwareUpdateDelay: Int? = nil,
      forceAutomaticDateAndTime: Bool? = nil,
    ) {
      self.id = id
      self.deviceId = deviceId
      self.isProfileLocked = isProfileLocked
      self.allowAppRemoval = allowAppRemoval
      self.allowEraseContentAndSettings = allowEraseContentAndSettings
      self.allowAppInstallation = allowAppInstallation
      self.whitelistedAppBundleIds = whitelistedAppBundleIds
      self.webAllowList = webAllowList
      self.allowItunes = allowItunes
      self.allowMusicService = allowMusicService
      self.allowRadioService = allowRadioService
      self.allowNews = allowNews
      self.allowBookstore = allowBookstore
      self.allowExplicitContent = allowExplicitContent
      self.ratingMovies = ratingMovies
      self.ratingTvShows = ratingTvShows
      self.allowSafari = allowSafari
      self.allowSpotlightInternetResults = allowSpotlightInternetResults
      self.allowDefinitionLookup = allowDefinitionLookup
      self.allowAutomaticAppDownloads = allowAutomaticAppDownloads
      self.allowAppClips = allowAppClips
      self.allowSystemAppRemoval = allowSystemAppRemoval
      self.allowAssistant = allowAssistant
      self.allowGameCenter = allowGameCenter
      self.forceDelayedSoftwareUpdates = forceDelayedSoftwareUpdates
      self.enforcedSoftwareUpdateDelay = enforcedSoftwareUpdateDelay
      self.forceAutomaticDateAndTime = forceAutomaticDateAndTime
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
