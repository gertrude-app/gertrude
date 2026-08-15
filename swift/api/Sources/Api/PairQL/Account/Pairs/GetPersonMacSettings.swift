import DuetSQL
import Gertie
import PairQL

struct GetPersonMacSettings: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
  }

  struct ScreenshotSettings: PairNestable {
    let enabled: Bool
    let resolution: Int
    let frequency: Int
    let canBeDisabled: Bool
  }

  struct KeychainSchedule: PairNestable {
    let type: RuleSchedule.Mode
    let days: RuleSchedule.Days
    let startTime: PlainTime
    let endTime: PlainTime

    init(_ schedule: RuleSchedule) {
      self.type = schedule.mode
      self.days = schedule.days
      self.startTime = schedule.window.start
      self.endTime = schedule.window.end
    }

    var ruleSchedule: RuleSchedule {
      .init(
        mode: self.type,
        days: self.days,
        window: .init(start: self.startTime, end: self.endTime),
      )
    }
  }

  struct KeychainSettings: PairNestable {
    let id: Keychain.Id
    let name: String
    let description: String?
    let warning: String?
    let isPublic: Bool
    let isOwn: Bool
    let numKeys: Int
    let schedule: KeychainSchedule?
  }

  struct AlwaysBlockedGroupSettings: PairNestable {
    let id: AlwaysBlockedGroup.Id
    let name: String
    let description: String
    let longDescription: String
  }

  struct CustomAlwaysBlockedRule: PairNestable {
    let id: ChildAlwaysBlockedRule.Id
    let rule: BlockRule
    let comment: String?
  }

  struct InternetFilteringSettings: PairNestable {
    let enabled: Bool
    let canBeDisabled: Bool
    let downtime: PlainTimeWindow?
    let keychains: [KeychainSettings]
    let availableKeychains: [KeychainSettings]
    let supportsAlwaysBlocked: Bool
    let availableAlwaysBlockedGroups: [AlwaysBlockedGroupSettings]
    let alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id]
    let customAlwaysBlockedRules: [CustomAlwaysBlockedRule]
  }

  struct BlockedAppSettings: PairNestable {
    let id: BlockedMacApp.Id
    let identifier: String
    let schedule: KeychainSchedule?
  }

  struct UnrestrictedAppSettings: PairNestable {
    let id: UnrestrictedMacApp.Id
    let scope: AppScope.Single
    let schedule: KeychainSchedule?
  }

  struct PublicUnrestrictedAppSettings: PairNestable {
    let keychainId: Keychain.Id
    let keychainName: String
    let scope: AppScope.Single
    let schedule: KeychainSchedule?
  }

  struct AppSettings: PairNestable {
    let blocked: [BlockedAppSettings]
    let unrestricted: [UnrestrictedAppSettings]
    let publicUnrestricted: [PublicUnrestrictedAppSettings]
  }

  struct Output: PairOutput {
    let keyloggingEnabled: Bool
    let showSuspensionActivity: Bool
    let screenshots: ScreenshotSettings
    let internetFiltering: InternetFilteringSettings
    let apps: AppSettings
    let hasMacDevices: Bool
  }
}

extension GetPersonMacSettings: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    let computerUsers = try await ComputerUser.query()
      .where(.childId == person.id)
      .all(in: context.db)
    let versions = try await computerUsers.concurrentMap {
      try await $0.computer(in: context.db).filterVersion ?? .zero
    }
    async let assignedKeychainSettings = childKeychainSettings(
      for: person.id,
      parentId: person.parentId,
      in: context.db,
    )
    async let availableAlwaysBlockedGroups = AlwaysBlockedGroup.query()
      .orderBy(.name, .asc)
      .all(in: context.db)
      .map {
        AlwaysBlockedGroupSettings(
          id: $0.id,
          name: $0.name,
          description: $0.description,
          longDescription: $0.longDescription,
        )
      }
    async let alwaysBlockedGroupIds = ChildAlwaysBlockedGroup.query()
      .where(.childId == person.id)
      .all(in: context.db)
      .map(\.groupId)
    async let customAlwaysBlockedRules = ChildAlwaysBlockedRule.query()
      .where(.childId == person.id)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
      .map {
        CustomAlwaysBlockedRule(id: $0.id, rule: $0.rule, comment: $0.comment)
      }
    async let blockedApps = BlockedMacApp.query()
      .where(.childId == person.id)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
      .map {
        BlockedAppSettings(
          id: $0.id,
          identifier: $0.identifier,
          schedule: $0.schedule.map(KeychainSchedule.init),
        )
      }
    async let unrestrictedApps = UnrestrictedMacApp.query()
      .where(.childId == person.id)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
      .map {
        UnrestrictedAppSettings(
          id: $0.id,
          scope: $0.scope,
          schedule: $0.schedule.map(KeychainSchedule.init),
        )
      }
    let availableKeychains = try await Keychain.query()
      .where(.parentId == person.parentId .|| .isPublic == true)
      .orderBy(.name, .asc)
      .all(in: context.db)
    let availableKeychainIds = availableKeychains.map(\.id)
    let availableKeychainCounts = try await Key.query()
      .where(.keychainId |=| availableKeychainIds)
      .all(in: context.db)
      .reduce(into: [Keychain.Id: Int]()) { counts, key in
        counts[key.keychainId, default: 0] += 1
      }
    let availableKeychainSettings = availableKeychains.map {
      GetPersonMacSettings.KeychainSettings(
        from: $0,
        isOwn: $0.parentId == person.parentId,
        numKeys: availableKeychainCounts[$0.id] ?? 0,
      )
    }
    let (assignedKeychains, publicUnrestrictedApps) = try await assignedKeychainSettings
    return try await .init(
      keyloggingEnabled: person.keyloggingEnabled,
      showSuspensionActivity: person.showSuspensionActivity,
      screenshots: .init(
        enabled: person.screenshotsEnabled,
        resolution: person.screenshotsResolution,
        frequency: person.screenshotsFrequency,
        canBeDisabled: !person.filteringDisabled,
      ),
      internetFiltering: .init(
        enabled: !person.filteringDisabled,
        canBeDisabled: !versions.isEmpty
          && versions.allSatisfy { $0 >= .init("2.9.0")! },
        downtime: person.downtime,
        keychains: assignedKeychains,
        availableKeychains: availableKeychainSettings,
        supportsAlwaysBlocked: !versions.isEmpty
          && versions.allSatisfy { $0 >= .init("2.9.1")! },
        availableAlwaysBlockedGroups: availableAlwaysBlockedGroups,
        alwaysBlockedGroupIds: alwaysBlockedGroupIds,
        customAlwaysBlockedRules: customAlwaysBlockedRules,
      ),
      apps: .init(
        blocked: blockedApps,
        unrestricted: unrestrictedApps,
        publicUnrestricted: publicUnrestrictedApps,
      ),
      hasMacDevices: !computerUsers.isEmpty,
    )
  }
}

private func childKeychainSettings(
  for personId: Child.Id,
  parentId: Parent.Id,
  in db: any DuetSQL.Client,
) async throws -> (
  keychains: [GetPersonMacSettings.KeychainSettings],
  publicUnrestrictedApps: [GetPersonMacSettings.PublicUnrestrictedAppSettings],
) {
  let assignments = try await ChildKeychain.query()
    .where(.childId == personId)
    .all(in: db)
  guard !assignments.isEmpty else { return ([], []) }
  let keychains = try await Keychain.query()
    .where(.id |=| assignments.map(\.keychainId))
    .all(in: db)
  let keys = try await Key.query()
    .where(.keychainId |=| keychains.map(\.id))
    .all(in: db)
  let countsByKeychain = keys.reduce(into: [Keychain.Id: Int]()) { counts, key in
    counts[key.keychainId, default: 0] += 1
  }
  let settings = keychains.map { keychain in
    let schedule = assignments.first { $0.keychainId == keychain.id }?.schedule
    return GetPersonMacSettings.KeychainSettings(
      from: keychain,
      isOwn: keychain.parentId == parentId,
      numKeys: countsByKeychain[keychain.id] ?? 0,
      schedule: schedule.map(GetPersonMacSettings.KeychainSchedule.init),
    )
  }
  let publicUnrestrictedApps = keychains.filter(\.isPublic).flatMap { keychain in
    let schedule = assignments.first { $0.keychainId == keychain.id }?.schedule
    return keys
      .filter { $0.keychainId == keychain.id }
      .compactMap { key -> GetPersonMacSettings.PublicUnrestrictedAppSettings? in
        guard case .skeleton(let scope) = key.key else { return nil }
        return GetPersonMacSettings.PublicUnrestrictedAppSettings(
          keychainId: keychain.id,
          keychainName: keychain.name,
          scope: scope,
          schedule: schedule.map(GetPersonMacSettings.KeychainSchedule.init),
        )
      }
  }
  return (settings, publicUnrestrictedApps)
}

extension GetPersonMacSettings.KeychainSettings {
  init(
    from keychain: Keychain,
    isOwn: Bool,
    numKeys: Int,
    schedule: GetPersonMacSettings.KeychainSchedule? = nil,
  ) {
    self.init(
      id: keychain.id,
      name: keychain.name,
      description: keychain.description,
      warning: keychain.warning,
      isPublic: keychain.isPublic,
      isOwn: isOwn,
      numKeys: numKeys,
      schedule: schedule,
    )
  }
}
