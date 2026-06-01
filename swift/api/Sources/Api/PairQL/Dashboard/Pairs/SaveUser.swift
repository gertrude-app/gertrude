import DuetSQL
import Gertie
import PairQL

struct SaveUser: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var id: Child.Id
    var isNew: Bool
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var showSuspensionActivity: Bool
    var filteringDisabled: Bool?
    var downtime: PlainTimeWindow?
    var keychains: [ChildKeychain]
    var blockedApps: [UserBlockedApp.DTO]?
    var alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id]?
    var customAlwaysBlockedRules: [ChildCustomBlockRule]?

    struct ChildKeychain: PairNestable {
      var id: Keychain.Id
      var schedule: RuleSchedule?
    }
  }
}

// resolver

extension SaveUser: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    if let downtime = input.downtime, !downtime.isValid {
      throw context.error("a5090c44", .badRequest, "invalid downtime window: \(downtime)")
    }
    for keychain in input.keychains {
      if let window = keychain.schedule?.window, !window.isValid {
        throw context.error("58002202", .badRequest, "invalid keychain schedule window: \(window)")
      }
    }
    let filteringDisabled = input.filteringDisabled ?? false
    if filteringDisabled, !input.screenshotsEnabled {
      throw context.error(
        id: "c3578cf8",
        type: .badRequest,
        debugMessage: "filteringDisabled=true requires screenshotsEnabled=true",
        userMessage: "Internet filtering can only be disabled if screenshots are enabled.",
        showContactSupport: false,
      )
    }
    var user: Child
    if input.isNew {
      user = try await context.db.create(Child(
        id: input.id,
        parentId: context.parent.id,
        name: input.name,
        filteringDisabled: filteringDisabled,
        downtime: input.downtime,
      ))
      dashSecurityEvent(.childAdded, "name: \(user.name)", in: context)
    } else {
      user = try await context.db.find(input.id)
      if let details = monitoringDecreased(user: user, input: input) {
        let detail = "for child: \(user.name), \(details)"
        dashSecurityEvent(.monitoringDecreased, detail, in: context)
      }
      user.name = input.name
      user.keyloggingEnabled = input.keyloggingEnabled
      user.screenshotsEnabled = input.screenshotsEnabled
      user.screenshotsResolution = input.screenshotsResolution
      user.screenshotsFrequency = max(10, input.screenshotsFrequency)
      user.showSuspensionActivity = input.showSuspensionActivity
      user.filteringDisabled = filteringDisabled
      user.downtime = input.downtime
      try await context.db.update(user)

      if let blockedApps = input.blockedApps {
        let existing = try await user.blockedApps(in: context.db).map(\.dto)
        if !existing.elementsEqual(blockedApps) {
          dashSecurityEvent(.blockedAppsChanged, "child: \(user.name)", in: context)
          try await UserBlockedApp.query()
            .where(.childId == user.id)
            .delete(in: context.db)
          let models = blockedApps.map { UserBlockedApp(dto: $0, childId: user.id) }
          try await context.db.create(models)
        }
      }

      let existing = try await childKeychainSummaries(for: user.id, in: context.db)
        .map(\.userKeychain)
      if !existing.elementsEqual(input.keychains) {
        dashSecurityEvent(.keychainsChanged, "child: \(user.name)", in: context)

        try await ChildKeychain.query()
          .where(.childId == user.id)
          .delete(in: context.db)

        let pivots = input.keychains.map { keychain in
          ChildKeychain(
            childId: user.id,
            keychainId: keychain.id,
            schedule: keychain.schedule,
          )
        }

        try await context.db.create(pivots)
      }

      if let groupIds = input.alwaysBlockedGroupIds {
        let existing = try await ChildAlwaysBlockedGroup.query()
          .where(.childId == user.id)
          .all(in: context.db)
          .map(\.groupId)
        if Set(existing) != Set(groupIds) {
          dashSecurityEvent(
            .alwaysBlockedGroupsChanged,
            "child: \(user.name)",
            in: context,
          )
          try await ChildAlwaysBlockedGroup.query()
            .where(.childId == user.id)
            .delete(in: context.db)
          let pivots = groupIds.map {
            ChildAlwaysBlockedGroup(childId: user.id, groupId: $0)
          }
          try await context.db.create(pivots)
        }
      }

      if let customRules = input.customAlwaysBlockedRules {
        let existing = try await ChildAlwaysBlockedRule.query()
          .where(.childId == user.id)
          .orderBy(.createdAt, .asc)
          .all(in: context.db)
          .map { ChildCustomBlockRule(id: $0.id, rule: $0.rule, comment: $0.comment) }
        if existing != customRules {
          dashSecurityEvent(
            .alwaysBlockedRulesChanged,
            "child: \(user.name)",
            in: context,
          )
          try await ChildAlwaysBlockedRule.query()
            .where(.childId == user.id)
            .delete(in: context.db)
          let models = customRules.map {
            ChildAlwaysBlockedRule(
              id: $0.id,
              childId: user.id,
              rule: $0.rule,
              comment: $0.comment,
            )
          }
          try await context.db.create(models)
        }
      }
    }

    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(user.id))
    return .success
  }
}

// helpers

func monitoringDecreased(user: Child, input: SaveUser.Input) -> String? {
  var parts: [String] = []
  if user.keyloggingEnabled, !input.keyloggingEnabled {
    parts.append("keylogging disabled")
  }
  if user.screenshotsEnabled, !input.screenshotsEnabled {
    parts.append("screenshots disabled")
  }
  if !user.filteringDisabled, input.filteringDisabled == true {
    parts.append("internet filtering disabled")
  }
  if user.screenshotsResolution > input.screenshotsResolution {
    parts.append("screenshots resolution decreased")
  }
  if user.screenshotsFrequency < input.screenshotsFrequency {
    parts.append("screenshots frequency decreased")
  }
  if user.showSuspensionActivity, !input.showSuspensionActivity {
    parts.append("suspension activity visibility disabled")
  }
  return parts.isEmpty ? nil : parts.joined(separator: ", ")
}

extension UserKeychainSummary {
  var userKeychain: SaveUser.Input.ChildKeychain {
    .init(id: id, schedule: schedule)
  }
}
