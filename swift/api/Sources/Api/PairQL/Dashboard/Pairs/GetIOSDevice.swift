import Foundation
import Gertie
import GertieIOS
import PairQL
import TypeScriptInterop

/// @deprecated safe to remove 2026-06-11
struct GetIOSDevice: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = IOSDevice.Id

  struct Output: PairOutput {
    struct BlockGroup: PairNestable {
      var id: BlockerApp.BlockGroup.Id
      var name: String
      var description: String
      var longDescription: String
    }

    struct BlockRuleData: PairOutput {
      var id: BlockerApp.BlockRule.Id
      var rule: GertieIOS.BlockRule
    }

    var childName: String
    var deviceType: String
    var osVersion: String
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
}

extension GetIOSDevice: Resolver {
  static func resolve(with id: IOSDevice.Id, in ctx: ParentContext) async throws -> Output {
    await ctx.db.logDeprecated("GetIOSDevice(v1)")
    let v2 = try await GetIOSDevice_v2.resolve(with: id, in: ctx)
    guard let blocker = v2.blocker else {
      throw ctx.error("e3f1a8b7", .notFound, user: "Device not found")
    }
    return Output(
      childName: v2.childName,
      deviceType: v2.deviceType,
      osVersion: v2.osVersion,
      allBlockGroups: blocker.allBlockGroups.map {
        .init(
          id: $0.id,
          name: $0.name,
          description: $0.description,
          longDescription: $0.longDescription,
        )
      },
      enabledBlockGroups: blocker.enabledBlockGroups,
      webPolicy: blocker.webPolicy,
      webPolicyDomains: blocker.webPolicyDomains,
      customBlockRules: blocker.customBlockRules.map { .init(id: $0.id, rule: $0.rule) },
      isSupervised: blocker.isSupervised,
      isProfileLocked: blocker.isProfileLocked,
      allowAppRemoval: blocker.allowAppRemoval,
      allowEraseContentAndSettings: blocker.allowEraseContentAndSettings,
      allowAppInstallation: blocker.allowAppInstallation,
    )
  }
}
