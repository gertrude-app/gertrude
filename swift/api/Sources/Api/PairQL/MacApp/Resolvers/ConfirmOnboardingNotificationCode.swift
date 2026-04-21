import Dependencies
import DuetSQL
import MacAppRoute
import Vapor

extension ConfirmOnboardingNotificationCode: Resolver {
  static func resolve(
    with input: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    try await context.verifyOnboardingToken("ConfirmOnboardingNotificationCode", "dbe2a684")

    let parent = try await context.child.parent(in: context.db)
    let methodId = Parent.NotificationMethod.Id(input.methodId)

    let pending = await with(dependency: \.ephemeral)
      .confirmPendingNotificationMethod(methodId, input.code)
    guard let pending else {
      throw context.error(
        id: "eacc7a3a",
        type: .unauthorized,
        debugMessage: "incorrect or expired confirmation code",
        appTag: .incorrectConfirmationCode,
      )
    }
    guard pending.parentId == parent.id else {
      throw Abort(.unauthorized)
    }
    try await context.db.create(pending)

    let existingNotifications = try await Parent.Notification.query()
      .where(.parentId == parent.id)
      .where(.methodId == methodId)
      .all(in: context.db)
    let alreadyWired = Set(existingNotifications.map(\.trigger))

    let triggers: [Parent.Notification.Trigger] = [
      .unlockRequestSubmitted,
      .suspendFilterRequestSubmitted,
    ]
    for trigger in triggers where !alreadyWired.contains(trigger) {
      try await context.db.create(Parent.Notification(
        parentId: parent.id,
        methodId: methodId,
        trigger: trigger,
      ))
    }

    return .success
  }
}
