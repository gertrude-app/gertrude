import Dependencies
import Foundation
import PairQL

struct UpdatePersonName: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
    let name: String
  }
}

extension UpdatePersonName: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let name = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !name.isEmpty else {
      throw context.error(
        id: "d13d20d5",
        type: .badRequest,
        debugMessage: "person name cannot be empty",
        userMessage: "Enter a name for this person.",
      )
    }

    var person = try await context.person(input.personId)
    guard person.name != name else { return .success }

    person.name = name
    try await context.db.update(person)
    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(person.id))
    return .success
  }
}
