import PairQL

struct GetAccountSettings: Pair {
  static let auth: ClientAuth = .parent

  struct Notification: PairNestable {
    let id: Parent.Notification.Id
    let trigger: Parent.Notification.Trigger
    let methodId: Parent.NotificationMethod.Id
  }

  struct NotificationMethod: PairNestable {
    let id: Parent.NotificationMethod.Id
    let config: Parent.NotificationMethod.Config
  }

  struct Output: PairOutput {
    let email: String
    let dailyReviewEmail: Bool
    let hasMacScreenshotUsers: Bool
    let notifications: [Notification]
    let notificationMethods: [NotificationMethod]
  }
}

extension GetAccountSettings: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let settings = try await GetAccountOwner_v2.resolve(in: context.legacyContext)
    return .init(
      email: settings.email,
      dailyReviewEmail: settings.dailyReviewEmail,
      hasMacScreenshotUsers: settings.hasMacScreenshotUsers,
      notifications: settings.notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      notificationMethods: settings.verifiedNotificationMethods.map {
        .init(id: $0.id, config: $0.config)
      },
    )
  }
}
