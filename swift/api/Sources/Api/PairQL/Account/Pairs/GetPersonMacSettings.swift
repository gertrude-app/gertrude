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
    let keychains: [KeychainSettings]
    let availableKeychains: [KeychainSettings]
    let supportsAlwaysBlocked: Bool
    let availableAlwaysBlockedGroups: [AlwaysBlockedGroupSettings]
    let alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id]
    let customAlwaysBlockedRules: [CustomAlwaysBlockedRule]
  }

  struct Output: PairOutput {
    let keyloggingEnabled: Bool
    let showSuspensionActivity: Bool
    let screenshots: ScreenshotSettings
    let internetFiltering: InternetFilteringSettings
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
    async let assignedKeychains = childKeychainSettings(
      for: person.id,
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
    let availableKeychains = try await Keychain.query()
      .where(.parentId == person.parentId .|| .isPublic == true)
      .all(in: context.db)
      .concurrentMap {
        try await GetPersonMacSettings.KeychainSettings(from: $0, in: context.db)
      }
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
        keychains: assignedKeychains,
        availableKeychains: availableKeychains,
        supportsAlwaysBlocked: !versions.isEmpty
          && versions.allSatisfy { $0 >= .init("2.9.1")! },
        availableAlwaysBlockedGroups: availableAlwaysBlockedGroups,
        alwaysBlockedGroupIds: alwaysBlockedGroupIds,
        customAlwaysBlockedRules: customAlwaysBlockedRules,
      ),
      hasMacDevices: !computerUsers.isEmpty,
    )
  }
}

private func childKeychainSettings(
  for personId: Child.Id,
  in db: any DuetSQL.Client,
) async throws -> [GetPersonMacSettings.KeychainSettings] {
  let assignments = try await ChildKeychain.query()
    .where(.childId == personId)
    .all(in: db)
  guard !assignments.isEmpty else { return [] }
  return try await Keychain.query()
    .where(.id |=| assignments.map(\.keychainId))
    .all(in: db)
    .concurrentMap { keychain in
      let schedule = assignments.first { $0.keychainId == keychain.id }?.schedule
      return try await GetPersonMacSettings.KeychainSettings(
        from: keychain,
        schedule: schedule.map(GetPersonMacSettings.KeychainSchedule.init),
        in: db,
      )
    }
}

extension GetPersonMacSettings.KeychainSettings {
  init(
    from keychain: Keychain,
    schedule: GetPersonMacSettings.KeychainSchedule? = nil,
    in db: any DuetSQL.Client,
  ) async throws {
    let numKeys = try await db.count(Key.self, where: .keychainId == keychain.id)
    self.init(
      id: keychain.id,
      name: keychain.name,
      description: keychain.description,
      warning: keychain.warning,
      isPublic: keychain.isPublic,
      numKeys: numKeys,
      schedule: schedule,
    )
  }
}
