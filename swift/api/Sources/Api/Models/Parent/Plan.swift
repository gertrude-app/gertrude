import Foundation
import TaggedMoney

enum Plan: Equatable, Sendable, Codable {
  case free(kind: Plan.FreeKind)
  case light(status: BillingStatus.Light)
  case full(status: BillingStatus.Full)
}

enum BillingStatus {
  enum Full: Equatable, Sendable, Codable {
    case complimentary
    case trialing(until: Date)
    case trialExpired
    case paid(stripeId: Subscription.StripeId, monthlyPriceInCents: Int)
    case overdue(stripeId: Subscription.StripeId, monthlyPriceInCents: Int)
  }

  enum Light: Equatable, Sendable, Codable {
    case paid(stripeId: Subscription.StripeId)
    case overdue(stripeId: Subscription.StripeId)
  }
}

// extensions

extension Plan {
  enum FreeKind: Equatable, Sendable, Codable {
    case standard
    case lapsedLight(stripeId: Subscription.StripeId)
    case lapsedFull(stripeId: Subscription.StripeId)
  }

  var monthlyPrice: Cents<Int>? {
    switch self {
    case .free:
      nil
    case .light:
      Cents(83) // $10/year ÷ 12 months
    case .full(let status):
      switch status {
      case .complimentary, .trialing, .trialExpired:
        nil
      case .paid(_, let monthlyPriceInCents), .overdue(_, let monthlyPriceInCents):
        Cents(monthlyPriceInCents)
      }
    }
  }

  init(subscription: Subscription?) {
    guard let subscription else {
      self = .free(kind: .standard)
      return
    }
    switch subscription.tier {
    case .light:
      switch (subscription.billingStatus, subscription.stripeId) {
      case (nil, _):
        fatalError("invariant 020adef4, id: \(subscription.id)")
      case (.trialing, _):
        fatalError("invariant 638203c8, id: \(subscription.id)")
      case (.trialExpiringSoon, _):
        fatalError("invariant e0e2821e, id: \(subscription.id)")
      case (.trialExpired, _):
        fatalError("invariant 6fd8c1f7, id: \(subscription.id)")
      case (.paid, nil):
        fatalError("invariant d486cada, id: \(subscription.id)")
      case (.overdue, nil):
        fatalError("invariant 4d047803, id: \(subscription.id)")
      case (.unpaid, nil):
        fatalError("invariant 38131a59, id: \(subscription.id)")
      case (.cancelled, nil):
        fatalError("invariant 4c79e7b7, id: \(subscription.id)")
      case (.paid, .some(let stripeId)):
        self = .light(status: .paid(stripeId: stripeId))
      case (.overdue, .some(let stripeId)):
        self = .light(status: .overdue(stripeId: stripeId))
      case (.unpaid, .some(let stripeId)):
        self = .free(kind: .lapsedLight(stripeId: stripeId))
      case (.cancelled, .some(let stripeId)):
        self = .free(kind: .lapsedLight(stripeId: stripeId))
      }
    case .full:
      let priceInCents = subscription.isLegacyPrice ? 500 : 1000
      switch (subscription.billingStatus, subscription.stripeId) {
      case (nil, _):
        self = .full(status: .complimentary)
      case (.paid, nil):
        fatalError("invariant 4c4e078c, id: \(subscription.id)")
      case (.overdue, nil):
        fatalError("invariant 30dd51e1, id: \(subscription.id)")
      case (.unpaid, nil):
        self = .free(kind: .standard)
      case (.cancelled, nil):
        fatalError("invariant 36fcef75, id: \(subscription.id)")
      case (.trialing, .some(_)):
        fatalError("invariant b36479be, id: \(subscription.id)")
      case (.trialExpiringSoon, .some(_)):
        fatalError("invariant 7e38249c, id: \(subscription.id)")
      case (.trialExpired, .some(_)):
        fatalError("invariant 7bb105c6, id: \(subscription.id)")
      case (.trialing, _):
        self = .full(status: .trialing(until: subscription.statusExpiresAt + .days(3)))
      case (.trialExpiringSoon, _):
        self = .full(status: .trialing(until: subscription.statusExpiresAt))
      case (.trialExpired, nil):
        self = .full(status: .trialExpired)
      case (.paid, .some(let stripeId)):
        self = .full(status: .paid(stripeId: stripeId, monthlyPriceInCents: priceInCents))
      case (.overdue, .some(let stripeId)):
        self = .full(status: .overdue(stripeId: stripeId, monthlyPriceInCents: priceInCents))
      case (.unpaid, .some(let stripeId)):
        self = .free(kind: .lapsedFull(stripeId: stripeId))
      case (.cancelled, .some(let stripeId)):
        self = .free(kind: .lapsedFull(stripeId: stripeId))
      }
    }
  }
}
