import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct UpdatePersonMacInternetFiltering: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    struct Keychain: PairNestable {
      let id: Api.Keychain.Id
      let schedule: GetPersonMacSettings.KeychainSchedule?
    }

    let personId: Child.Id
    let filteringEnabled: Bool
    let keychains: [Keychain]
    let alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id]
    let customAlwaysBlockedDomains: [String]
  }
}

extension UpdatePersonMacInternetFiltering: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    var person = try await context.person(input.personId)
    let filteringDisabled = !input.filteringEnabled
    let existingKeychains = try await ChildKeychain.query()
      .where(.childId == person.id)
      .all(in: context.db)
    let keychainsChanged = Set(existingKeychains.map(\.keychainId)) !=
      Set(input.keychains.map(\.id))
      || existingKeychains.contains { existing in
        existing.schedule != input.keychains.first { $0.id == existing.keychainId }?.schedule?
          .ruleSchedule
      }
    let existingAlwaysBlockedGroupIds = try await ChildAlwaysBlockedGroup.query()
      .where(.childId == person.id)
      .all(in: context.db)
      .map(\.groupId)
    let alwaysBlockedGroupsChanged = Set(existingAlwaysBlockedGroupIds) !=
      Set(input.alwaysBlockedGroupIds)
    let existingAlwaysBlockedRules = try await ChildAlwaysBlockedRule.query()
      .where(.childId == person.id)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
    let existingCustomDomains = customAlwaysBlockedDomains(
      from: existingAlwaysBlockedRules,
    )
    let customAlwaysBlockedDomainsChanged = existingCustomDomains !=
      input.customAlwaysBlockedDomains
    guard person.filteringDisabled != filteringDisabled
      || keychainsChanged
      || alwaysBlockedGroupsChanged
      || customAlwaysBlockedDomainsChanged
    else {
      return .success
    }
    if filteringDisabled, !person.filteringDisabled {
      guard person.screenshotsEnabled else {
        throw context.error(
          id: "edbdf004",
          type: .badRequest,
          debugMessage: "filteringDisabled=true requires screenshotsEnabled=true",
          userMessage: "Internet filtering can only be disabled while screenshots are enabled.",
          showContactSupport: false,
        )
      }
      let computers = try await ComputerUser.query()
        .where(.childId == person.id)
        .all(in: context.db)
      let versions = try await computers.concurrentMap {
        try await $0.computer(in: context.db).filterVersion ?? .zero
      }
      guard !versions.isEmpty, versions.allSatisfy({ $0 >= .init("2.9.0")! }) else {
        throw context.error(
          id: "c089f32c",
          type: .badRequest,
          debugMessage: "all connected Mac filter versions must be at least 2.9.0",
          userMessage: "Update every connected Mac before disabling internet filtering.",
          showContactSupport: false,
        )
      }
    }

    guard Set(input.keychains.map(\.id)).count == input.keychains.count else {
      throw context.error(
        id: "1ca1fd4c",
        type: .badRequest,
        debugMessage: "keychain IDs must be unique",
        userMessage: "Each keychain can only be selected once.",
        showContactSupport: false,
      )
    }
    for keychain in input.keychains {
      if let window = keychain.schedule?.ruleSchedule.window, !window.isValid {
        throw context.error(
          id: "34d9a40e",
          type: .badRequest,
          debugMessage: "invalid keychain schedule window: \(window)",
          userMessage: "Keychain schedules need a valid time range.",
          showContactSupport: false,
        )
      }
    }
    guard Set(input.customAlwaysBlockedDomains).count == input.customAlwaysBlockedDomains.count,
          input.customAlwaysBlockedDomains.allSatisfy({
            !$0.isEmpty
              && $0 == $0.lowercased()
              && $0 == $0.trimmingCharacters(in: .whitespacesAndNewlines)
          })
    else {
      throw context.error(
        id: "d62d1ff8",
        type: .badRequest,
        debugMessage: "custom always-blocked domains must be unique, nonempty, and lowercase",
        userMessage: "Always-blocked domains must be unique and valid.",
        showContactSupport: false,
      )
    }
    guard Set(input.alwaysBlockedGroupIds).count == input.alwaysBlockedGroupIds.count else {
      throw context.error(
        id: "eff6b6dd",
        type: .badRequest,
        debugMessage: "always-blocked group IDs must be unique",
        userMessage: "Each always-blocked group can only be selected once.",
        showContactSupport: false,
      )
    }
    let selectableAlwaysBlockedGroups = try await AlwaysBlockedGroup.query()
      .where(.id |=| input.alwaysBlockedGroupIds)
      .all(in: context.db)
    guard selectableAlwaysBlockedGroups.count == input.alwaysBlockedGroupIds.count else {
      throw context.error(
        id: "ac7d6588",
        type: .badRequest,
        debugMessage: "always-blocked group IDs must be available",
        userMessage: "One or more always-blocked groups are unavailable.",
        showContactSupport: false,
      )
    }
    let selectableKeychains = try await Keychain.query()
      .where(.id |=| input.keychains.map(\.id))
      .where(.parentId == person.parentId .|| .isPublic == true)
      .all(in: context.db)
    guard selectableKeychains.count == input.keychains.count else {
      throw context.error(
        id: "9e7c04a1",
        type: .badRequest,
        debugMessage: "keychainIds must belong to the parent or be public",
        userMessage: "One or more selected keychains are unavailable.",
        showContactSupport: false,
      )
    }

    person.filteringDisabled = filteringDisabled
    if filteringDisabled {
      dashSecurityEvent(
        .monitoringDecreased,
        "for child: \(person.name), internet filtering disabled",
        in: context.legacyContext,
      )
    }
    if keychainsChanged {
      dashSecurityEvent(
        .keychainsChanged,
        "child: \(person.name)",
        in: context.legacyContext,
      )
      try await ChildKeychain.query()
        .where(.childId == person.id)
        .delete(in: context.db)
      try await context.db.create(input.keychains.map {
        ChildKeychain(
          childId: person.id,
          keychainId: $0.id,
          schedule: $0.schedule?.ruleSchedule,
        )
      })
    }
    if alwaysBlockedGroupsChanged {
      dashSecurityEvent(
        .alwaysBlockedGroupsChanged,
        "child: \(person.name)",
        in: context.legacyContext,
      )
      try await ChildAlwaysBlockedGroup.query()
        .where(.childId == person.id)
        .delete(in: context.db)
      try await context.db.create(input.alwaysBlockedGroupIds.map {
        ChildAlwaysBlockedGroup(childId: person.id, groupId: $0)
      })
    }
    if customAlwaysBlockedDomainsChanged {
      dashSecurityEvent(
        .alwaysBlockedRulesChanged,
        "child: \(person.name)",
        in: context.legacyContext,
      )
      let domainRuleIds = existingAlwaysBlockedRules.compactMap {
        model -> ChildAlwaysBlockedRule.Id? in
        guard case .hostnameOrSubdomain = model.rule else { return nil }
        return model.id
      }
      if !domainRuleIds.isEmpty {
        try await ChildAlwaysBlockedRule.query()
          .where(.id |=| domainRuleIds)
          .delete(in: context.db)
      }
      try await context.db.create(input.customAlwaysBlockedDomains.map {
        ChildAlwaysBlockedRule(
          childId: person.id,
          rule: .hostnameOrSubdomain(value: $0),
        )
      })
    }
    try await context.db.update(person)
    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(person.id))
    return .success
  }
}
