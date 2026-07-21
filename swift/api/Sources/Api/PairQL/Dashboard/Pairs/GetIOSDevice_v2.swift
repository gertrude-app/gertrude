import DuetSQL
import Foundation
import Gertie
import GertieBlocker
import PairQL
import PodcastRoute
import TypeScriptInterop

struct GetIOSDevice_v2: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = IOSDevice.Id

  struct Output: PairOutput {
    struct BlockGroup: PairNestable {
      var id: BlockerApp.BlockGroup.Id
      var name: String
      var description: String
      var longDescription: String
    }

    struct BlockRuleData: PairNestable {
      var id: BlockerApp.BlockRule.Id
      var rule: GertieBlocker.BlockRule
    }

    struct Blocker: PairNestable {
      var allBlockGroups: [BlockGroup]
      var enabledBlockGroups: [BlockerApp.BlockGroup.Id]
      var webPolicy: WebContentFilterPolicy.Kind
      var webPolicyDomains: [String]
      var customBlockRules: [BlockRuleData]
      var isSupervised: Bool
      var isProfileLocked: Bool
      var allowAppRemoval: Bool
      var allowEraseContentAndSettings: Bool
      var allowAppInstallation: Bool
      var extendedSupervisionControls: SaveExtendedSupervisionControls.Controls?
    }

    struct AmInstall: PairNestable {
      var subscription: AmSubscriptionState
    }

    struct MusicInstall: PairNestable {
      var requiresPayment: Bool
    }

    var childName: String
    var deviceType: String
    var osVersion: String
    var blocker: Blocker?
    var am: AmInstall?
    var music: MusicInstall?
    var musicConnected: Bool
  }
}

extension GetIOSDevice_v2: Resolver {
  static func resolve(with id: IOSDevice.Id, in ctx: ParentContext) async throws -> Output {
    let device: IOSDevice = try await ctx.db.find(id)
    guard let childId = device.childId else {
      throw ctx.error("f8a9b3c2", .notFound, user: "Device not found")
    }
    let child = try await ctx.verifiedChild(from: childId)
    let music = try await self.musicInstall(for: device, in: ctx)
    return try await Output(
      childName: child.name,
      deviceType: device.deviceType,
      osVersion: device.iosVersion,
      blocker: self.blocker(for: device, in: ctx),
      am: self.amInstall(for: device, in: ctx),
      music: music,
      musicConnected: music != nil,
    )
  }

  static func blocker(for device: IOSDevice, in ctx: ParentContext) async throws -> Output
    .Blocker? {
    guard let install = try await BlockerApp.Install.query()
      .where(.deviceId == device.id)
      .all(in: ctx.db)
      .first else {
      return nil
    }

    let tokenExists = try await BlockerApp.Token.query()
      .where(.installId == install.id)
      .exists(in: ctx.db)
    guard tokenExists else {
      return nil
    }

    let enabledBlockGroups = try await device.blockGroups(in: ctx.db)
    let allBlockGroups = try await BlockerApp.BlockGroup.query().all(in: ctx.db)
    let domains = try await device.webPolicyDomains(in: ctx.db)
    let blockRules = try await device.blockRules(in: ctx.db)
    let supervision = try await device.supervision(in: ctx.db)
    let settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: ctx.db)
    let isSupervised = supervision?.supervised ?? false
    let billing = try await ctx.currentBillingAccount()
    var extendedControls: SaveExtendedSupervisionControls.Controls?
    if isSupervised, billing.can(.manageExtendedSupervisionControls) {
      extendedControls = .init(
        whitelistedAppBundleIds: settings.whitelistedAppBundleIds,
        webAllowList: settings.webAllowList
          .map { $0.map { .init(url: $0.url, title: $0.title) } },
        allowItunes: settings.allowItunes,
        allowMusicService: settings.allowMusicService,
        allowRadioService: settings.allowRadioService,
        allowNews: settings.allowNews,
        allowBookstore: settings.allowBookstore,
        allowExplicitContent: settings.allowExplicitContent,
        ratingMovies: settings.ratingMovies,
        ratingTvShows: settings.ratingTvShows,
        allowSafari: settings.allowSafari,
        allowSpotlightInternetResults: settings.allowSpotlightInternetResults,
        allowDefinitionLookup: settings.allowDefinitionLookup,
        allowAutomaticAppDownloads: settings.allowAutomaticAppDownloads,
        allowAppClips: settings.allowAppClips,
        allowSystemAppRemoval: settings.allowSystemAppRemoval,
        allowAssistant: settings.allowAssistant,
        allowGameCenter: settings.allowGameCenter,
        forceDelayedSoftwareUpdates: settings.forceDelayedSoftwareUpdates,
        enforcedSoftwareUpdateDelay: settings.enforcedSoftwareUpdateDelay,
        forceAutomaticDateAndTime: settings.forceAutomaticDateAndTime,
      )
    }
    return Output.Blocker(
      allBlockGroups: allBlockGroups.map {
        .init(
          id: $0.id,
          name: $0.name,
          description: $0.description,
          longDescription: $0.longDescription,
        )
      },
      enabledBlockGroups: enabledBlockGroups.map(\.id),
      webPolicy: .init(string: install.webPolicy) ?? .blockAll,
      webPolicyDomains: domains.map(\.domain),
      customBlockRules: blockRules.map { .init(id: $0.id, rule: $0.rule) },
      isSupervised: isSupervised,
      isProfileLocked: settings.isProfileLocked,
      allowAppRemoval: settings.allowAppRemoval,
      allowEraseContentAndSettings: settings.allowEraseContentAndSettings,
      allowAppInstallation: settings.allowAppInstallation,
      extendedSupervisionControls: extendedControls,
    )
  }

  static func amInstall(for device: IOSDevice, in ctx: ParentContext) async throws -> Output
    .AmInstall? {
    guard let install = try await device.podcastInstall(in: ctx.db) else {
      return nil
    }
    let tokenExists = try await PodcastApp.Token.query()
      .where(.installId == install.id)
      .exists(in: ctx.db)
    guard tokenExists else { return nil }
    let account = try await ctx.currentBillingAccount()
    return Output.AmInstall(subscription: account.amSubscriptionState(forInstall: install))
  }

  static func musicInstall(for device: IOSDevice, in ctx: ParentContext) async throws -> Output
    .MusicInstall? {
    guard let install = try await device.musicInstall(in: ctx.db) else {
      return nil
    }
    let tokenExists = try await MusicApp.Token.query()
      .where(.installId == install.id)
      .exists(in: ctx.db)
    guard tokenExists else { return nil }
    let account = try await ctx.currentBillingAccount()
    return Output.MusicInstall(
      requiresPayment: account.paymentActionForMissingLightPlanCapability(.useGertrudeMusic) != nil,
    )
  }
}

extension GertieBlocker.BlockRule: @retroactive TypeScriptAliased {}
