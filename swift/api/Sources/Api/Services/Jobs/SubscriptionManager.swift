import Dependencies
import DuetSQL
import Foundation
import Gertie
import Queues
import Vapor
import XCore

enum SubscriptionEmail: Equatable {
  case trialEndingSoon(length: Int, remaining: Int)
  case trialExpired(length: Int)
  case overdueToUnpaid
  case paidToOverdue
}

struct SubscriptionUpdate: Equatable {
  enum Action: Equatable {
    case update(status: BillingStatus.Db, expiration: Date)
    case delete(reason: String)
  }

  var action: Action
  var email: SubscriptionEmail?
}

struct SubscriptionManager: AsyncScheduledJob {
  @Dependency(\.stripe) var stripe
  @Dependency(\.env) var env
  @Dependency(\.db) var db
  @Dependency(\.date.now) var now
  @Dependency(\.postmark) var postmark

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    try await self.advanceExpired()
  }

  func advanceExpired() async throws {
    var logs: [String] = []
    let parents = try await ParentWithSubscription.all(in: self.db)
    for parent in parents {
      guard let update = try await self.subscriptionUpdate(for: parent) else {
        continue
      }

      switch (update.action, parent.subscription) {

      case (.update(let status, let expiration), .some(var subscription)):
        subscription.billingStatus = status
        subscription.statusExpiresAt = expiration
        try await self.db.update(subscription)
        let link = self.adminLink(for: parent.model)
        logs.append("Updated parent \(link) to `.\(status)` until \(expiration)")

      case (.delete(let reason), _):
        try await self.db.create(DeletedEntity(
          type: "Parent",
          reason: reason,
          data: JSON.encode(parent.model, [.isoDates]),
        ))
        logs.append("Deleted parent `\(parent.email)` reason: \(reason)")
        try await self.db.delete(parent.model)

      case (.update, .none):
        unexpected("f3c5e1b2", parent.model.id, "should be unreachable, investigate")
      }

      if let event = update.email {
        try await self.postmark.send(template: email(event, to: parent.email))
        logs.append("Sent `.\(event)` email to parent \(self.adminLink(for: parent.model))")
      }
    }

    if self.env.mode == .prod, !logs.isEmpty {
      self.postmark.toSuperAdmin(
        "Gertrude subscription manager events",
        "<ol><li>" + logs.joined(separator: "</li><li>") + "</li></ol>",
      )
    }
  }

  func subscriptionUpdate(for parent: ParentWithSubscription) async throws -> SubscriptionUpdate? {
    if !parent.emailVerified, parent.createdAt < self.now - .days(3) {
      return .init(
        action: .delete(reason: "email never verified"),
        email: nil,
      )
    }

    guard let subscription = parent.subscription else {
      return nil
    }

    if subscription.statusExpiresAt > self.now {
      return nil
    }

    let hasConnectedApp = try await parent.model.hasConnectedApp(self.db)
    switch subscription.billingStatus {

    case .trialing:
      return .init(
        action: .update(
          status: .trialExpiringSoon,
          expiration: self.now + Plan.Full.trialWarningDays,
        ),
        email: .trialEndingSoon(length: 21, remaining: 3),
      )

    case .trialExpiringSoon:
      return .init(
        action: .update(status: .trialExpired, expiration: self.now + Plan.Full.trialGraceDays),
        email: hasConnectedApp ? .trialExpired(length: 21) : nil,
      )

    case .trialExpired:
      return .init(
        action: .update(status: .unpaid, expiration: .distantFuture),
        email: hasConnectedApp ? .overdueToUnpaid : nil,
      )

    case .paid:
      return try await self.updateIfPaid(subscription.stripeId) ?? .init(
        action: .update(status: .overdue, expiration: self.now + .days(14)),
        email: .paidToOverdue,
      )

    case .overdue:
      return try await self.updateIfPaid(subscription.stripeId) ?? .init(
        action: .update(status: .unpaid, expiration: .distantFuture),
        email: hasConnectedApp ? .overdueToUnpaid : nil,
      )

    // terminal state, expiration is .distantFuture, hence unreachable
    case .unpaid:
      unexpected("bab0487a", parent.id)
      return nil

    // TODO: we're not generating this state yet, see issue #466
    case .cancelled:
      return nil

    // complimentary, expires should be .distantFuture, hence unreachable
    case nil where subscription.tier == .full:
      unexpected("2d1710c2", parent.id)
      return nil

    case nil:
      unexpected("8610dd81", parent.id) // unreachable
      return nil
    }
  }

  // failsafe in case webhook missed the `invoice.paid` event
  // theoretically, we should never find a subscription active
  private func updateIfPaid(
    _ subscriptionId: Subscription.StripeId?,
  ) async throws -> SubscriptionUpdate? {
    if let subsId = subscriptionId?.rawValue,
       let subscription = try? await self.stripe.getSubscription(subsId),
       subscription.status == .active {
      return .init(
        action: .update(
          status: .paid,
          expiration: Date(timeIntervalSince1970: TimeInterval(subscription.currentPeriodEnd))
            .advanced(by: .days(2)), // +2 days is for a little leeway, recommended by stripe docs
        ),
        email: nil,
      )
    }
    return nil
  }

  func adminLink(for parent: Parent) -> String {
    AdminLink().email(to: .parent(parent.id), text: parent.email.rawValue)
  }
}

// helpers

private extension Parent {
  func hasConnectedApp(_ db: any DuetSQL.Client) async throws -> Bool {
    let children = try await children(in: db)
    let computers = try await children.concurrentMap {
      try await $0.computerUsers(in: db)
    }.flatMap(\.self)
    if !computers.isEmpty { return true }

    let iosDevices = try await children.concurrentMap {
      try await $0.iosDevices(in: db)
    }.flatMap(\.self)
    return !iosDevices.isEmpty
  }
}

func email(_ event: SubscriptionEmail, to address: EmailAddress) -> TemplateEmail {
  switch event {
  case .trialEndingSoon(let length, let remaining):
    .trialEndingSoon(
      to: address.rawValue,
      model: .init(length: length, remaining: remaining),
    )
  case .trialExpired(let length):
    .trialExpired(to: address.rawValue, model: .init(length: length))
  case .overdueToUnpaid:
    .overdueToUnpaid(to: address.rawValue, model: .init())
  case .paidToOverdue:
    .paidToOverdue(to: address.rawValue, model: .init())
  }
}
