import Dependencies
import Foundation
import PairQL

struct GetAccountOwner: Pair {
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
    var entitlement: Entitlement
    var notifications: [Notification]
    var verifiedNotificationMethods: [VerifiedNotificationMethod]
  }
}

// extension

extension GetAccountOwner: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    @Dependency(\.date.now) var now
    let parent = context.parent
    async let billing = parent.parentBilling(in: context.db)
    async let notifications = parent.notifications(in: context.db)
    async let methods = parent.verifiedNotificationMethods(in: context.db)
    return try await .init(
      id: parent.id,
      email: parent.email.rawValue,
      entitlement: billing.entitlement(at: now),
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map {
        .init(id: $0.id, config: $0.config)
      },
    )
  }
}
