import Foundation
import PairQL

struct MacAppConnectionCode: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var childId: Child.Id
  }

  struct Output: PairOutput {
    var code: Int
    var gate: MacAppConnectionGate?
  }
}

// resolver

extension MacAppConnectionCode: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChild(from: input.childId)
    let billing = try await context.currentBillingAccount()
    let code = await with(dependency: \.ephemeral).createPendingAppConnection(child.id)
    return .init(code: code, gate: billing.macAppConnectionGate)
  }
}

// extensions

enum MacAppConnectionGate: String, Codable, Equatable, Sendable {
  case trialRequired
  case planUpgradeRequired
  case subscriptionFixRequired
}

extension BillingAccountSnapshot {
  var macAppConnectionGate: MacAppConnectionGate? {
    let trialedFull = self.billingIdentity?.fullTrialStartedAt != nil
    let hasHistory = self.billingIdentity?.lastStripeSubscriptionId != nil

    switch self.planStatus {
    case .complimentary, .full(.current), .fullTrial:
      return nil

    case .full(.pastDue):
      return .subscriptionFixRequired

    case .fullTrialGrace(_, let substrate):
      if let substrate, substrate.tier == .light, case .current = substrate.status {
        return .planUpgradeRequired
      }
      return .subscriptionFixRequired

    case .light(.pastDue):
      return .subscriptionFixRequired

    case .light(.current):
      return trialedFull ? .planUpgradeRequired : .trialRequired

    case .free:
      if !hasHistory {
        return .trialRequired
      }
      if self.billingIdentity?.lastPaidTier == .full {
        return .subscriptionFixRequired
      }
      return trialedFull ? .planUpgradeRequired : .trialRequired
    }
  }
}
