import Dependencies
import Foundation
import PairQL

/// deprecated, remove 2/21/26
struct GetAdmin: Pair {
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

  enum SubscriptionStatus: PairNestable {
    case complimentary
    case trialing(daysLeft: Int)
    case paid
    case overdue
    case unpaid
  }

  struct Output: PairOutput {
    var id: Parent.Id
    var email: String
    var subscriptionStatus: SubscriptionStatus
    var notifications: [Notification]
    var verifiedNotificationMethods: [VerifiedNotificationMethod]
    var hasAdminChild: Bool
    var monthlyPriceInDollars: Int
  }
}

// resolver

extension GetAdmin: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let parent = context.parent
    async let subscription = parent.subscription(in: context.db)
    async let notifications = parent.notifications(in: context.db)
    async let methods = parent.verifiedNotificationMethods(in: context.db)

    return try await .init(
      id: parent.id,
      email: parent.email.rawValue,
      subscriptionStatus: .init(parent, subscription: subscription),
      notifications: notifications.map {
        .init(id: $0.id, trigger: $0.trigger, methodId: $0.methodId)
      },
      verifiedNotificationMethods: methods.map {
        .init(id: $0.id, config: $0.config)
      },
      // deprecated: was used to gate security event notifications, now always enabled
      hasAdminChild: false,
      monthlyPriceInDollars: subscription?.isLegacyPrice == true ? 5 : 10,
    )
  }
}

extension GetAdmin.SubscriptionStatus {
  init(_ parent: Parent, subscription: Subscription?) throws {
    switch Plan(subscription: subscription) {
    case .full(.complimentary):
      self = .complimentary
    case .full(.trialing(let expiration)):
      let delta = get(dependency: \.date.now).distance(to: expiration)
      self = .trialing(daysLeft: Int(delta / 86400))
    case .full(.trialExpired):
      self = .overdue
    case .full(.paid):
      self = .paid
    case .full(.overdue):
      self = .overdue
    // these states should be unreachable during deprecation of this pair
    case .free, .light:
      self = .paid
    }
  }
}
