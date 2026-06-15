import DuetSQL
import Foundation
import Gertie
import GertieIOS
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
      var rule: GertieIOS.BlockRule
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
    }

    struct AmInstall: PairNestable {
      var subscription: AmSubscriptionState
    }

    var childName: String
    var deviceType: String
    var osVersion: String
    var blocker: Blocker?
    var am: AmInstall?
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
    return try await Output(
      childName: child.name,
      deviceType: device.deviceType,
      osVersion: device.iosVersion,
      blocker: self.blocker(for: device, in: ctx),
      am: self.amInstall(for: device, in: ctx),
      musicConnected: self.musicConnected(for: device, in: ctx),
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
    let enabledBlockGroups = try await device.blockGroups(in: ctx.db)
    let allBlockGroups = try await BlockerApp.BlockGroup.query().all(in: ctx.db)
    let domains = try await device.webPolicyDomains(in: ctx.db)
    let blockRules = try await device.blockRules(in: ctx.db)
    let supervision = try await device.supervision(in: ctx.db)
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
      isSupervised: supervision?.supervised ?? false,
      isProfileLocked: install.isProfileLocked,
      allowAppRemoval: install.allowAppRemoval,
      allowEraseContentAndSettings: install.allowEraseContentAndSettings,
      allowAppInstallation: install.allowAppInstallation,
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

  static func musicConnected(for device: IOSDevice, in ctx: ParentContext) async throws -> Bool {
    guard let install = try await device.musicInstall(in: ctx.db) else {
      return false
    }
    return try await MusicApp.Token.query()
      .where(.installId == install.id)
      .exists(in: ctx.db)
  }
}

extension GertieIOS.BlockRule: @retroactive TypeScriptAliased {}
