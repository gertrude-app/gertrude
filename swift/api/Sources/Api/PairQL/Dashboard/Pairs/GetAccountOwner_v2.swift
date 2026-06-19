import Dependencies
import DuetSQL
import Foundation
import PairQL

struct GetAccountOwner_v2: Pair {
  static let auth: ClientAuth = .parent

  struct Notification: PairNestable {
    var id: Parent.Notification.Id
    var trigger: Parent.Notification.Trigger
    var methodId: Parent.NotificationMethod.Id
  }

  struct VerifiedNotificationMethod: PairNestable {
    var id: Parent.NotificationMethod.Id
    var config: Parent.NotificationMethod.Config
  }

  struct Output: PairOutput {
    var id: Parent.Id
    var email: String
    var dailyReviewEmail: Bool
    var hasMacScreenshotUsers: Bool
    var notifications: [Notification]
    var verifiedNotificationMethods: [VerifiedNotificationMethod]
  }
}

extension GetAccountOwner_v2: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let parent = context.parent
    async let notifications = parent.notifications(in: context.db)
    async let methods = parent.verifiedNotificationMethods(in: context.db)

    let children = try await parent.children(in: context.db)
    let screenshotChildIds = children.filter(\.screenshotsEnabled).map(\.id)
    var hasMacScreenshotUsers = false
    if !screenshotChildIds.isEmpty {
      hasMacScreenshotUsers = try await ComputerUser.query()
        .where(.childId |=| screenshotChildIds)
        .count(in: context.db) > 0
    }

    return try await .init(
      id: parent.id,
      email: parent.email.rawValue,
      dailyReviewEmail: parent.dailyReviewEmail,
      hasMacScreenshotUsers: hasMacScreenshotUsers,
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map {
        .init(id: $0.id, config: $0.config)
      },
    )
  }
}
