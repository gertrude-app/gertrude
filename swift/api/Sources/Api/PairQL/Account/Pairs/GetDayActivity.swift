import PairQL

struct GetDayActivity: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let range: DateRange
  }

  struct Output: PairOutput {
    let people: [PersonDay]
  }

  struct PersonDay: PairNestable {
    let personId: Child.Id
    let personName: String
    let items: [GetPersonDayActivity.Item]
  }
}

// resolver

extension GetDayActivity: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    let peopleDays = try await people.concurrentMap { person in
      let feed = try await UserActivityFeed.resolve(
        with: .init(userId: person.id, range: input.range),
        in: context.legacyContext,
      )
      return PersonDay(
        personId: person.id,
        personName: person.name,
        items: feed.items.map(GetPersonDayActivity.Item.init(from:)),
      )
    }
    return Output(people: peopleDays.filter { !$0.items.isEmpty })
  }
}
