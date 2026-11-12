import DuetSQL
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

    if input.eventId == referralSurveyEventId {
      try await recordReferralSurveyAnswer(
        input.detail,
        parent: context.parent,
        context: "dash",
        in: context.db,
      )
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
    let msg = "Dash interesting event: \(input.eventId)  \(input.detail)"
    await get(dependency: \.slack).internal(.info, msg)

    return .success
  }
}

// helpers

let referralSurveyEventId = "e7b3a1c9"

func recordReferralSurveyAnswer(
  _ detail: String,
  parent: Parent,
  context eventContext: String,
  in db: any DuetSQL.Client,
) async throws {
  try await db.create(InterestingEvent(
    eventId: referralSurveyEventId,
    kind: "event",
    context: eventContext,
    computerUserId: nil,
    parentId: parent.id,
    detail: detail,
  ))
  await get(dependency: \.slack).internal(.signups, """
    *How did you hear about us?*
    parent: `\(parent.email)`
    \(detail)
  """)
}
