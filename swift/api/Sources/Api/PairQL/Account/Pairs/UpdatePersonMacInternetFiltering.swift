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
    let downtime: PlainTimeWindow?
    let keychains: [Keychain]
    let alwaysBlockedGroupIds: [AlwaysBlockedGroup.Id]
    let customAlwaysBlockedRules: [GetPersonMacSettings.CustomAlwaysBlockedRule]
  }
}

extension UpdatePersonMacInternetFiltering: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    return try await SaveMacappFiltering.resolve(
      with: .init(
        id: person.id,
        filteringDisabled: !input.filteringEnabled,
        downtime: input.downtime,
        keychains: input.keychains.map {
          .init(id: $0.id, schedule: $0.schedule?.ruleSchedule)
        },
        alwaysBlockedGroupIds: input.alwaysBlockedGroupIds,
        customAlwaysBlockedRules: input.customAlwaysBlockedRules.map {
          .init(id: $0.id, rule: $0.rule, comment: $0.comment)
        },
      ),
      in: context.legacyContext,
    )
  }
}
