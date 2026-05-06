import Foundation

struct ParentBilling: Sendable {
  let identity: BillingIdentity
  let stripeSubscription: Subscription?

  func entitlement(at now: Date) -> Entitlement {
    if self.identity.isComplimentary {
      return .complimentary
    }

    let liveSub: Subscription? =
      self.stripeSubscription?.stripeStatus?.isLive == true
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
}
