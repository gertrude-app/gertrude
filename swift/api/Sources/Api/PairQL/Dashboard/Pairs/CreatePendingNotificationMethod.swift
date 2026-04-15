import Dependencies
import Foundation
import PairQL
import Vapor

struct CreatePendingNotificationMethod: Pair {
  static let auth: ClientAuth = .parent

  typealias Input = Parent.NotificationMethod.Config

  struct Output: PairOutput {
    let methodId: Parent.NotificationMethod.Id
    let ntfyTopic: String?

    init(methodId: Parent.NotificationMethod.Id, ntfyTopic: String? = nil) {
      self.methodId = methodId
      self.ntfyTopic = ntfyTopic
    }
  }
}

// extensions

extension Parent.NotificationMethod.Config: PairInput {}

extension CreatePendingNotificationMethod: Resolver {
  static func resolve(with config: Input, in context: ParentContext) async throws -> Output {
    if case .ntfy = config {
      let topic = NtfyClient.generateTopic()
      let model = Parent.NotificationMethod(
        parentId: context.parent.id,
        config: .ntfy(topic: topic),
      )
      await with(dependency: \.ephemeral).storePendingNtfyMethod(model)
      try await with(dependency: \.ntfy).send(
        topic,
        "Gertrude",
        "This ntfy topic is now connected to Gertrude notifications.",
        nil,
      )
      return .init(methodId: model.id, ntfyTopic: topic)
    }

    let model = Parent.NotificationMethod(parentId: context.parent.id, config: config)
    let code = await with(dependency: \.ephemeral)
      .createPendingNotificationMethod(model)
    try await sendVerification(code, for: config, in: context)
    return .init(methodId: model.id)
  }
}

// helpers

private func sendVerification(
  _ code: Int,
  for method: Parent.NotificationMethod.Config,
  in context: ParentContext,
) async throws {
  switch method {
  case .slack(channelId: let channel, channelName: _, token: let token):
    do {
      try await with(dependency: \.slack).send(Slack(
        text: "Your verification code is `\(code)`",
        channel: channel,
        token: token,
      ))
    } catch {
      throw context.error(
        id: "df619205",
        type: .unauthorized,
        debugMessage: "failed to send Slack verification code: \(error) ",
        dashboardTag: .slackVerificationFailed,
      )
    }

  case .email(email: let email):
    _ = try await with(dependency: \.postmark)
      .send(template: .verifyNotificationEmail(to: email, model: .init(code: code)))

  case .text(phoneNumber: let phoneNumber):
    do {
      let result = try await with(dependency: \.twilio).send(Text(
        to: .init(rawValue: phoneNumber),
        message: "Your verification code is \(code)",
      ))
      SmsSend.createDetached(
        parentId: context.parent.id,
        trigger: "verification",
        phoneNumber: phoneNumber,
        twilioResult: result,
      )
    } catch {
      let parentLink = AdminLink().slack(
        to: .parent(context.parent.id),
        text: context.parent.email.rawValue,
      )
      await with(dependency: \.slack)
        .error("Failed to send SMS verification to \(phoneNumber) (\(parentLink)): \(error)")
      throw error
    }

  case .ntfy:
    break
  }
}
