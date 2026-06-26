import PairQL

struct GetActivitySummaries: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let timeZone: String
  }

  typealias Output = [GetPersonActivitySummaries.Day]
}

// resolver

extension GetActivitySummaries: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let days = try await FamilyActivitySummaries.resolve(
      with: .init(timeZone: input.timeZone),
      in: context.legacyContext,
    )
    return days.map { day in
      GetPersonActivitySummaries.Day(
        date: day.date,
        numTotal: day.numTotal,
        numDeleted: day.numApproved,
        numFlagged: day.numFlagged,
      )
    }
  }
}
