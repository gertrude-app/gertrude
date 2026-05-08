import Foundation
import PairQL

struct MacAppConnectionCode: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
  }

  enum Gate: String, PairNestable {
    case trialRequired
    case planUpgradeRequired
    case subscriptionFixRequired
  }

  struct Output: PairOutput {
    var code: Int
    var gate: Gate?
  }
}

// resolver

extension MacAppConnectionCode: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChild(from: input.childId)
    let billing = try await context.parent.parentBilling(in: context.db)
    let code = await with(dependency: \.ephemeral).createPendingAppConnection(child.id)
    let now = get(dependency: \.date.now)

    let entitlement = billing.entitlement(at: now)
    let identity = billing.identity
    let sub = billing.stripeSubscription
    let trialedFull = identity.fullTrialStartedAt != nil
    let hasHistory = identity.lastStripeSubscriptionId != nil

    switch entitlement {
    case .complimentary:
      return .init(code: code, gate: nil)

    case .full:
      if sub?.stripeStatus == .pastDue {
        return .init(code: code, gate: .subscriptionFixRequired)
      }
      return .init(code: code, gate: nil)

    case .fullTrial:
      return .init(code: code, gate: nil)

    case .fullTrialGrace:
      if sub?.tier == .light {
        return .init(code: code, gate: .planUpgradeRequired)
      }
      return .init(code: code, gate: .subscriptionFixRequired)

    case .light:
      if sub?.stripeStatus == .pastDue {
        return .init(code: code, gate: .subscriptionFixRequired)
      }
      return .init(code: code, gate: trialedFull ? .planUpgradeRequired : .trialRequired)

    case .free:
      if !hasHistory {
        return .init(code: code, gate: .trialRequired)
      }
      if identity.lastPaidTier == .full {
        return .init(code: code, gate: .subscriptionFixRequired)
      }
      return .init(code: code, gate: trialedFull ? .planUpgradeRequired : .trialRequired)
    }
  }
}
