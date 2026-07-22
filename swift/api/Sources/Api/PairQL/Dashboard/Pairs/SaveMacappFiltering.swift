import DuetSQL
import Gertie
import PairQL

struct SaveMacappFiltering: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var id: Child.Id
    var filteringDisabled: Bool
    var downtime: PlainTimeWindow?
    var keychains: [PersonKeychain]
    var alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id]
    var customAlwaysBlockedRules: [ChildCustomBlockRule]

    struct PersonKeychain: PairNestable {
      var id: Keychain.Id
      var schedule: RuleSchedule?
    }
  }
}

extension SaveMacappFiltering: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    if let downtime = input.downtime, !downtime.isValid {
      throw context.error("a5090c44", .badRequest, "invalid downtime window: \(downtime)")
    }
    for keychain in input.keychains {
      if let window = keychain.schedule?.window, !window.isValid {
        throw context.error("58002202", .badRequest, "invalid keychain schedule window: \(window)")
      }
    }

    var child = try await context.verifiedChild(from: input.id)
    if input.filteringDisabled, !child.screenshotsEnabled {
      throw context.error(
        id: "8b3a1f54",
        type: .badRequest,
        debugMessage: "filteringDisabled=true requires screenshotsEnabled=true",
        userMessage: "Internet filtering can only be disabled if screenshots are enabled.",
        showContactSupport: false,
      )
    }
    if !child.filteringDisabled, input.filteringDisabled {
      let detail = "for child: \(child.name), internet filtering disabled"
      dashSecurityEvent(.monitoringDecreased, detail, in: context)
    }
    child.filteringDisabled = input.filteringDisabled
    child.downtime = input.downtime
    try await context.db.update(child)

    let existingKeychains = try await keychainSummaries(for: child.id, in: context.db)
      .summaries
      .map(\.saveMacappFilteringPersonKeychain)
    if !existingKeychains.elementsEqual(input.keychains) {
      dashSecurityEvent(.keychainsChanged, "child: \(child.name)", in: context)

      try await ChildKeychain.query()
        .where(.childId == child.id)
        .delete(in: context.db)

      let pivots = input.keychains.map { keychain in
        ChildKeychain(
          childId: child.id,
          keychainId: keychain.id,
          schedule: keychain.schedule,
        )
      }
      try await context.db.create(pivots)
    }

    let existingGroupIds = try await ChildAlwaysBlockedGroup.query()
      .where(.childId == child.id)
      .all(in: context.db)
      .map(\.groupId)
    if Set(existingGroupIds) != Set(input.alwaysBlockedGroupIds) {
      dashSecurityEvent(.alwaysBlockedGroupsChanged, "child: \(child.name)", in: context)
      try await ChildAlwaysBlockedGroup.query()
        .where(.childId == child.id)
        .delete(in: context.db)
      let pivots = input.alwaysBlockedGroupIds.map {
        ChildAlwaysBlockedGroup(childId: child.id, groupId: $0)
      }
      try await context.db.create(pivots)
    }

    let existingRules = try await ChildAlwaysBlockedRule.query()
      .where(.childId == child.id)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
      .map { ChildCustomBlockRule(id: $0.id, rule: $0.rule, comment: $0.comment) }
    if existingRules != input.customAlwaysBlockedRules {
      dashSecurityEvent(.alwaysBlockedRulesChanged, "child: \(child.name)", in: context)
      try await ChildAlwaysBlockedRule.query()
        .where(.childId == child.id)
        .delete(in: context.db)
      let models = input.customAlwaysBlockedRules.map {
        ChildAlwaysBlockedRule(
          id: $0.id,
          childId: child.id,
          rule: $0.rule,
          comment: $0.comment,
        )
      }
      try await context.db.create(models)
    }

    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(child.id))
    return .success
  }
}

extension UserKeychainSummary {
  var saveMacappFilteringPersonKeychain: SaveMacappFiltering.Input.PersonKeychain {
    .init(id: id, schedule: schedule)
  }
}
