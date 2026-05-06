import DuetSQL

struct Subscription: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var tier: Tier
  var billingStatus: BillingStatus.Db?
  var stripeId: StripeId?
  var stripeStatus: StripeStatus?
  var currentPeriodEnd: Date?
  var isLegacyPrice: Bool
  var trialStartedAt: Date?
  var statusExpiresAt: Date
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    parentId: Parent.Id,
    tier: Tier,
    billingStatus: BillingStatus.Db? = nil,
    stripeId: StripeId? = nil,
    stripeStatus: StripeStatus? = nil,
    currentPeriodEnd: Date? = nil,
    trialStartedAt: Date? = nil,
    statusExpiresAt: Date,
  ) {
    self.id = id
    self.parentId = parentId
    self.tier = tier
    self.billingStatus = billingStatus
    self.stripeId = stripeId
    self.stripeStatus = stripeStatus
    self.currentPeriodEnd = currentPeriodEnd
    self.trialStartedAt = trialStartedAt
    self.statusExpiresAt = statusExpiresAt
    self.isLegacyPrice = false
  }
}

extension BillingStatus {
  enum Db: String, Codable, Equatable, CaseIterable, Sendable {
    case trialing
    case trialExpiringSoon
    case trialExpired
    case paid
    case overdue
    case unpaid
    case cancelled
  }
}

extension Subscription {
  enum StripeStatus: String, Codable, Equatable, CaseIterable, Sendable {
    case active
    case trialing
    case pastDue = "past_due"
    case unpaid
    case canceled
    case incomplete
    case incompleteExpired = "incomplete_expired"

    var isPaying: Bool {
      switch self {
      case .active, .pastDue: true
      case .trialing, .unpaid, .canceled, .incomplete, .incompleteExpired: false
      }
    }

    /// True when a live Stripe subscription object backs the parent's access.
    /// Distinct from `isPaying` in that `.trialing` is included: a trialing sub is
    /// live substrate (Stripe object exists, user has access) even though no money
    /// has changed hands yet. We don't currently produce `.trialing` subs (we don't
    /// pass `trial_period_days` to checkout), but we may in the future.
    var isLive: Bool {
      switch self {
      case .active, .trialing, .pastDue: true
      case .unpaid, .canceled, .incomplete, .incompleteExpired: false
      }
    }
  }

  enum Tier: String, Codable, Equatable, CaseIterable, Sendable {
    case light
    case full

    var checkoutStripePriceId: String {
      switch self {
      case .full: "price_1RJbTrGKRdhETuKAkI5OO1NB" // $10/month
      case .light: "price_1SwT4IGKRdhETuKAc9wwLtsR" // $10/year
      }
    }

    var periodLengthInDays: Int {
      switch self {
      case .full: 30
      case .light: 365
      }
    }

    init?(stripePriceId: String) {
      switch stripePriceId {
      case "price_1RJbTrGKRdhETuKAkI5OO1NB": self = .full // $10/month (current)
      case "price_1SwT4IGKRdhETuKAc9wwLtsR": self = .light // $10/year (current)
      // old, legacy prices
      case "price_1M9xZYGKRdhETuKA22aYJ4fI": self = .full
      case "price_1QooP1GKRdhETuKAcVawow7B": self = .full
      case "price_1Lz4dIGKRdhETuKA7ojOoW4g": self = .full
      default: return nil
      }
    }
  }
}

extension Subscription {
  typealias StripeId = Tagged<Subscription, String>

  var plan: Plan {
    .init(subscription: self)
  }

  func parent(in db: any DuetSQL.Client) async throws -> Parent {
    try await db.find(self.parentId)
  }
}
