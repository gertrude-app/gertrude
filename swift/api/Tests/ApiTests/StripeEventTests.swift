import DuetSQL
import XCTest
import XCTVapor
import XExpect

@testable import Api

final class StripeEventTests: ApiTestCase, @unchecked Sendable {
  func testUpdatesSubscription() async throws {
    let subscriptionId: Subscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription {
      $1.stripeId = nil // <-- no subscription yet
      $1.billingStatus = .trialing
    }

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "\(parent.email)",
            "subscription": "\(subscriptionId.rawValue)",
            "lines": {
              "data": [
                {
                  "price": {
                    "id": "price_1RJbTrGKRdhETuKAkI5OO1NB"
                  },
                }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      let retrieved = try await ParentWithSubscription.find(parent.id, in: self.db)
      expect(retrieved.subscription?.stripeId).toEqual(subscriptionId)
    })
  }

  func testCreatesSubscription() async throws {
    let subscriptionId: Subscription.StripeId = .init("subId_".random)
    let parent = try await self.db.create(Parent.random) // <-- no subscription

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "\(parent.email)",
            "subscription": "\(subscriptionId.rawValue)",
            "lines": {
              "data": [
                {
                  "price": {
                    "id": "price_1RJbTrGKRdhETuKAkI5OO1NB"
                  },
                }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      let retrieved = try await ParentWithSubscription.find(parent.id, in: self.db)
      expect(retrieved.subscription?.stripeId).toEqual(subscriptionId)
    })
  }

  func testUpdateAdminSubscriptionStatusExpirationFromStripeEvent() async throws {
    let periodEnd = 1_704_050_627
    let subscriptionId: Subscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription {
      $1.stripeId = nil
      $1.billingStatus = .trialing
      $1.statusExpiresAt = .reference - .days(1000)
    }

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "\(parent.email)",
            "subscription": "\(subscriptionId.rawValue)",
            "lines": {
              "data": [
                {
                  "price": {
                    "id": "price_1RJbTrGKRdhETuKAkI5OO1NB"
                  },
                  "period": {
                    "end": \(periodEnd),
                    "start": 1701372227
                  }
                }
              ]
            }
          }
        }
      }
    """

    let expectedNewStatusExpiration = Date(timeIntervalSince1970: TimeInterval(periodEnd))
      .advanced(by: .days(2))

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      expect(res.status).toEqual(.noContent)
      let retrieved = try await Subscription.query()
        .where(.parentId == parent.id)
        .first(in: self.db)
      expect(retrieved.statusExpiresAt).toEqual(expectedNewStatusExpiration)
    })
  }

  func testSubscriptionDeletedEventCancelsSubscription() async throws {
    let subscriptionId: Subscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription {
      $1.stripeId = subscriptionId
      $1.billingStatus = .paid
      $1.statusExpiresAt = .reference + .days(30)
    }

    let json = """
      {
        "type": "customer.subscription.deleted",
        "data": {
          "object": {
            "id": "\(subscriptionId.rawValue)",
            "customer": "cus_test123",
            "status": "canceled"
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      expect(res.status).toEqual(.noContent)
      let retrieved = try await Subscription.query()
        .where(.parentId == parent.id)
        .first(in: self.db)
      expect(retrieved.billingStatus).toEqual(.cancelled)
      expect(retrieved.statusExpiresAt).toEqual(.distantFuture)
    })
  }

  // @see email ref:96dc2
  func testUpdateAdminSubscriptionStatusFromSubscriptionIdAndAlternateEmail() async throws {
    let subscriptionId: Subscription.StripeId = .init("subId_".random)
    let periodEnd = 1_704_050_627
    let parent = try await self.parentWithSubscription {
      $0.email = .init("changed@email.com") // <-- different email from stripe customer_email
      $1.stripeId = subscriptionId
      $1.billingStatus = .overdue
      $1.statusExpiresAt = .reference - .days(1000)
    }

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "customer_email": "stripe@email.com",
            "subscription": "\(subscriptionId.rawValue)",
            "lines": {
              "data": [
                {
                  "price": {
                    "id": "price_1RJbTrGKRdhETuKAkI5OO1NB"
                  },
                  "period": {
                    "end": \(periodEnd),
                    "start": 1701372227
                  }
                }
              ]
            }
          }
        }
      }
    """

    let expectedNewStatusExpiration = Date(timeIntervalSince1970: TimeInterval(periodEnd))
      .advanced(by: .days(2))

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      expect(res.status).toEqual(.noContent)
      let retrieved = try await Subscription.query()
        .where(.parentId == parent.id)
        .first(in: self.db)
      expect(retrieved.statusExpiresAt).toEqual(expectedNewStatusExpiration)
    })
  }
}
