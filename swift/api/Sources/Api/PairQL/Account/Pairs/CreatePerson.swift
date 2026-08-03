import PairQL

struct CreatePerson: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let name: String
    let relationship: Child.Relationship
  }

  struct Output: PairOutput {
    let personId: Child.Id
    let name: String
    let relationship: Child.Relationship
  }
}

extension CreatePerson: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let name = try context.validatedPersonName(input.name)
    try await context.validatePersonRelationship(input.relationship)
    let person = try await context.db.create(Child(
      parentId: context.accountOwner.id,
      name: name,
      relationship: input.relationship,
    ))
    dashSecurityEvent(.childAdded, "name: \(person.name)", in: context.legacyContext)
    return .init(
      personId: person.id,
      name: person.name,
      relationship: person.relationship,
    )
  }
}
