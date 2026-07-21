import Dependencies
import DuetSQL

/// current/active stripe subscription
@DuetModel(schema: "parent", table: "stripe_subscriptions")
struct StripeSubscription: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var tier: Tier
  var stripeId: StripeId
  var stripeStatus: StripeStatus
  var currentPeriodEnd: Date
  var isLegacyPrice: Bool
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    parentId: Parent.Id,
    tier: Tier,
    stripeId: StripeId,
    stripeStatus: StripeStatus,
    currentPeriodEnd: Date,
  ) {
    self.id = id
    self.parentId = parentId
    self.tier = tier
    self.stripeId = stripeId
    self.stripeStatus = stripeStatus
    self.currentPeriodEnd = currentPeriodEnd
    self.isLegacyPrice = false
  }
}

extension StripeSubscription {
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

    /// true when a live stripe sub backs the parent's access. differs from `isPaying`
    /// by including `.trialing` — not produced today, but may be in the future.
    var isLive: Bool {
      switch self {
      case .active, .trialing, .pastDue: true
      case .unpaid, .canceled, .incomplete, .incompleteExpired: false
      }
    }
  }

  enum Tier: String, Codable, Equatable, CaseIterable, Sendable {
    case light
    case medium
    case full

    var checkoutStripePriceId: String {
      @Dependency(\.env) var env
      return switch self {
      case .full: env.stripe.priceIdFull
      case .medium: env.stripe.priceIdMedium
      case .light: env.stripe.priceIdLight
      }
    }

    var periodLengthInDays: Int {
      switch self {
      case .full, .medium: 30
      case .light: 365
      }
    }

    init?(stripePriceId: String) {
      @Dependency(\.env) var env
      if stripePriceId == env.stripe.priceIdFull {
        self = .full
      } else if stripePriceId == env.stripe.priceIdMedium {
        self = .medium
      } else if stripePriceId == env.stripe.priceIdLight {
        self = .light
      } else if env.stripe.legacyPriceIdsFull.contains(stripePriceId) {
        self = .full
      } else {
        return nil
      }
    }
  }
}

extension StripeSubscription.Tier: Comparable {
  static func < (lhs: Self, rhs: Self) -> Bool {
    allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
  }
}

extension StripeSubscription {
  typealias StripeId = Tagged<StripeSubscription, String>

  func parent(in db: any DuetSQL.Client) async throws -> Parent {
    try await db.find(self.parentId)
  }
}
