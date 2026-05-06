import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class SubscriptionManagerTests: ApiTestCase, @unchecked Sendable {

  // MARK: - delete unverified parents

  func testDeletesUnverifiedParentsOlderThanThreeDays() async throws {
    let stale = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = nil
    })
    let recent = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = nil
    })
    let verified = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = .reference - .days(1)
    })
    try await self.backdate(parent: stale.id, to: .reference - .days(4))
    try await self.backdate(parent: recent.id, to: .reference - .days(2))
    try await self.backdate(parent: verified.id, to: .reference - .days(10))

    let priorDeletions = try await DeletedEntity.query().count(in: self.db)
    let logs = try await SubscriptionManager().deleteUnverifiedParents()
    expect(logs.count >= 1).toEqual(true)

    let surviving = try await Parent.query().all(in: self.db)
    let survivingIds = surviving.map(\.id)
    expect(survivingIds.contains(stale.id)).toEqual(false)
    expect(survivingIds.contains(recent.id)).toEqual(true)
    expect(survivingIds.contains(verified.id)).toEqual(true)

    let postDeletions = try await DeletedEntity.query().all(in: self.db)
    expect(postDeletions.count > priorDeletions).toEqual(true)
    expect(postDeletions.contains { $0.reason == "email never verified" }).toEqual(true)
  }

  private func backdate(parent id: Parent.Id, to date: Date) async throws {
    var stmt = SQL.Statement("""
    UPDATE \(table: Parent.self) SET \(Parent.columnName(.createdAt)) =
    """)
    stmt.components.append(.sql(" "))
    stmt.components.append(.binding(.date(date)))
    stmt.components.append(.sql(" WHERE \(Parent.columnName(.id)) = "))
    stmt.components.append(.binding(.uuid(id)))
    try await self.db.execute(statement: stmt)
  }

  // MARK: - trial email progression (pure decision)

  func testNoEmailBeforeT18() {
    let trialStart = Date.reference
    let now = trialStart + .days(17)
    expect(nextTrialEmailDecision(
      lifecycle: .none,
      trialStartedAt: trialStart,
      hasConnectedApp: true,
      now: now,
    )).toBeNil()
  }

  func testEndingSoonAtExactlyT18() {
    let trialStart = Date.reference
    let now = trialStart + .days(18)
    expect(nextTrialEmailDecision(
      lifecycle: .none,
      trialStartedAt: trialStart,
      hasConnectedApp: false,
      now: now,
    )).toEqual(.init(
      send: .trialEndingSoon(length: 21, remaining: 3),
      nextLifecycle: .endingSoonSent,
    ))
  }

  func testTrialExpiredAtT21OnlyAfterEndingSoonSent() {
    let trialStart = Date.reference
    let now = trialStart + .days(21)
    expect(nextTrialEmailDecision(
      lifecycle: .none,
      trialStartedAt: trialStart,
      hasConnectedApp: true,
      now: now,
    )).toEqual(.init(
      send: .trialEndingSoon(length: 21, remaining: 3),
      nextLifecycle: .endingSoonSent,
    ))

    expect(nextTrialEmailDecision(
      lifecycle: .endingSoonSent,
      trialStartedAt: trialStart,
      hasConnectedApp: true,
      now: now,
    )).toEqual(.init(
      send: .trialExpired(length: 21),
      nextLifecycle: .expiredSent,
    ))
  }

  func testTrialExpiredSkipsEmailIfNotOnboarded() {
    let trialStart = Date.reference
    let now = trialStart + .days(21)
    expect(nextTrialEmailDecision(
      lifecycle: .endingSoonSent,
      trialStartedAt: trialStart,
      hasConnectedApp: false,
      now: now,
    )).toEqual(.init(send: nil, nextLifecycle: .expiredSent))
  }

  func testFinalSentAtT28OnboardedSendsOverdueToUnpaid() {
    let trialStart = Date.reference
    let now = trialStart + .days(28)
    expect(nextTrialEmailDecision(
      lifecycle: .expiredSent,
      trialStartedAt: trialStart,
      hasConnectedApp: true,
      now: now,
    )).toEqual(.init(
      send: .overdueToUnpaid,
      nextLifecycle: .finalSent,
    ))
  }

  func testFinalSentSkipsEmailIfNotOnboarded() {
    let trialStart = Date.reference
    let now = trialStart + .days(28)
    expect(nextTrialEmailDecision(
      lifecycle: .expiredSent,
      trialStartedAt: trialStart,
      hasConnectedApp: false,
      now: now,
    )).toEqual(.init(send: nil, nextLifecycle: .finalSent))
  }

  func testFinalLifecycleNoMoreEmails() {
    let trialStart = Date.reference
    let now = trialStart + .days(50)
    expect(nextTrialEmailDecision(
      lifecycle: .finalSent,
      trialStartedAt: trialStart,
      hasConnectedApp: true,
      now: now,
    )).toBeNil()
  }

  // MARK: - trial email progression (integration)

  func testStandaloneTrialAdvancesAtT18() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(18),
      trialEmailLifecycle: .none,
    ))

    let logs = try await SubscriptionManager().advanceTrialEmails()
    expect(logs.count).toEqual(1)

    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(identity.trialEmailLifecycle).toEqual(.endingSoonSent)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].to).toEqual(parent.email.rawValue)
    expect(self.sent.emails[0].template).toBe("trial-ending-soon")
  }

  func testFromLightTrialGetsEndingSoonEmail() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(18),
      trialEmailLifecycle: .none,
    ))
    _ = try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .light,
      billingStatus: .paid,
      stripeId: .init("sub_light"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(180),
      statusExpiresAt: .reference + .days(182),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(identity.trialEmailLifecycle).toEqual(.endingSoonSent)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("trial-ending-soon")
  }

  func testPaidFullParentMarkedAsSkipped() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(18),
      trialEmailLifecycle: .none,
    ))
    _ = try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .full,
      billingStatus: .paid,
      stripeId: .init("sub_full"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(15),
      statusExpiresAt: .reference + .days(17),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(identity.trialEmailLifecycle).toEqual(.skipped)
    expect(self.sent.emails.count).toEqual(0)
  }

  func testComplimentaryIdentityIgnored() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .none,
      isComplimentary: true,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(identity.trialEmailLifecycle).toEqual(.none)
    expect(self.sent.emails.count).toEqual(0)
  }

  func testIdentityWithoutTrialIgnored() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: nil,
      trialEmailLifecycle: .none,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.count).toEqual(0)
  }

  func testFinalSentLifecycleFilteredOutByQuery() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .finalSent,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.count).toEqual(0)
  }

  func testSkippedLifecycleFilteredOutByQuery() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .skipped,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.count).toEqual(0)
  }

  func testTrialExpiredOnboardedSendsEmail() async throws {
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(21),
      trialEmailLifecycle: .endingSoonSent,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(identity.trialEmailLifecycle).toEqual(.expiredSent)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("trial-expired")
  }

  func testTrialExpiredNotOnboardedAdvancesWithoutEmail() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(21),
      trialEmailLifecycle: .endingSoonSent,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await BillingIdentity.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(identity.trialEmailLifecycle).toEqual(.expiredSent)
    expect(self.sent.emails.count).toEqual(0)
  }

  // MARK: - Stripe failsafe

  func testRefreshActiveSubKeepsActiveAndUpdatesPeriodEnd() async throws {
    try await self.db.delete(all: Subscription.self)
    let parent = try await self.parent()
    _ = try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .full,
      billingStatus: .paid,
      stripeId: .init("sub_x"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
      statusExpiresAt: .reference - .days(3),
    ))

    let nextPeriodEnd = Date.reference + .days(25)

    try await withDependencies {
      $0.stripe.getSubscription = { id in
        expect(id).toEqual("sub_x")
        return .init(
          id: id,
          status: .active,
          customer: "cus_x",
          currentPeriodEnd: Int(Date.epoch.distance(to: nextPeriodEnd)),
        )
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await Subscription.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(sub.stripeStatus).toEqual(.active)
    expect(sub.currentPeriodEnd).toEqual(nextPeriodEnd)
    expect(sub.statusExpiresAt).toEqual(nextPeriodEnd + .days(2))
    expect(sub.billingStatus).toEqual(.paid)
    expect(self.sent.emails.count).toEqual(0)
  }

  func testActiveToPastDueSendsPaidToOverdueEmail() async throws {
    try await self.db.delete(all: Subscription.self)
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .full,
      billingStatus: .paid,
      stripeId: .init("sub_pd"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
      statusExpiresAt: .reference - .days(3),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: "sub_pd", status: .pastDue, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await Subscription.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(sub.stripeStatus).toEqual(.pastDue)
    expect(sub.billingStatus).toEqual(.overdue)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("paid-to-overdue")
  }

  func testPastDueToCanceledOnboardedSendsOverdueToUnpaidEmail() async throws {
    try await self.db.delete(all: Subscription.self)
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .full,
      billingStatus: .overdue,
      stripeId: .init("sub_cx"),
      stripeStatus: .pastDue,
      currentPeriodEnd: .reference - .days(8),
      statusExpiresAt: .reference - .days(6),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: "sub_cx", status: .canceled, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await Subscription.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(sub.stripeStatus).toEqual(.canceled)
    expect(sub.billingStatus).toEqual(.cancelled)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("overdue-to-unpaid")
  }

  func testTerminalSubsAreNotRefreshed() async throws {
    try await self.db.delete(all: Subscription.self)
    let parent = try await self.parent()
    _ = try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .full,
      billingStatus: .cancelled,
      stripeId: .init("sub_t"),
      stripeStatus: .canceled,
      currentPeriodEnd: .reference - .days(50),
      statusExpiresAt: .distantFuture,
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        XCTFail("Stripe should not be called for terminal subs")
        return .init(id: "sub_t", status: .canceled, customer: "x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }
    expect(self.sent.emails.count).toEqual(0)
  }

  func testStripeLookupErrorIsSwallowed() async throws {
    try await self.db.delete(all: Subscription.self)
    let parent = try await self.parent()
    _ = try await self.db.create(Subscription(
      parentId: parent.id,
      tier: .full,
      billingStatus: .paid,
      stripeId: .init("sub_e"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
      statusExpiresAt: .reference - .days(3),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        throw NSError(domain: "Test", code: 1)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await Subscription.query()
      .where(.parentId == parent.id)
      .first(in: self.db)
    expect(sub.stripeStatus).toEqual(.active)
    expect(self.sent.emails.count).toEqual(0)
  }
}

private extension ParentEntities {
  @discardableResult
  func withOnboardedChild() async throws -> ParentWithOnboardedChildEntities {
    @Dependency(\.db) var db
    let child = try await db.create(Child.random { $0.parentId = self.model.id })
    let computer = try await db.create(Computer.random { $0.parentId = self.model.id })
    let computerUser = try await db.create(ComputerUser.random {
      $0.childId = child.id
      $0.computerId = computer.id
    })
    return .init(
      model: self.model,
      token: self.token,
      child: child,
      computerUser: computerUser,
      computer: computer,
    )
  }
}
