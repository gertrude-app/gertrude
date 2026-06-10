import PairQL
import Vapor

struct LogEvent: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var eventId: String
    var detail: String
  }
}

// resolver

extension LogEvent: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    if isTestAddress(context.parent.email.rawValue) {
      return .success
    }
    try await context.db.create(InterestingEvent(
      eventId: input.eventId,
      kind: "event",
      context: "dash",
      computerUserId: nil,
      parentId: context.parent.id,
      detail: input.detail,
    ))

    let slack = get(dependency: \.slack)
    if input.eventId == "e7b3a1c9" {
      await slack.internal(.signups, """
        *How did you hear about us?*
        parent: `\(context.parent.email)`
        \(input.detail)
      """)
    } else {
      let msg = "Dash interesting event: \(input.eventId)  \(input.detail)"
      await slack.internal(.info, msg)
    }

    return .success
  }
}
