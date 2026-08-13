import Gertie
import PairQL

struct UpdatePersonMacApps: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    struct BlockedApp: PairNestable {
      let id: BlockedMacApp.Id
      let identifier: String
      let schedule: GetPersonMacSettings.KeychainSchedule?
    }

    struct UnrestrictedApp: PairNestable {
      let id: UnrestrictedMacApp.Id
      let scope: AppScope.Single
      let schedule: GetPersonMacSettings.KeychainSchedule?
    }

    let personId: Child.Id
    let blockedApps: [BlockedApp]
    let unrestrictedApps: [UnrestrictedApp]
  }
}

extension UpdatePersonMacApps: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    return try await SaveMacappApps.resolve(
      with: .init(
        id: person.id,
        blockedApps: input.blockedApps.map {
          .init(id: $0.id, identifier: $0.identifier, schedule: $0.schedule?.ruleSchedule)
        },
        unrestrictedApps: input.unrestrictedApps.map {
          .init(id: $0.id, scope: $0.scope, schedule: $0.schedule?.ruleSchedule)
        },
      ),
      in: context.legacyContext,
    )
  }
}
