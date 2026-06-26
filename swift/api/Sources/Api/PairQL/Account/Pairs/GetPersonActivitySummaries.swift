import Foundation
import PairQL

struct GetPersonActivitySummaries: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
    let timeZone: String
  }

  struct Output: PairOutput {
    let personName: String
    let days: [Day]
  }

  struct Day: PairOutput, PairNestable {
    let date: Date
    let numTotal: Int
    let numDeleted: Int
    let numFlagged: Int
  }
}

// resolver

extension GetPersonActivitySummaries: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    let summaries = try await ChildActivitySummaries.resolve(
      with: .init(childId: input.personId, timeZone: input.timeZone),
      in: context.legacyContext,
    )
    return Output(
      personName: summaries.childName,
      days: summaries.days.map { day in
        Day(
          date: day.date,
          numTotal: day.numTotal,
          numDeleted: day.numApproved,
          numFlagged: day.numFlagged,
        )
      },
    )
  }
}
