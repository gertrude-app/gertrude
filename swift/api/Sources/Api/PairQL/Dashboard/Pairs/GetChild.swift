import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct UserKeychainSummary: PairNestable {
  var id: Api.Keychain.Id
  var parentId: Parent.Id
  var name: String
  var description: String?
  var isPublic: Bool
  var numKeys: Int
  var schedule: RuleSchedule?
}

struct AlwaysBlockedGroupSummary: PairNestable {
  var id: AlwaysBlockedGroup.Id
  var name: String
  var description: String
  var longDescription: String
}

struct ChildCustomBlockRule: PairNestable {
  var id: ChildAlwaysBlockedRule.Id
  var rule: BlockRule
  var comment: String?
}

struct GetChild: Pair {
  static let auth: ClientAuth = .parent

  struct Child: PairOutput {
    var id: Api.Child.Id
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var showSuspensionActivity: Bool
    var filteringDisabled: Bool
    var canDisableFilter: Bool
    var keychains: [UserKeychainSummary]
    var downtime: PlainTimeWindow?
    var computers: [Computer]
    var iosDevices: [IOSDevice]
    var blockedApps: [UserBlockedApp.DTO]?
    var availableAlwaysBlockedGroups: [AlwaysBlockedGroupSummary]
    var alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id]
    var customAlwaysBlockedRules: [ChildCustomBlockRule]
    var supportsAlwaysBlocked: Bool
    var createdAt: Date
  }

  struct Computer: PairNestable {
    var id: ComputerUser.Id
    var computerId: Api.Computer.Id
    var status: ChildComputerStatus
    var modelFamily: DeviceModelFamily
    var modelTitle: String
    var modelIdentifier: String
    var customName: String?
  }

  struct IOSDevice: PairNestable {
    var id: IOSApp.Device.Id
    var modelName: String
    var deviceType: String
    var iosVersion: String
    var pendingClaimCode: Int?
  }

  typealias Input = Api.Child.Id
  typealias Output = Child
}

// resolver

extension GetChild: Resolver {
  static func resolve(
    with id: Api.Child.Id,
    in context: ParentContext,
  ) async throws -> Output {
    let child = try await context.verifiedChild(from: id)
    async let childKeychains = childKeychainSummaries(for: child.id, in: context.db)
    async let availableAlwaysBlockedGroups = AlwaysBlockedGroup.query()
      .orderBy(.name, .asc)
      .all(in: context.db)
      .map { AlwaysBlockedGroupSummary(
        id: $0.id,
        name: $0.name,
        description: $0.description,
        longDescription: $0.longDescription,
      ) }
    async let alwaysBlockedGroupIds = ChildAlwaysBlockedGroup.query()
      .where(.childId == child.id)
      .all(in: context.db)
      .map(\.groupId)
    async let customAlwaysBlockedRules = ChildAlwaysBlockedRule.query()
      .where(.childId == child.id)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
      .map { ChildCustomBlockRule(id: $0.id, rule: $0.rule, comment: $0.comment) }
    let pairs = try await ComputerUser.query()
      .where(.childId == child.id)
      .all(in: context.db)
      .concurrentMap { (computerUser: ComputerUser) -> (GetChild.Computer, Semver) in
        let computer = try await computerUser.computer(in: context.db)
        return await (GetChild.Computer(
          id: computerUser.id,
          computerId: computer.id,
          status: computerUser.status(),
          modelFamily: computer.model.family,
          modelTitle: computer.model.shortDescription,
          modelIdentifier: computer.model.identifier,
          customName: computer.customName,
        ), computer.filterVersion ?? .zero)
      }
    let computers = pairs.map(\.0)
    let versions = pairs.map(\.1)

    let devices = try await child.iosDevices(in: context.db)

    var blockedApps: [UserBlockedApp.DTO]?
    if versions.contains(where: { $0 >= .init("2.6.0")! }) {
      blockedApps = try await (child.blockedApps(in: context.db)).map(\.dto)
    }

    let canDisableFilter = !versions.isEmpty
      && versions.allSatisfy { $0 >= .init("2.9.0")! }

    let supportsAlwaysBlocked = !versions.isEmpty
      && versions.allSatisfy { $0 >= .init("2.9.1")! }

    return try await .init(
      id: child.id,
      name: child.name,
      keyloggingEnabled: child.keyloggingEnabled,
      screenshotsEnabled: child.screenshotsEnabled,
      screenshotsResolution: child.screenshotsResolution,
      screenshotsFrequency: child.screenshotsFrequency,
      showSuspensionActivity: child.showSuspensionActivity,
      filteringDisabled: child.filteringDisabled,
      canDisableFilter: canDisableFilter,
      keychains: childKeychains,
      downtime: child.downtime,
      computers: computers.uniqued(on: \.id),
      iosDevices: devices.concurrentMap { device in
        let supervision = try await device.supervision(in: context.db)
        return .init(
          id: device.id,
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          pendingClaimCode: supervision?.supervised == false ? supervision?.claimCode : nil,
        )
      },
      blockedApps: blockedApps,
      availableAlwaysBlockedGroups: availableAlwaysBlockedGroups,
      alwaysBlockedGroupIds: alwaysBlockedGroupIds,
      customAlwaysBlockedRules: customAlwaysBlockedRules,
      supportsAlwaysBlocked: supportsAlwaysBlocked,
      createdAt: child.createdAt,
    )
  }
}

// TODO: this is major N+1 territory, write a custom query w/ join for perf
// @see also ruleKeychains(for:in:)
func childKeychainSummaries(
  for childId: Child.Id,
  in db: any DuetSQL.Client,
) async throws -> [UserKeychainSummary] {
  let childKeychains = try await ChildKeychain.query()
    .where(.childId == childId)
    .all(in: db)
  let keychains = try await Keychain.query()
    .where(.id |=| childKeychains.map(\.keychainId))
    .all(in: db)
  return try await keychains.concurrentMap { keychain in
    let numKeys = try await db.count(
      Key.self,
      where: .keychainId == keychain.id,
      withSoftDeleted: false,
    )
    return .init(
      id: keychain.id,
      parentId: keychain.parentId,
      name: keychain.name,
      description: keychain.description,
      isPublic: keychain.isPublic,
      numKeys: numKeys,
      schedule: childKeychains.first { $0.keychainId == keychain.id }?.schedule,
    )
  }
}
