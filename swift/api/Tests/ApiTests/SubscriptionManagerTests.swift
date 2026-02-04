import Dependencies
import XCTest
import XExpect

@testable import Api

final class SubscriptionManagerTests: ApiTestCase, @unchecked Sendable {
  func testAdvanceExpiredFn() async throws {
    try await self.db.delete(all: Parent.self)
    try await self.db.delete(all: DeletedEntity.self)

    let nonExpired = Parent.random
    let nonExpiredSub = Subscription(
      parentId: nonExpired.id,
      tier: .full,
      billingStatus: .trialing,
      trialStartedAt: .reference,
      statusExpiresAt: .reference + .days(18),
    )

    let trialEndingSoon = Parent.random
    let trialEndingSoonSub = Subscription(
      parentId: trialEndingSoon.id,
      tier: .full,
      billingStatus: .trialing,
      trialStartedAt: .reference,
      statusExpiresAt: .reference - .days(1),
    )

    try await self.db.create([nonExpired, trialEndingSoon])
    try await self.db.create([nonExpiredSub, trialEndingSoonSub])
    try await SubscriptionManager().advanceExpired()

    let retrievedNonExpired = try await ParentWithSubscription.find(nonExpired.id, in: self.db)
    expect(retrievedNonExpired.subscription!.billingStatus).toEqual(.trialing)
    expect(retrievedNonExpired.subscription!.statusExpiresAt)
      .toEqual(.reference + .days(18))

    let retrievedTrialEndingSoon = try await ParentWithSubscription.find(
      trialEndingSoon.id,
      in: self.db,
    )
    expect(retrievedTrialEndingSoon.subscription!.billingStatus).toEqual(.trialExpiringSoon)
    expect(retrievedTrialEndingSoon.subscription!.statusExpiresAt)
      .toEqual(.reference + .days(3))

    expect(sent.emails.count).toEqual(1)
    expect(sent.emails[0].to).toEqual(trialEndingSoon.email.rawValue)
    expect(sent.emails[0].template).toBe("trial-ending-soon")
  }

  func testNonExpiredStateDoesNotUpdate() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .overdue
      $1.stripeId = .init("sub-123")
      $1.statusExpiresAt = .distantFuture
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toBeNil()
  }

  func testTrialExpiringSoon() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .trialing
      $1.trialStartedAt = .reference - .days(21)
      $1.statusExpiresAt = .reference - .days(1)
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .update(status: .trialExpiringSoon, expiration: .reference + .days(3)),
      email: .trialEndingSoon(length: 21, remaining: 3),
    ))
  }

  func testTrialEnded_NotOnboarded() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .trialExpiringSoon
      $1.trialStartedAt = .reference - .days(21)
      $1.statusExpiresAt = .reference - .days(1)
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .update(status: .trialExpired, expiration: .reference + .days(7)),
      email: nil, // <-- no email, they never onboarded
    ))
  }

  func testTrialEnded_Onboarded() async throws {
    let parentModel = try await self.parent()
      .withOnboardedChild().model
    let subscription = Subscription(
      parentId: parentModel.id,
      tier: .full,
      billingStatus: .trialExpiringSoon,
      trialStartedAt: .reference - .days(21),
      statusExpiresAt: .reference - .days(1),
    )
    let parent = ParentWithSubscription(model: parentModel, subscription: subscription)
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .update(status: .trialExpired, expiration: .reference + .days(7)),
      email: .trialExpired(length: 21),
    ))
  }

  func testTrialExpiredToUnpaid_NotOnboarded() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .trialExpired
      $1.trialStartedAt = .reference - .days(21)
      $1.statusExpiresAt = .reference - .days(1)
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .update(status: .unpaid, expiration: .reference + .days(365)),
      email: nil, // <-- no email, they never onboarded
    ))
  }

  func testOverdueToUnpaid_NotOnboarded() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .overdue
      $1.stripeId = .init("sub-123")
      $1.statusExpiresAt = .epoch
    }
    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: "sub-123", status: .pastDue, customer: "cs-123", currentPeriodEnd: 0)
      }
    } operation: {
      await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
        action: .update(status: .unpaid, expiration: .reference + .days(365)),
        email: nil, // <-- no email, they never onboarded
      ))
    }
  }

  func testOverdueToUnpaid_Onboarded() async throws {
    let parentModel = try await self.parent()
      .withOnboardedChild().model
    let subscription = Subscription(
      parentId: parentModel.id,
      tier: .full,
      billingStatus: .overdue,
      trialStartedAt: .reference - .days(35),
      statusExpiresAt: .reference - .days(1),
    )
    let parent = ParentWithSubscription(model: parentModel, subscription: subscription)
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .update(status: .unpaid, expiration: .reference + .days(365)),
      email: .overdueToUnpaid,
    ))
  }

  func testUnpaidToPendingDeletion_NotOnboarded() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .unpaid
      $1.statusExpiresAt = .epoch
    }
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .softDelete,
      email: nil, // <-- no email, they never onboarded
    ))
  }

  func testUnpaidToPendingDeletion_Onboarded() throws {
    // TODO: see issue #477
    // let parent = try await self.parent {
    //   $0.subscriptionStatus = .unpaid
    //   $0.subscriptionStatusExpiration = .epoch
    // }.withOnboardedChild().model
    // await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
    //   action: .update(
    //     status: .pendingAccountDeletion,
    //     expiration: .reference + .days(30),
    //   ),
    //   email: .unpaidToPendingDelete,
    // ))
  }

  func testPendingDeletionToDeleted() throws {
    // TODO: see issue #477
    // let parent = Parent.empty {
    //   $0.subscriptionStatus = .pendingAccountDeletion
    //   $0.subscriptionStatusExpiration = .epoch
    // }
    // await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
    //   action: .delete(reason: "account unpaid > 1yr"),
    //   email: nil,
    // ))
  }

  func testEmailUnverifiedToDeleted() async throws {
    let parentModel = try await self.db.create(Parent.empty {
      $0.emailVerifiedAt = nil
      $0.createdAt = .reference - .days(4)
    })
    let parent = ParentWithSubscription(model: parentModel, subscription: nil)
    await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
      action: .delete(reason: "email never verified"),
      email: nil,
    ))
  }

  func testPaidToOverdue() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .paid
      $1.stripeId = .init("sub-123")
      $1.statusExpiresAt = .epoch
    }
    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        throw NSError(domain: "Test", code: 1)
      }
    } operation: {
      await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
        action: .update(status: .overdue, expiration: .reference + .days(14)),
        email: .paidToOverdue,
      ))
    }
  }

  func testPaidToOverdueButStripeSaysPaid() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .paid
      $1.stripeId = .init("sub-123")
      $1.statusExpiresAt = .epoch
    }

    let nextExpiration = Date.reference + .days(27)

    try await withDependencies {
      $0.stripe.getSubscription = { subsId in
        expect(subsId).toEqual("sub-123")
        return .init(
          id: subsId,
          status: .active,
          customer: "cs-123",
          currentPeriodEnd: Int(Date.epoch.distance(to: nextExpiration)),
        )
      }
    } operation: {
      await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
        action: .update(status: .paid, expiration: nextExpiration + .days(2)),
        email: nil,
      ))
    }
  }

  func testOverdueToPaid() async throws {
    let parent = try await self.parentWithSubscription {
      $1.billingStatus = .overdue
      $1.stripeId = .init("sub-123")
      $1.statusExpiresAt = .epoch
    }
    let nextExpiration = Date.reference + .days(27)
    try await withDependencies {
      $0.stripe.getSubscription = { subsId in
        expect(subsId).toEqual("sub-123")
        return .init(
          id: subsId,
          status: .active,
          customer: "cs-123",
          currentPeriodEnd: Int(Date.epoch.distance(to: nextExpiration)),
        )
      }
    } operation: {
      await expect(try SubscriptionManager().subscriptionUpdate(for: parent)).toEqual(.init(
        action: .update(status: .paid, expiration: nextExpiration + .days(2)),
        email: nil,
      ))
    }
  }
}

private extension ParentEntities {
  func withOnboardedChild(
    config: (inout Child, inout ComputerUser, inout Computer) -> Void = { _, _, _ in },
  ) async throws -> ParentWithOnboardedChildEntities {
    @Dependency(\.db) var db
    var child = Child.random { $0.parentId = model.id }
    var computer = Computer.random { $0.parentId = model.id }
    var computerUser = ComputerUser.random {
      $0.childId = child.id
      $0.computerId = computer.id
    }
    config(&child, &computerUser, &computer)
    try await db.create(child)
    try await db.create(computer)
    try await db.create(computerUser)
    return .init(
      model: self.model,
      token: self.token,
      child: child,
      computerUser: computerUser,
      computer: computer,
    )
  }
}
