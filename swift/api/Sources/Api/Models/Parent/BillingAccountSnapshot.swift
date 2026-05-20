import Foundation
import Gertie
import TaggedMoney

struct BillingAccountSnapshot: Sendable {
  let billingIdentity: BillingIdentity?
  let stripeSubscription: StripeSubscription?
  let date: Date

  var stripeSubscriptionId: StripeSubscription.Id? {
    self.stripeSubscription?.id
  }

  var stripeCustomerId: BillingIdentity.StripeCustomerId? {
    self.billingIdentity?.stripeCustomerId
  }

  var planStatus: PlanStatus {
    if self.billingIdentity?.isComplimentary == true {
      return .complimentary
    }

    let liveSub: StripeSubscription? =
      self.stripeSubscription?.stripeStatus.isLive == true
        ? self.stripeSubscription
        : nil

    if let sub = liveSub, sub.tier == .full {
      return .full(status: billingStatus(of: sub))
    }

    if let trialStart = self.billingIdentity?.fullTrialStartedAt {
      let trialEnd = trialStart + PlanStatus.trialPeriod
      if self.date < trialEnd {
        return .fullTrial(until: trialEnd)
      }
      let graceEnd = trialEnd + PlanStatus.gracePeriod
      if self.date < graceEnd {
        return .fullTrialGrace(until: graceEnd)
      }
    }

    guard let sub = liveSub else {
      return .free
    }

    switch sub.tier {
    case .light: return .light(status: billingStatus(of: sub))
    case .full: return .full(status: billingStatus(of: sub))
    }
  }

  var capabilities: Set<Capability> {
    switch self.planStatus {
    case .complimentary, .full(.current):
      [.superviseIosDevice, .connectMacApp]
    case .light(.current):
      [.superviseIosDevice]
    case .fullTrial:
      [.connectMacApp]
    case .free, .fullTrialGrace, .full(.pastDue), .light(.pastDue):
      []
    }
  }

  func can(_ capability: Capability) -> Bool {
    self.capabilities.contains(capability)
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

  var macAppAccessStatus: AdminAccountStatus {
    switch self.planStatus {
    case .full(.current), .complimentary, .fullTrial:
      .active
    case .full(.pastDue), .fullTrialGrace:
      .needsAttention
    case .light, .free:
      .inactive
    }
  }
}

enum Capability: Hashable, Sendable, CaseIterable {
  case superviseIosDevice
  case connectMacApp
}

private func billingStatus(of sub: StripeSubscription) -> BillingStatus {
  sub.stripeStatus == .pastDue
    ? .pastDue(since: sub.currentPeriodEnd)
    : .current(renewsAt: sub.currentPeriodEnd)
}
