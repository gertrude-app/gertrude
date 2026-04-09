import Dependencies
import Gertie
import MacAppRoute

extension SetDowntimeSchedule: Resolver {
  static func resolve(
    with input: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    try await context.verifyOnboardingToken("SetDowntimeSchedule", "1eda41cd")

    guard input.isValid else {
      throw context.error(
        "3e8d2102",
        .badRequest,
        "invalid downtime window: \(input)",
      )
    }

    var child = context.child
    child.downtime = input
    try await context.db.update(child)

    let task = Task {
      let parent = try await child.parent(in: context.db)
      let computerUser = try await context.computerUser()
      try await context.db.create(InterestingEvent(
        eventId: "cf582b72",
        kind: "event",
        context: "macapp",
        computerUserId: computerUser.id,
        parentId: parent.id,
        detail: "downtime set during onboarding: \(input.start.hour):\(String(format: "%02d", input.start.minute))-\(input.end.hour):\(String(format: "%02d", input.end.minute))",
      ))
    }

    if context.env.mode == .test {
      _ = try await task.value
    }

    return .success
  }
}
