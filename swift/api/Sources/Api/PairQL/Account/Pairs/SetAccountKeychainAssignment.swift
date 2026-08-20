import Dependencies
import DuetSQL
import PairQL

struct SetAccountKeychainAssignment: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let keychainId: Keychain.Id
    let personId: Child.Id
    let assigned: Bool
  }
}

extension SetAccountKeychainAssignment: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    _ = try await Keychain.query()
      .where(.id == input.keychainId)
      .where(.parentId == context.accountOwner.id)
      .first(in: context.db)
    let assignment = ChildKeychain.query()
      .where(.keychainId == input.keychainId)
      .where(.childId == person.id)
    let isAssigned = try await assignment.exists(in: context.db)
    guard isAssigned != input.assigned else { return .success }

    if input.assigned {
      try await context.db.create(ChildKeychain(
        childId: person.id,
        keychainId: input.keychainId,
      ))
    } else {
      try await assignment.delete(in: context.db)
    }

    dashSecurityEvent(
      .keychainsChanged,
      "child: \(person.name)",
      in: context.legacyContext,
    )
    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(person.id))
    return .success
  }
}
