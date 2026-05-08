import Dependencies
import DuetSQL
import XCTest
import XCTVapor
import XExpect
import XStripe

@testable import Api

final class StripeEventTests: ApiTestCase, @unchecked Sendable {
  func testUpdatesSubscription() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    // identity-only standalone trial → first invoice.paid creates the sub row
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(parentId: parent.id))

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
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
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.db.create(Parent.random) // <-- no subscription

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
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
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(parentId: parent.id))

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
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
      let retrieved = try await parent.model.subscription(in: self.db)!
    })
  }

  func testSubscriptionDeletedEventCancelsSubscription() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription { _, sub in
      sub.stripeId = subscriptionId
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
      let retrieved = try await parent.model.subscription(in: self.db)!
    })
  }

  // @see email ref:96dc2
  func testUpdateAdminSubscriptionStatusFromSubscriptionIdAndAlternateEmail() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let periodEnd = 1_704_050_627
    let parent = try await self.parentWithSubscription { p, sub in
      p.email = .init("changed@email.com") // <-- different email from stripe customer_email
      sub.stripeId = subscriptionId
    }

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
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
      let retrieved = try await parent.model.subscription(in: self.db)!
    })
  }

  func testReplayedEventIdIsIgnored() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.parent()
    _ = try await self.db.create(BillingIdentity(parentId: parent.id))
    let eventId = "evt_\("".random)"

    let json = """
      {
        "id": "\(eventId)",
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
            "customer_email": "\(parent.email)",
            "subscription": "\(subscriptionId.rawValue)",
            "lines": {
              "data": [
                {
                  "price": { "id": "price_1RJbTrGKRdhETuKAkI5OO1NB" }
                }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
      let retrieved = try await ParentWithSubscription.find(parent.id, in: self.db)
      expect(retrieved.subscription?.stripeId).toEqual(subscriptionId)
    })

    let differentSubId = "subId_".random
    let replayedJsonWithDifferentBody = """
      {
        "id": "\(eventId)",
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
            "customer_email": "\(parent.email)",
            "subscription": "\(differentSubId)",
            "lines": {
              "data": [
                {
                  "price": { "id": "price_1RJbTrGKRdhETuKAkI5OO1NB" }
                }
              ]
            }
          }
        }
      }
    """

    try await app.test(
      .POST,
      "stripe-events",
      body: .init(string: replayedJsonWithDifferentBody),
      afterResponse: { res in
        expect(res.status).toEqual(.noContent)
        let retrieved = try await ParentWithSubscription.find(parent.id, in: self.db)
        expect(retrieved.subscription?.stripeId).toEqual(subscriptionId)
      },
    )

    let storedEvents = try await StripeEvent.query()
      .where(.stripeEventId == .string(eventId))
      .all(in: self.db)
    expect(storedEvents.count).toEqual(1)
  }

  func testSubscriptionUpdatedReconcilesTierAndStatus() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .light
      sub.stripeId = subscriptionId
    }
    let newPeriodEnd = 1_704_050_627

    let json = """
      {
        "id": "evt_\("".random)",
        "type": "customer.subscription.updated",
        "data": {
          "object": {
            "id": "\(subscriptionId.rawValue)",
            "customer": "cus_test_reconcile",
            "status": "active",
            "current_period_end": \(newPeriodEnd),
            "items": {
              "data": [
                { "price": { "id": "price_1RJbTrGKRdhETuKAkI5OO1NB" } }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      expect(res.status).toEqual(.noContent)
      let retrieved = try await parent.model.subscription(in: self.db)!
      expect(retrieved.tier).toEqual(.full)
      expect(retrieved.stripeStatus).toEqual(.active)
      expect(retrieved.currentPeriodEnd)
        .toEqual(Date(timeIntervalSince1970: TimeInterval(newPeriodEnd)))
    })

    let alarms = self.sent.slacks.filter { $0.message.channel == "unexpected-errors" }
    expect(alarms.count).toEqual(1)
    expect(alarms[0].message.text.contains("Unexpected tier change")).toBeTrue()

    let interestingEvents = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string("tier_upgraded"))
      .all(in: self.db)
    expect(interestingEvents.count).toEqual(1)
  }

  func testSubscriptionUpdatedWritesStatusOnlyWhenTierUnchanged() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .full
      sub.stripeId = subscriptionId
    }
    let newPeriodEnd = 1_704_050_627

    let json = """
      {
        "id": "evt_\("".random)",
        "type": "customer.subscription.updated",
        "data": {
          "object": {
            "id": "\(subscriptionId.rawValue)",
            "status": "past_due",
            "current_period_end": \(newPeriodEnd),
            "items": {
              "data": [
                { "price": { "id": "price_1RJbTrGKRdhETuKAkI5OO1NB" } }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
      let retrieved = try await parent.model.subscription(in: self.db)!
      expect(retrieved.tier).toEqual(.full)
      expect(retrieved.stripeStatus).toEqual(.pastDue)
    })

    let alarms = self.sent.slacks.filter { $0.message.channel == "unexpected-errors" }
    expect(alarms.count).toEqual(0)
  }

  func testSubscriptionUpdatedTrialingDoesNotMirrorBillingStatus() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription { _, sub in
      sub.tier = .full
      sub.stripeId = subscriptionId
    }

    let json = """
      {
        "id": "evt_\("".random)",
        "type": "customer.subscription.updated",
        "data": {
          "object": {
            "id": "\(subscriptionId.rawValue)",
            "status": "trialing",
            "current_period_end": 1704050627,
            "items": {
              "data": [
                { "price": { "id": "price_1RJbTrGKRdhETuKAkI5OO1NB" } }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
      let retrieved = try await parent.model.subscription(in: self.db)!
      expect(retrieved.stripeStatus).toEqual(.trialing)
    })
  }

  func testInvoicePaidLooksUpParentByStripeCustomerId() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let customerId = "cus_\("".random)"
    let parent = try await self.parent {
      $0.email = .init("local@email.com")
    }
    _ = try await self.db.create(BillingIdentity(
      parentId: parent.id,
      stripeCustomerId: .init(customerId),
      lastStripeSubscriptionId: subscriptionId,
      lastPaidTier: .full,
    ))

    let json = """
      {
        "id": "evt_\("".random)",
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 1000,
            "customer": "\(customerId)",
            "customer_email": "stripe-side@different.com",
            "subscription": "\(subscriptionId.rawValue)",
            "lines": {
              "data": [
                { "price": { "id": "price_1RJbTrGKRdhETuKAkI5OO1NB" } }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
      let retrieved = try await ParentWithSubscription.find(parent.id, in: self.db)
      expect(retrieved.subscription?.stripeId).toEqual(subscriptionId)
    })
  }

  func testDuplicateOverwriteRejectedWhenExistingSubIsActive() async throws {
    let existingSubId = "sub_existing_".random
    let incomingSubId = "sub_incoming_".random
    let parent = try await self.parentWithSubscription { _, sub in
      sub.stripeId = .init(existingSubId)
      sub.tier = .full
    }

    let json = invoicePaidJson(
      eventId: "evt_\("".random)",
      email: parent.email.rawValue,
      subscriptionId: incomingSubId,
      priceId: "price_1RJbTrGKRdhETuKAkI5OO1NB",
    )

    try await withDependencies {
      $0.stripe.getSubscription = { id in
        expect(id).toBe(existingSubId)
        return .init(id: existingSubId, status: .active, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
        let retrieved = try await parent.model.subscription(in: self.db)!
        expect(retrieved.stripeId.rawValue).toEqual(existingSubId)
      })
    }

    let alarms = self.sent.slacks.filter { $0.message.channel == "unexpected-errors" }
    expect(alarms.count).toEqual(1)
    expect(alarms[0].message.text.contains("DUPLICATE SUBSCRIPTION ATTEMPT")).toBeTrue()

    let interestingEvents = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string("duplicate_subscription_rejected"))
      .all(in: self.db)
    expect(interestingEvents.count).toEqual(1)
  }

  func testDuplicateOverwriteAllowedWhenExistingSubIsCanceled() async throws {
    let existingSubId = "sub_existing_".random
    let incomingSubId = "sub_incoming_".random
    let parent = try await self.parentWithSubscription { _, sub in
      sub.stripeId = .init(existingSubId)
      sub.tier = .light
    }

    let json = invoicePaidJson(
      eventId: "evt_\("".random)",
      email: parent.email.rawValue,
      subscriptionId: incomingSubId,
      priceId: "price_1RJbTrGKRdhETuKAkI5OO1NB",
    )

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        .init(id: existingSubId, status: .canceled, customer: "cus_x", currentPeriodEnd: 0)
      }
    } operation: {
      try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
        let retrieved = try await parent.model.subscription(in: self.db)!
        expect(retrieved.stripeId.rawValue).toEqual(incomingSubId)
        expect(retrieved.tier).toEqual(.full)
      })
    }

    let alarms = self.sent.slacks.filter { $0.message.channel == "unexpected-errors" }
    expect(alarms.count).toEqual(0)

    let interestingEvents = try await InterestingEvent.query()
      .where(.parentId == parent.id)
      .where(.eventId == .string("subscription_overwritten"))
      .all(in: self.db)
    expect(interestingEvents.count).toEqual(1)
  }

  func testDuplicateOverwriteAllowedOnStripeResourceMissing() async throws {
    let existingSubId = "sub_existing_".random
    let incomingSubId = "sub_incoming_".random
    let parent = try await self.parentWithSubscription { _, sub in
      sub.stripeId = .init(existingSubId)
      sub.tier = .light
    }

    let json = invoicePaidJson(
      eventId: "evt_\("".random)",
      email: parent.email.rawValue,
      subscriptionId: incomingSubId,
      priceId: "price_1RJbTrGKRdhETuKAkI5OO1NB",
    )

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        throw Stripe.Api.Error(type: "invalid_request_error", code: "resource_missing")
      }
    } operation: {
      try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
        let retrieved = try await parent.model.subscription(in: self.db)!
        expect(retrieved.stripeId.rawValue).toEqual(incomingSubId)
      })
    }
  }

  func testDuplicateOverwriteRejectedOnUnknownStripeError() async throws {
    let existingSubId = "sub_existing_".random
    let incomingSubId = "sub_incoming_".random
    let parent = try await self.parentWithSubscription { _, sub in
      sub.stripeId = .init(existingSubId)
      sub.tier = .light
    }

    let json = invoicePaidJson(
      eventId: "evt_\("".random)",
      email: parent.email.rawValue,
      subscriptionId: incomingSubId,
      priceId: "price_1RJbTrGKRdhETuKAkI5OO1NB",
    )

    try await withDependencies {
      $0.stripe.getSubscription = { _ in
        throw Stripe.Api.Error(type: "api_error", code: "rate_limited")
      }
    } operation: {
      try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { _ in
        let retrieved = try await parent.model.subscription(in: self.db)!
        expect(retrieved.stripeId.rawValue).toEqual(existingSubId)
      })
    }

    let alarms = self.sent.slacks.filter { $0.message.channel == "unexpected-errors" }
    expect(alarms.count).toEqual(1)
  }

  func testZeroAmountDueInvoicePaidDoesNotOverrideCancelledStatus() async throws {
    let subscriptionId: StripeSubscription.StripeId = .init("subId_".random)
    let parent = try await self.parentWithSubscription { _, sub in
      sub.stripeId = subscriptionId
      sub.tier = .light
    }

    let json = """
      {
        "type": "invoice.paid",
        "data": {
          "object": {
            "amount_due": 0,
            "customer_email": "\(parent.email)",
            "subscription": "\(subscriptionId.rawValue)",
            "lines": {
              "data": [
                {
                  "price": {
                    "id": "price_1SwT4IGKRdhETuKAc9wwLtsR"
                  }
                }
              ]
            }
          }
        }
      }
    """

    try await app.test(.POST, "stripe-events", body: .init(string: json), afterResponse: { res in
      expect(res.status).toEqual(.noContent)
      let retrieved = try await parent.model.subscription(in: self.db)!
      expect(retrieved.tier).toEqual(.light)
    })
  }
}

private func invoicePaidJson(
  eventId: String,
  email: String,
  subscriptionId: String,
  priceId: String,
  amountDue: Int = 1000,
) -> String {
  """
    {
      "id": "\(eventId)",
      "type": "invoice.paid",
      "data": {
        "object": {
          "amount_due": \(amountDue),
          "customer_email": "\(email)",
          "subscription": "\(subscriptionId)",
          "lines": {
            "data": [
              { "price": { "id": "\(priceId)" } }
            ]
          }
        }
      }
    }
  """
}
