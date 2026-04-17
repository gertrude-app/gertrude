import Dependencies
import DuetSQL
import MacAppRoute

extension SelectAlwaysBlockedGroups: Resolver {
  static func resolve(
    with input: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    try await context.verifyOnboardingToken("SelectAlwaysBlockedGroups", "0e5d0d99")

    let groupIds = input.map { AlwaysBlockedGroup.Id($0) }

    try await ChildAlwaysBlockedGroup.query()
      .where(.childId == context.child.id)
      .delete(in: context.db)

    for groupId in groupIds {
      try await context.db.create(ChildAlwaysBlockedGroup(
        childId: context.child.id,
        groupId: groupId,
      ))
    }

    @Dependency(\.websockets) var websockets
    try await websockets.send(.userUpdated, to: .user(context.child.id))

    let task = Task {
      let parent = try await context.child.parent(in: context.db)
      let computerUser = try await context.computerUser()
      let idList = groupIds.map(\.lowercased).joined(separator: ", ")
      await get(dependency: \.slack).internal(
        .info,
        "(\(parent.adminSiteLink(.slack))) selected always-blocked groups during onboarding: \(groupIds.count) group(s)",
      )
      try await context.db.create(InterestingEvent(
        eventId: "a582a19f",
        kind: "event",
        context: "macapp",
        computerUserId: computerUser.id,
        parentId: parent.id,
        detail: "selected \(groupIds.count) always-blocked group(s) during onboarding: \(idList)",
      ))
    }

    if context.env.mode == .test {
      _ = try await task.value
    }

    return .success
  }
}
