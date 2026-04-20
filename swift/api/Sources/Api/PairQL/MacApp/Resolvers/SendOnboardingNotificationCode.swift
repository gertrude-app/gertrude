import Dependencies
import MacAppRoute
import Vapor

extension SendOnboardingNotificationCode: Resolver {
  static func resolve(
    with input: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    try await context.verifyOnboardingToken("SendOnboardingNotificationCode", "26d28e89")

    let parent = try await context.child.parent(in: context.db)
    let model = Parent.NotificationMethod(
      parentId: parent.id,
      config: .text(phoneNumber: input.phoneNumber),
    )

    let code = await with(dependency: \.ephemeral)
      .createPendingNotificationMethod(model)

    do {
      let result = try await with(dependency: \.twilio).send(Text(
        to: .init(rawValue: input.phoneNumber),
        message: "Your verification code is \(code)",
      ))
      SmsSend.createDetached(
        parentId: parent.id,
        trigger: "verification",
        phoneNumber: input.phoneNumber,
        twilioResult: result,
      )
    } catch {
      let parentLink = AdminLink().slack(
        to: .parent(parent.id),
        text: parent.email.rawValue,
      )
      slackErr("sms verify send error: \(input.phoneNumber) (\(parentLink)): \(error)")
      throw error
    }

    return .init(methodId: model.id.rawValue)
  }
}
