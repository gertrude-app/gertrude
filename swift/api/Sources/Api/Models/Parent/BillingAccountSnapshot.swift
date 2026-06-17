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

  var liveSubscription: StripeSubscription? {
    self.stripeSubscription?.stripeStatus.isLive == true
      ? self.stripeSubscription
      : nil
  }

  var planStatus: PlanStatus {
    if self.billingIdentity?.isComplimentary == true {
      return .complimentary
    }

    let liveSub = self.liveSubscription

    if let sub = liveSub, sub.tier == .full {
      return .full(status: billingStatus(of: sub))
    }

    if let trialStart = self.billingIdentity?.fullTrialStartedAt {
      let substrate = liveSub.map {
        PaidSubscription(tier: $0.tier, status: billingStatus(of: $0))
      }
      let trialEnd = trialStart + PlanStatus.trialPeriod
      if self.date < trialEnd {
        return .fullTrial(until: trialEnd, substrate: substrate)
      }
      let graceEnd = trialEnd + PlanStatus.gracePeriod
      if self.date < graceEnd {
        return .fullTrialGrace(until: graceEnd, substrate: substrate)
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
    if self.billingIdentity?.isComplimentary == true {
      return Set(Capability.allCases)
    }
    var capabilities: Set<Capability> = []
    if let sub = self.liveSubscription, sub.stripeStatus != .pastDue {
      capabilities.formUnion(sub.tier.capabilities)
    }
    if let trialStart = self.billingIdentity?.fullTrialStartedAt,
       self.date < trialStart + PlanStatus.trialPeriod {
      capabilities.insert(.connectMacApp)
      capabilities.insert(.useGertrudeMusic)
    }
    return capabilities
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
  case useGertrudeMusic
}

extension StripeSubscription.Tier {
  var capabilities: Set<Capability> {
    switch self {
    case .light: [.superviseIosDevice, .useGertrudeMusic]
    case .full: [.superviseIosDevice, .connectMacApp, .useGertrudeMusic]
    }
  }
}

private func billingStatus(of sub: StripeSubscription) -> BillingStatus {
  sub.stripeStatus == .pastDue
    ? .pastDue(since: sub.currentPeriodEnd)
    : .current(renewsAt: sub.currentPeriodEnd)
}
