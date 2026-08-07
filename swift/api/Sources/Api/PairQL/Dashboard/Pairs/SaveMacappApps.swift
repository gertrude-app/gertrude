import DuetSQL
import Gertie
import PairQL

struct SaveMacappApps: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var id: Child.Id
    var blockedApps: [BlockedMacApp.DTO]
    var unrestrictedApps: [UnrestrictedMacApp.DTO]
  }
}

extension SaveMacappApps: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChild(from: input.id)

    let existingBlocked = try await child.blockedMacApps(in: context.db).map(\.dto)
    if !existingBlocked.elementsEqual(input.blockedApps) {
      dashSecurityEvent(.blockedAppsChanged, "child: \(child.name)", in: context)
      try await BlockedMacApp.query()
        .where(.childId == child.id)
        .delete(in: context.db)
      let models = input.blockedApps.map { BlockedMacApp(dto: $0, childId: child.id) }
      try await context.db.create(models)
    }

    let existingUnrestricted = try await child.unrestrictedMacApps(in: context.db).map(\.dto)
    if !existingUnrestricted.elementsEqual(input.unrestrictedApps) {
      dashSecurityEvent(.unrestrictedAppsChanged, "child: \(child.name)", in: context)
      try await UnrestrictedMacApp.query()
        .where(.childId == child.id)
        .delete(in: context.db)
      let models = input.unrestrictedApps.map { UnrestrictedMacApp(dto: $0, childId: child.id) }
      try await context.db.create(models)
    }

    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(child.id))
    return .success
  }
}
