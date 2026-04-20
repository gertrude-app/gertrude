import Foundation
import TaggedMoney
import TSCodable

@TSCodable
enum Plan: Equatable, Sendable {
  case free(kind: Plan.FreeKind)
  case light(status: BillingStatus.Light)
  case full(status: BillingStatus.Full)
}

enum BillingStatus {
  @TSCodable
  enum Full: Equatable, Sendable {
    case complimentary
    case trialing(kind: TrialKind, until: Date)
    case trialExpired(kind: TrialKind)
    case paid(stripeId: Subscription.StripeId, monthlyPriceInCents: Int)
    case overdue(stripeId: Subscription.StripeId, monthlyPriceInCents: Int)

    @TSCodable
    enum TrialKind: Equatable, Sendable {
      case full
      case fromLight(stripeId: Subscription.StripeId)
      case fromLapsedLight(stripeId: Subscription.StripeId)
    }
  }

  @TSCodable
  enum Light: Equatable, Sendable {
    case paid(stripeId: Subscription.StripeId, hasTrialedFull: Bool)
    case overdue(stripeId: Subscription.StripeId, hasTrialedFull: Bool)
  }
}

// extensions

extension Plan {
  @TSCodable
  enum FreeKind: Equatable, Sendable {
    case standard
    case lapsedLight(stripeId: Subscription.StripeId, hasTrialedFull: Bool)
    case lapsedFull(stripeId: Subscription.StripeId?)
  }

  enum Full {
    static let trialLengthDays: TimeInterval = .days(21)
    static let trialWarningDays: TimeInterval = .days(3)
    static let trialGraceDays: TimeInterval = .days(7)
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

  var isFull: Bool {
    switch self {
    case .full: true
    case .free, .light: false
    }
  }

  var isLight: Bool {
    switch self {
    case .light: true
    case .free, .full: false
    }
  }

  var isFree: Bool {
    switch self {
    case .free: true
    case .light, .full: false
    }
  }

  var allowsSupervision: Bool {
    switch self {
    case .free: false
    case .light: true
    case .full(let status):
      switch status {
      case .complimentary, .paid: true
      case .trialing(.fromLight, _), .trialExpired(.fromLight): true
      case .trialing(.full, _), .trialing(.fromLapsedLight, _): false
      case .trialExpired(.full), .trialExpired(.fromLapsedLight): false
      case .overdue: false
      }
    }
  }

  init(subscription: Subscription?, now: Date = Date()) {
    guard let subscription else {
      self = .free(kind: .standard)
      return
    }
    switch subscription.tier {
    case .light:
      switch (subscription.billingStatus, subscription.stripeId, subscription.trialStartedAt) {
      case (nil, _, _):
        fatalError("invariant 020adef4, id: \(subscription.id)")
      case (.trialing, _, _):
        fatalError("invariant 638203c8, id: \(subscription.id)")
      case (.trialExpiringSoon, _, _):
        fatalError("invariant e0e2821e, id: \(subscription.id)")
      case (.trialExpired, _, _):
        fatalError("invariant 6fd8c1f7, id: \(subscription.id)")
      case (.paid, nil, _):
        fatalError("invariant d486cada, id: \(subscription.id)")
      case (.overdue, nil, _):
        fatalError("invariant 4d047803, id: \(subscription.id)")
      case (.unpaid, nil, _):
        fatalError("invariant 38131a59, id: \(subscription.id)")
      case (.cancelled, nil, _):
        fatalError("invariant 4c79e7b7, id: \(subscription.id)")
      case (_, .none, .some):
        fatalError("invariant 08cd4729, id: \(subscription.id)")
      case (.paid, .some(let stripeId), .some(let trialStartedAt))
        where trialStartedAt + Full.trialLengthDays > now,
           (.overdue, .some(let stripeId), .some(let trialStartedAt))
             where trialStartedAt + Full.trialLengthDays > now:
        self = .full(status: .trialing(
          kind: .fromLight(stripeId: stripeId),
          until: trialStartedAt + Full.trialLengthDays,
        ))
      case (.paid, .some(let stripeId), .some(let trialStartedAt))
        where trialStartedAt + Full.trialLengthDays > now - Full.trialGraceDays,
           (.overdue, .some(let stripeId), .some(let trialStartedAt))
             where trialStartedAt + Full.trialLengthDays > now - Full.trialGraceDays:
        self = .full(status: .trialExpired(kind: .fromLight(stripeId: stripeId)))
      case (.unpaid, .some(let stripeId), .some(let trialStartedAt))
        where trialStartedAt + Full.trialLengthDays > now,
           (.cancelled, .some(let stripeId), .some(let trialStartedAt))
             where trialStartedAt + Full.trialLengthDays > now:
        self = .full(status: .trialing(
          kind: .fromLapsedLight(stripeId: stripeId),
          until: trialStartedAt + Full.trialLengthDays,
        ))
      case (.unpaid, .some(let stripeId), .some(let trialStartedAt))
        where trialStartedAt + Full.trialLengthDays > now - Full.trialGraceDays,
           (.cancelled, .some(let stripeId), .some(let trialStartedAt))
             where trialStartedAt + Full.trialLengthDays > now - Full.trialGraceDays:
        self = .full(status: .trialExpired(kind: .fromLapsedLight(stripeId: stripeId)))
      case (.paid, .some(let stripeId), let trialStarted):
        self = .light(status: .paid(stripeId: stripeId, hasTrialedFull: trialStarted != nil))
      case (.overdue, .some(let stripeId), let trialStarted):
        self = .light(status: .overdue(stripeId: stripeId, hasTrialedFull: trialStarted != nil))
      case (.unpaid, .some(let stripeId), let trialStarted):
        self = .free(kind: .lapsedLight(stripeId: stripeId, hasTrialedFull: trialStarted != nil))
      case (.cancelled, .some(let stripeId), let trialStarted):
        self = .free(kind: .lapsedLight(stripeId: stripeId, hasTrialedFull: trialStarted != nil))
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
        self = .free(kind: .lapsedFull(stripeId: nil))
      case (.cancelled, nil):
        fatalError("invariant 36fcef75, id: \(subscription.id)")
      case (.trialing, .some(_)):
        fatalError("invariant b36479be, id: \(subscription.id)")
      case (.trialExpiringSoon, .some(_)):
        fatalError("invariant 7e38249c, id: \(subscription.id)")
      case (.trialExpired, .some(_)):
        fatalError("invariant 7bb105c6, id: \(subscription.id)")
      case (.trialing, _):
        self = .full(status: .trialing(
          kind: .full,
          until: subscription.statusExpiresAt + Full.trialWarningDays,
        ))
      case (.trialExpiringSoon, _):
        self = .full(status: .trialing(kind: .full, until: subscription.statusExpiresAt))
      case (.trialExpired, nil):
        self = .full(status: .trialExpired(kind: .full))
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
