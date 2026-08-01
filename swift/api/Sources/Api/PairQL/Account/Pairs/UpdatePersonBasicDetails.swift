import Dependencies
import PairQL

struct UpdatePersonBasicDetails: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
    let name: String
    let relationship: Child.Relationship
  }
}

extension UpdatePersonBasicDetails: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let name = try context.validatedPersonName(input.name)
    var person = try await context.person(input.personId)
    try await context.validatePersonRelationship(input.relationship, excluding: person.id)
    let nameChanged = person.name != name
    guard nameChanged || person.relationship != input.relationship else { return .success }

    person.name = name
    person.relationship = input.relationship
    try await context.db.update(person)
    if nameChanged {
      try await with(dependency: \.websockets)
        .send(.userUpdated, to: .user(person.id))
    }
    return .success
  }
}
