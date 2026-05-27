import Dependencies
import DuetSQL
import XCTest
import XExpect

@testable import Api

final class SubscriptionManagerTests: ApiTestCase, @unchecked Sendable {

  // MARK: - delete unverified parents

  func testDeletesUnverifiedParentsOlderThanThreeDays() async throws {
    var stale = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = nil
    })
    var recent = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = nil
    })
    var verified = try await self.db.create(Parent.random {
      $0.emailVerifiedAt = .reference - .days(1)
    })
    try await stale.modifyCreatedAt(.exact(.reference - .days(4)))
    try await recent.modifyCreatedAt(.exact(.reference - .days(2)))
    try await verified.modifyCreatedAt(.exact(.reference - .days(10)))

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

  func testStaleTrialShortCircuitsToFinalSentWithoutEmail() {
    let trialStart = Date.reference
    let now = trialStart + .days(36)
    for lifecycle in [BillingIdentity.TrialEmailLifecycle.none, .endingSoonSent, .expiredSent] {
      expect(nextTrialEmailDecision(
        lifecycle: lifecycle,
        trialStartedAt: trialStart,
        hasConnectedApp: true,
        now: now,
      )).toEqual(.init(send: nil, nextLifecycle: .finalSent))
    }
  }

  func testNotYetStaleAtFinalStillSendsOverdueToUnpaid() {
    let trialStart = Date.reference
    let now = trialStart + .days(34)
    expect(nextTrialEmailDecision(
      lifecycle: .expiredSent,
      trialStartedAt: trialStart,
      hasConnectedApp: true,
      now: now,
    )).toEqual(.init(send: .overdueToUnpaid, nextLifecycle: .finalSent))
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

    let identity = try await parent.model.billingIdentity(in: self.db)!
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
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .light,
      stripeId: .init("sub_light"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(180),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
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
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_full"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(15),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.skipped)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testLapsedFullParentMarkedAsSkippedViaLastPaidTier() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init("cus_lapsed_full"),
      fullTrialStartedAt: .reference - .days(50),
      lastStripeSubscriptionId: .init("sub_old_full"),
      lastPaidTier: .full,
      trialEmailLifecycle: .none,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.skipped)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testLapsedLightParentDoesNotShortCircuit() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init("cus_lapsed_light"),
      fullTrialStartedAt: .reference - .days(18),
      lastStripeSubscriptionId: .init("sub_old_light"),
      lastPaidTier: .light,
      trialEmailLifecycle: .none,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.endingSoonSent)
    expect(self.sent.emails.count).toEqual(1)
  }

  func testAncientLightTrialGoesTerminalWithoutEmail() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init("cus_ancient_light"),
      fullTrialStartedAt: .reference - .days(90),
      lastStripeSubscriptionId: .init("sub_ancient_light"),
      lastPaidTier: .light,
      trialEmailLifecycle: .none,
    ))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .light,
      stripeId: .init("sub_ancient_light"),
      stripeStatus: .active,
      currentPeriodEnd: .reference + .days(180),
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.finalSent)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
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

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.none)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testIdentityWithoutTrialIgnored() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: nil,
      trialEmailLifecycle: .none,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testFinalSentLifecycleFilteredOutByQuery() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .finalSent,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  func testSkippedLifecycleFilteredOutByQuery() async throws {
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      fullTrialStartedAt: .reference - .days(50),
      trialEmailLifecycle: .skipped,
    ))

    _ = try await SubscriptionManager().advanceTrialEmails()
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
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

    let identity = try await parent.model.billingIdentity(in: self.db)!
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

    let identity = try await parent.model.billingIdentity(in: self.db)!
    expect(identity.trialEmailLifecycle).toEqual(.expiredSent)
    expect(self.sent.emails.contains(where: { $0.to == parent.email.rawValue })).toBeFalse()
  }

  // MARK: - Stripe failsafe

  func testRefreshActiveSubKeepsActiveAndUpdatesPeriodEnd() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_x"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
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

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.stripeStatus).toEqual(.active)
    expect(sub.currentPeriodEnd).toEqual(nextPeriodEnd)
    expect(self.sent.emails.count).toEqual(0)
  }

  func testActiveToPastDueSendsPaidToOverdueEmail() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_pd"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: "sub_pd", status: .pastDue, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.stripeStatus).toEqual(.pastDue)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("paid-to-overdue")
  }

  func testPastDueToCanceledOnboardedSendsOverdueToUnpaidEmail() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try await parent.withOnboardedChild()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_cx"),
      stripeStatus: .pastDue,
      currentPeriodEnd: .reference - .days(8),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: "sub_cx", status: .canceled, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await parent.model.subscription(in: self.db)!
    expect(sub.stripeStatus).toEqual(.canceled)
    expect(self.sent.emails.count).toEqual(1)
    expect(self.sent.emails[0].template).toBe("overdue-to-unpaid")
  }

  func testTerminalSubsAreNotRefreshed() async throws {
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_t"),
      stripeStatus: .canceled,
      currentPeriodEnd: .reference - .days(50),
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
    try await self.db.delete(all: StripeSubscription.self)
    let parent = try await self.parent()
    _ = try? await self.db.create(BillingIdentity(parentId: parent.id))
    _ = try await self.db.create(StripeSubscription(
      parentId: parent.id,
      tier: .full,
      stripeId: .init("sub_e"),
      stripeStatus: .active,
      currentPeriodEnd: .reference - .days(5),
    ))

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        throw NSError(domain: "Test", code: 1)
      }
    } operation: {
      _ = try await SubscriptionManager().refreshStaleSubscriptions()
    }

    let sub = try await parent.model.subscription(in: self.db)!
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
