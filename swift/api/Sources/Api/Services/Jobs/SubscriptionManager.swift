import Dependencies
import DuetSQL
import Foundation
import Gertie
import Queues
import Vapor
import XCore
import XStripe

enum SubscriptionEmail: Equatable {
  case trialEndingSoon(length: Int, remaining: Int)
  case trialExpired(length: Int)
  case overdueToUnpaid
  case paidToOverdue
}

struct TrialEmailDecision: Equatable {
  let send: SubscriptionEmail?
  let nextLifecycle: BillingIdentity.TrialEmailLifecycle
}

struct SubscriptionManager: AsyncScheduledJob {
  @Dependency(\.stripe) var stripe
  @Dependency(\.env) var env
  @Dependency(\.db) var db
  @Dependency(\.date.now) var now
  @Dependency(\.postmark) var postmark

  func run(context: QueueContext) async throws {
    guard self.env.mode == .prod else { return }
    try await self.tick()
  }

  func tick() async throws {
    var logs: [String] = []
    try await logs.append(contentsOf: self.deleteUnverifiedParents())
    try await logs.append(contentsOf: self.advanceTrialEmails())
    try await logs.append(contentsOf: self.refreshStaleSubscriptions())

    if self.env.mode == .prod, !logs.isEmpty {
      self.postmark.toSuperAdmin(
        "Gertrude subscription manager events",
        "<ol><li>" + logs.joined(separator: "</li><li>") + "</li></ol>",
      )
    }
  }

  func deleteUnverifiedParents() async throws -> [String] {
    var logs: [String] = []
    let cutoff = self.now - .days(3)
    let stale = try await Parent.query()
      .where(.emailVerifiedAt == nil)
      .where(.createdAt < cutoff)
      .all(in: self.db)
    for parent in stale {
      try await self.db.create(DeletedEntity(
        type: "Parent",
        reason: "email never verified",
        data: JSON.encode(parent, [.isoDates]),
      ))
      try await self.db.delete(parent)
      logs.append("Deleted parent `\(parent.email)` reason: email never verified")
    }
    return logs
  }

  func advanceTrialEmails() async throws -> [String] {
    var logs: [String] = []
    let identities = try await BillingIdentity.query()
      .where(.isComplimentary == false)
      .where(.fullTrialStartedAt != nil)
      .where(.trialEmailLifecycle !=
        BillingIdentity.TrialEmailLifecycle.finalSent.rawValue)
      .where(.trialEmailLifecycle !=
        BillingIdentity.TrialEmailLifecycle.skipped.rawValue)
      .all(in: self.db)

    for var identity in identities {
      guard let trialStart = identity.fullTrialStartedAt else { continue }
      let parent: Parent
      do {
        parent = try await self.db.find(identity.parentId) as Parent
      } catch {
        unexpected("c2a31be4", identity.parentId)
        continue
      }

      let parentLink = self.adminLink(for: parent)
      let sub = try await parent.subscription(in: self.db)

      let currentlyPaidFull = sub?.tier == .full && sub?.stripeStatus.isPaying == true
      if currentlyPaidFull || identity.lastPaidTier == .full {
        identity.trialEmailLifecycle = .skipped
        try await self.db.update(identity)
        logs.append("Skipped trial email lifecycle for paid-full parent \(parentLink)")
        continue
      }

      let onboarded = try await parent.hasConnectedApp(self.db)
      let decision = nextTrialEmailDecision(
        lifecycle: identity.trialEmailLifecycle,
        trialStartedAt: trialStart,
        hasConnectedApp: onboarded,
        now: self.now,
      )
      guard let decision else { continue }

      if let event = decision.send {
        try await self.postmark.send(template: emailTemplate(event, to: parent.email))
        logs.append("Sent `.\(event)` email to parent \(parentLink)")
      }
      identity.trialEmailLifecycle = decision.nextLifecycle
      try await self.db.update(identity)
    }
    return logs
  }

  func refreshStaleSubscriptions() async throws -> [String] {
    var logs: [String] = []
    let threshold = self.now - .days(2)
    let liveStatuses = StripeSubscription.StripeStatus.allCases.filter { !terminal($0) }
      .map(\.rawValue)
    let stale = try await StripeSubscription.query()
      .where(.currentPeriodEnd < threshold)
      .where(.stripeStatus |=| liveStatuses)
      .all(in: self.db)

    for var sub in stale {
      let oldStatus = sub.stripeStatus
      let live: Stripe.Api.Subscription
      do {
        live = try await self.stripe.getSubscription(sub.stripeId.rawValue)
      } catch {
        continue
      }

      guard let newStatus = StripeSubscription.StripeStatus(rawValue: live.status.rawValue) else {
        unexpected("4d2af9c2", sub.parentId, "unknown stripe status: \(live.status.rawValue)")
        continue
      }
      let newPeriodEnd = Date(timeIntervalSince1970: TimeInterval(live.currentPeriodEnd))
      sub.stripeStatus = newStatus
      sub.currentPeriodEnd = newPeriodEnd
      try await self.db.update(sub)

      let parent = try await self.db.find(sub.parentId) as Parent
      let onboarded = try await parent.hasConnectedApp(self.db)

      if oldStatus != .pastDue, newStatus == .pastDue {
        try await self.postmark.send(template: emailTemplate(.paidToOverdue, to: parent.email))
        logs.append("Sent `.paidToOverdue` email to parent \(self.adminLink(for: parent))")
      } else if !terminal(oldStatus), terminal(newStatus), onboarded {
        try await self.postmark.send(template: emailTemplate(.overdueToUnpaid, to: parent.email))
        logs.append("Sent `.overdueToUnpaid` email to parent \(self.adminLink(for: parent))")
      }
    }
    return logs
  }

  func adminLink(for parent: Parent) -> String {
    AdminLink().email(to: .parent(parent.id), text: parent.email.rawValue)
  }
}

func nextTrialEmailDecision(
  lifecycle: BillingIdentity.TrialEmailLifecycle,
  trialStartedAt: Date,
  hasConnectedApp: Bool,
  now: Date,
) -> TrialEmailDecision? {
  let endingSoonAt = trialStartedAt + Entitlement.trialPeriod - .days(3)
  let expiredAt = trialStartedAt + Entitlement.trialPeriod
  let finalAt = trialStartedAt + Entitlement.trialPeriod + Entitlement.gracePeriod
  switch lifecycle {
  case .none where now >= endingSoonAt:
    return .init(
      send: .trialEndingSoon(length: 21, remaining: 3),
      nextLifecycle: .endingSoonSent,
    )
  case .endingSoonSent where now >= expiredAt:
    return .init(
      send: hasConnectedApp ? .trialExpired(length: 21) : nil,
      nextLifecycle: .expiredSent,
    )
  case .expiredSent where now >= finalAt:
    return .init(
      send: hasConnectedApp ? .overdueToUnpaid : nil,
      nextLifecycle: .finalSent,
    )
  default:
    return nil
  }
}

private func terminal(_ status: StripeSubscription.StripeStatus) -> Bool {
  switch status {
  case .canceled, .unpaid, .incompleteExpired: true
  case .active, .trialing, .pastDue, .incomplete: false
  }
}

private func emailTemplate(
  _ event: SubscriptionEmail,
  to address: EmailAddress,
) -> TemplateEmail {
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
