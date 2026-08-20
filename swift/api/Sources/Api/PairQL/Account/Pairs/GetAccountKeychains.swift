import DuetSQL
import PairQL

struct GetAccountKeychains: Pair {
  static let auth: ClientAuth = .parent

  struct Person: PairNestable {
    let id: Child.Id
    let name: String
  }

  struct AccountKeychain: PairNestable {
    let id: Keychain.Id
    let name: String
    let description: String?
    let isPublic: Bool
    let numKeys: Int
    let assignedPersonIds: [Child.Id]
  }

  struct Output: PairOutput {
    let keychains: [AccountKeychain]
    let people: [Person]
  }
}

extension GetAccountKeychains: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let keychains = try await Keychain.query()
      .where(.parentId == context.accountOwner.id)
      .orderBy(.name, .asc)
      .all(in: context.db)
    let people = try await Child.query()
      .where(.parentId == context.accountOwner.id)
      .orderBy(.name, .asc)
      .all(in: context.db)
    let keychainIds = keychains.map(\.id)
    let personIds = Set(people.map(\.id))
    let keys = keychainIds.isEmpty
      ? []
      : try await Key.query()
      .where(.keychainId |=| keychainIds)
      .all(in: context.db)
    let assignments = keychainIds.isEmpty
      ? []
      : try await ChildKeychain.query()
      .where(.keychainId |=| keychainIds)
      .all(in: context.db)
      .filter { personIds.contains($0.childId) }
    let keyCounts = keys.reduce(into: [Keychain.Id: Int]()) { counts, key in
      counts[key.keychainId, default: 0] += 1
    }
    let assignedPersonIds = assignments.reduce(
      into: [Keychain.Id: [Child.Id]](),
    ) { personIdsByKeychain, assignment in
      personIdsByKeychain[assignment.keychainId, default: []].append(assignment.childId)
    }

    return .init(
      keychains: keychains.map { keychain in
        .init(
          id: keychain.id,
          name: keychain.name,
          description: keychain.description,
          isPublic: keychain.isPublic,
          numKeys: keyCounts[keychain.id] ?? 0,
          assignedPersonIds: assignedPersonIds[keychain.id] ?? [],
        )
      },
      people: people.map { .init(id: $0.id, name: $0.name) },
    )
  }
}
