import Dependencies
import Gertie
import MacAppRoute

extension DisableFilterForChild: NoInputResolver {
  static func resolve(in context: MacApp.ChildContext) async throws -> Output {
    try await context.verifyOnboardingToken("DisableFilterForChild", "61031fd2")

    var child = context.child
    child.filteringDisabled = true
    child.screenshotsEnabled = true
    try await context.db.update(child)

    let parent = try await child.parent(in: context.db)
    let computerUser = try await context.computerUser()
    await get(dependency: \.slack).internal(
      .info,
      "Child *\(child.name)* (\(parent.adminSiteLink(.slack))) filter disabled during onboarding",
    )

    let task = Task {
      try await context.db.create(InterestingEvent(
        eventId: "7bb32aa0",
        kind: "event",
        context: "macapp",
        computerUserId: computerUser.id,
        parentId: parent.id,
        detail: "filtering disabled during onboarding",
      ))

      try await context.db.create(Api.SecurityEvent(
        parentId: parent.id,
        computerUserId: computerUser.id,
        event: Gertie.SecurityEvent.MacApp.filteringDisabledDuringOnboarding.rawValue,
      ))

      await with(dependency: \.adminNotifier).notify(
        parent.id,
        .securityEvent(.init(
          source: .macApp(childName: child.name, event: .filteringDisabledDuringOnboarding),
          detail: nil,
        )),
      )
    }

    if context.env.mode == .test {
      _ = try await task.value
    }

    return .success
  }
}
