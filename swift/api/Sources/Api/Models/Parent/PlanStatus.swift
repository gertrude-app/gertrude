import Foundation
import TSCodable
import XCore

/// plan-based view into a parent's billing account, at a moment of time
/// rich data beyond simple tier exists to drive nuanced capability biz logic,
/// e.g. fact that supervising an ios device requires paid+current light or full,
/// not a trialing full -- also used for subscription panel copy in dashboard
@TSCodable
enum PlanStatus: Equatable, Sendable {
  case free
  case light(status: BillingStatus)
  case medium(status: BillingStatus)
  case full(status: BillingStatus)
  case fullTrial(until: Date, substrate: PaidSubscription?)
  case fullTrialGrace(until: Date, substrate: PaidSubscription?)
  case complimentary
}

@TSCodable
enum BillingStatus: Equatable, Sendable {
  case current(renewsAt: Date)
  case pastDue(since: Date)
}

struct PaidSubscription: Codable, Equatable, Sendable {
  var tier: StripeSubscription.Tier
  var status: BillingStatus
}

extension PlanStatus {
  static let trialPeriod: TimeInterval = .days(21)
  static let gracePeriod: TimeInterval = .days(7)
}
