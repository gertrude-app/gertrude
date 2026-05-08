import DuetSQL
import Tagged

struct BillingIdentity: Codable, Sendable {
  var id: Id
  var parentId: Parent.Id
  var stripeCustomerId: StripeCustomerId?
  var fullTrialStartedAt: Date?
  var lastStripeSubscriptionId: StripeSubscription.StripeId?
  var lastPaidTier: StripeSubscription.Tier?
  var trialEmailLifecycle: TrialEmailLifecycle
  var isComplimentary: Bool
  var createdAt = Date()
  var updatedAt = Date()

  init(
    id: Id = .init(),
    parentId: Parent.Id,
    stripeCustomerId: StripeCustomerId? = nil,
    fullTrialStartedAt: Date? = nil,
    lastStripeSubscriptionId: StripeSubscription.StripeId? = nil,
    lastPaidTier: StripeSubscription.Tier? = nil,
    trialEmailLifecycle: TrialEmailLifecycle = .none,
    isComplimentary: Bool = false,
  ) {
    self.id = id
    self.parentId = parentId
    self.stripeCustomerId = stripeCustomerId
    self.fullTrialStartedAt = fullTrialStartedAt
    self.lastStripeSubscriptionId = lastStripeSubscriptionId
    self.lastPaidTier = lastPaidTier
    self.trialEmailLifecycle = trialEmailLifecycle
    self.isComplimentary = isComplimentary
  }
}

extension BillingIdentity {
  typealias StripeCustomerId = Tagged<BillingIdentity, String>

  enum TrialEmailLifecycle: String, Codable, Equatable, CaseIterable, Sendable {
    case none
    case endingSoonSent = "ending_soon_sent"
    case expiredSent = "expired_sent"
    case finalSent = "final_sent"
    case skipped
  }
}
