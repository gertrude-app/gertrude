import PairQL

struct GetPeople: Pair {
  static let auth: ClientAuth = .parent

  struct Person: PairOutput, PairNestable {
    let id: Child.Id
    let name: String
  }

  typealias Output = [Person]
}

// resolver

extension GetPeople: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    return people.map { Person(id: $0.id, name: $0.name) }
  }
}
