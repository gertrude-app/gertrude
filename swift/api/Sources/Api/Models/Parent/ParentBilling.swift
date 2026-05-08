import Foundation
import TaggedMoney

struct ParentBilling: Sendable {
  let identity: BillingIdentity
  let stripeSubscription: StripeSubscription?

  func entitlement(at now: Date) -> Entitlement {
    if self.identity.isComplimentary {
      return .complimentary
    }

    let liveSub: StripeSubscription? =
      self.stripeSubscription?.stripeStatus.isLive == true
        ? self.stripeSubscription
        : nil

    if liveSub?.tier == .full {
      return .full
    }

    if let trialStart = self.identity.fullTrialStartedAt {
      let trialEnd = trialStart + Entitlement.trialPeriod
      if now < trialEnd {
        return .fullTrial(until: trialEnd)
      }
      let graceEnd = trialEnd + Entitlement.gracePeriod
      if now < graceEnd {
        return .fullTrialGrace(until: graceEnd)
      }
    }

    guard let sub = liveSub else {
      return .free
    }

    switch sub.tier {
    case .light: return .light
    case .full: return .full
    }
  }

  var allowsSupervision: Bool {
    if self.identity.isComplimentary { return true }
    guard let sub = self.stripeSubscription, sub.stripeStatus.isLive else {
      return false
    }
    return !(sub.tier == .full && sub.stripeStatus == .pastDue)
  }

  var monthlyPrice: Cents<Int>? {
    guard let sub = self.stripeSubscription, sub.stripeStatus.isPaying else {
      return nil
    }
    switch sub.tier {
    case .light: return Cents(83)
    case .full: return Cents(sub.isLegacyPrice ? 500 : 1000)
    }
  }
}
