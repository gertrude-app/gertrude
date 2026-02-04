import XCTest
import XExpect

@testable import Api

final class SubscriptionConstraintTests: ApiTestCase, @unchecked Sendable {
  func testInvalidSubscriptionsRejectedByDatabase() async throws {
    let parent = try await self.db.create(Parent.random)
    let parentId = parent.id

    struct InvalidCase: CustomStringConvertible {
      let description: String
      let subscription: Subscription
    }

    let invalidCases: [InvalidCase] = [
      // stripe_id_required_for_paid_status constraint:
      // paid, overdue, cancelled all require stripe_id
      .init(
        description: "paid status requires stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .paid,
          stripeId: nil,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "overdue status requires stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .overdue,
          stripeId: nil,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "cancelled status requires stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .cancelled,
          stripeId: nil,
          statusExpiresAt: .distantFuture,
        ),
      ),

      // trial_status_requires_full_plan constraint:
      // trialing, trialExpiringSoon, trialExpired can only be on full tier
      .init(
        description: "light tier cannot have trialing status",
        subscription: .init(
          parentId: parentId,
          tier: .light,
          billingStatus: .trialing,
          stripeId: .init("sub_test"),
          trialStartedAt: .now,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "light tier cannot have trialExpiringSoon status",
        subscription: .init(
          parentId: parentId,
          tier: .light,
          billingStatus: .trialExpiringSoon,
          stripeId: .init("sub_test"),
          trialStartedAt: .now,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "light tier cannot have trialExpired status",
        subscription: .init(
          parentId: parentId,
          tier: .light,
          billingStatus: .trialExpired,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),

      // trialing_requires_trial_started constraint:
      // trialing, trialExpiringSoon require trial_started_at
      .init(
        description: "trialing status requires trial_started_at",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialing,
          trialStartedAt: nil,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "trialExpiringSoon status requires trial_started_at",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialExpiringSoon,
          trialStartedAt: nil,
          statusExpiresAt: .distantFuture,
        ),
      ),

      // light_tier_requires_stripe_id constraint:
      // light tier always requires stripe_id
      .init(
        description: "light tier unpaid requires stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .light,
          billingStatus: .unpaid,
          stripeId: nil,
          statusExpiresAt: .distantFuture,
        ),
      ),

      // trial_status_forbids_stripe_id constraint:
      // trialing, trialExpiringSoon, trialExpired cannot have stripe_id
      .init(
        description: "trialing status cannot have stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialing,
          stripeId: .init("sub_test"),
          trialStartedAt: .now,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "trialExpiringSoon status cannot have stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialExpiringSoon,
          stripeId: .init("sub_test"),
          trialStartedAt: .now,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "trialExpired status cannot have stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialExpired,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),

      // Note: complimentary_requires_full_plan constraint (nil billing_status for
      // non-full tiers) cannot be tested via ORM due to nullable enum encoding issue.
      // The constraint is verified via migration tests with raw SQL.
    ]

    for invalidCase in invalidCases {
      do {
        try await self.db.create(invalidCase.subscription)
        XCTFail("Expected DB error for: \(invalidCase.description)")
        _ = try? await self.db.delete(invalidCase.subscription)
      } catch {
        let errorString = String(reflecting: error)
        let isConstraintError = errorString.contains("constraint")
        XCTAssertTrue(
          isConstraintError,
          "\(invalidCase.description): expected constraint error, got: \(error)",
        )
      }
    }
  }

  func testValidSubscriptionsAcceptedByDatabase() async throws {
    let parent = try await self.db.create(Parent.random)
    let parentId = parent.id

    struct ValidCase: CustomStringConvertible {
      let description: String
      let subscription: Subscription
    }

    let validCases: [ValidCase] = [
      // Note: complimentary (nil billing_status) cases cannot be tested via ORM
      // due to nullable enum encoding issue. Verified via migration tests.
      .init(
        description: "full tier trialing with trial_started_at",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialing,
          trialStartedAt: .now,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "full tier trialExpiringSoon with trial_started_at",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialExpiringSoon,
          trialStartedAt: .now,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "full tier trialExpired without stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .trialExpired,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "full tier paid with stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .paid,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "full tier overdue with stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .overdue,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "full tier unpaid without stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .unpaid,
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "light tier paid with stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .light,
          billingStatus: .paid,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "light tier overdue with stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .light,
          billingStatus: .overdue,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "light tier unpaid with stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .light,
          billingStatus: .unpaid,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),
      .init(
        description: "full tier unpaid with stripe_id",
        subscription: .init(
          parentId: parentId,
          tier: .full,
          billingStatus: .unpaid,
          stripeId: .init("sub_test"),
          statusExpiresAt: .distantFuture,
        ),
      ),
    ]

    for validCase in validCases {
      do {
        try await self.db.create(validCase.subscription)
        try await self.db.delete(validCase.subscription)
      } catch {
        XCTFail("Unexpected error for valid case '\(validCase.description)': \(error)")
      }
    }
  }
}
