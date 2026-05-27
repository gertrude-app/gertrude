import Foundation
import Gertie
import GertieIOS
import PairQL
import TypeScriptInterop

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
    let device: IOSDevice = try await ctx.db.find(id)
    guard let childId = device.childId else {
      throw ctx.error("f8a9b3c2", .notFound, user: "Device not found")
    }
    let child = try await ctx.verifiedChild(from: childId)
    let install = try await device.install(in: ctx.db)
    let enabledBlockGroups = try await device.blockGroups(in: ctx.db)
    let allBlockGroups = try await BlockerApp.BlockGroup.query().all(in: ctx.db)
    let domains = try await device.webPolicyDomains(in: ctx.db)
    let blockRules = try await device.blockRules(in: ctx.db)
    let supervision = try await device.supervision(in: ctx.db)
    return .init(
      childName: child.name,
      deviceType: device.deviceType,
      osVersion: device.iosVersion,
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
}

extension GertieIOS.BlockRule: @retroactive TypeScriptAliased {}
