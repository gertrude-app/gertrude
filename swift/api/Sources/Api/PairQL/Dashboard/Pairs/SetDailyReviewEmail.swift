import DuetSQL
import PairQL

struct SetDailyReviewEmail: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var enabled: Bool
  }
}

// resolver

extension SetDailyReviewEmail: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    guard context.parent.dailyReviewEmail != input.enabled else {
      return .success
    }
    var parent = context.parent
    parent.dailyReviewEmail = input.enabled
    try await context.db.update(parent)
    return .success
  }
}
