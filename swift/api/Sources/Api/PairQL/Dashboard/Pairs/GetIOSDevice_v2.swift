import Gertie
import GertieBlocker
import PairQL
import PodcastRoute
import TypeScriptInterop

/// @deprecated safe to remove 2026-09-18
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
    let v3 = try await GetIOSDevice_v3.resolve(with: id, in: ctx)
    return Output(
      childName: v3.childName,
      deviceType: v3.deviceType,
      osVersion: v3.osVersion,
      blocker: v3.blocker.map { blocker in
        .init(
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
          extendedSupervisionControls: blocker.extendedSupervisionControls,
        )
      },
      am: v3.am.map { .init(subscription: $0.subscription) },
      music: v3.music.map {
        .init(requiresPayment: $0.subscription == .unavailable)
      },
      musicConnected: v3.musicConnected,
    )
  }
}

extension GertieBlocker.BlockRule: @retroactive TypeScriptAliased {}
