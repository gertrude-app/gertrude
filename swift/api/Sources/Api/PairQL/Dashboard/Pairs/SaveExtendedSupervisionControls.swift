import DuetSQL
import Foundation
import PairQL
import Vapor

struct SaveExtendedSupervisionControls: Pair {
  static let auth: ClientAuth = .parent

  struct Bookmark: PairNestable {
    var url: String
    var title: String
  }

  struct Controls: PairNestable {
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
  }

  struct Input: PairInput {
    var deviceId: IOSDevice.Id
    var controls: Controls
  }
}

extension SaveExtendedSupervisionControls: Resolver {
  static func resolve(with input: Input, in ctx: ParentContext) async throws -> Output {
    let device: IOSDevice = try await ctx.db.find(input.deviceId)
    let children = try await ctx.children()
    guard children.first(where: { $0.id == device.childId }) != nil else {
      throw Abort(.unauthorized)
    }

    let billing = try await ctx.currentBillingAccount()
    guard billing.can(.manageExtendedSupervisionControls) else {
      throw ctx.error(
        "0e7d41b9",
        .paymentRequired,
        user: "Your Gertrude account does not include extended supervision controls.",
      )
    }

    let supervision = try await device.supervision(in: ctx.db)
    guard supervision?.supervised == true else {
      throw ctx.error(
        "b4f2c6a1",
        .badRequest,
        user: "Extended supervision controls require a supervised device.",
      )
    }

    try self.validate(input.controls, in: ctx)

    var settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: ctx.db)
    settings.whitelistedAppBundleIds = input.controls.whitelistedAppBundleIds
    settings.webAllowList = input.controls.webAllowList
      .map { $0.map { .init(url: $0.url, title: $0.title) } }
    settings.allowItunes = input.controls.allowItunes
    settings.allowMusicService = input.controls.allowMusicService
    settings.allowRadioService = input.controls.allowRadioService
    settings.allowNews = input.controls.allowNews
    settings.allowBookstore = input.controls.allowBookstore
    settings.allowExplicitContent = input.controls.allowExplicitContent
    settings.ratingMovies = input.controls.ratingMovies
    settings.ratingTvShows = input.controls.ratingTvShows
    settings.allowSafari = input.controls.allowSafari
    settings.allowSpotlightInternetResults = input.controls.allowSpotlightInternetResults
    settings.allowDefinitionLookup = input.controls.allowDefinitionLookup
    settings.allowAutomaticAppDownloads = input.controls.allowAutomaticAppDownloads
    settings.allowAppClips = input.controls.allowAppClips
    settings.allowSystemAppRemoval = input.controls.allowSystemAppRemoval
    settings.allowAssistant = input.controls.allowAssistant
    settings.allowGameCenter = input.controls.allowGameCenter
    settings.forceDelayedSoftwareUpdates = input.controls.forceDelayedSoftwareUpdates
    settings.enforcedSoftwareUpdateDelay = input.controls.enforcedSoftwareUpdateDelay
    settings.forceAutomaticDateAndTime = input.controls.forceAutomaticDateAndTime
    try await ctx.db.update(settings)

    return .success
  }

  private static func validate(_ controls: Controls, in ctx: ParentContext) throws {
    if let ratingMovies = controls.ratingMovies, ratingMovies != 0 {
      throw ctx.error(
        "f9808834",
        .badRequest,
        user: "Movie rating controls must be either off or block all movies.",
      )
    }
    if let ratingTvShows = controls.ratingTvShows, ratingTvShows != 0 {
      throw ctx.error(
        "6a9a38ce",
        .badRequest,
        user: "TV rating controls must be either off or block all TV shows.",
      )
    }
    if let delay = controls.enforcedSoftwareUpdateDelay, !(1 ... 90).contains(delay) {
      throw ctx.error(
        "3f23c10c",
        .badRequest,
        user: "Software update delay must be between 1 and 90 days.",
      )
    }
  }
}
