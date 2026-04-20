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
    let subscription = try await context.parent.subscription(in: context.db)
    let code = await with(dependency: \.ephemeral).createPendingAppConnection(child.id)
    let plan = Plan(subscription: subscription, now: get(dependency: \.date.now))

    switch plan {
    case .full(.complimentary), .full(.trialing), .full(.paid):
      return .init(code: code, gate: nil)
    case .full(.trialExpired(kind: .fromLight)):
      return .init(code: code, gate: .planUpgradeRequired)
    case .full(.trialExpired(kind: .fromLapsedLight)):
      return .init(code: code, gate: .subscriptionFixRequired)
    case .full(.overdue), .full(.trialExpired):
      return .init(code: code, gate: .subscriptionFixRequired)
    case .light(.paid(_, hasTrialedFull: false)):
      return .init(code: code, gate: .trialRequired)
    case .light(.paid(_, hasTrialedFull: true)):
      return .init(code: code, gate: .planUpgradeRequired)
    case .light(.overdue):
      return .init(code: code, gate: .subscriptionFixRequired)
    case .free(.standard):
      return .init(code: code, gate: .trialRequired)
    case .free(.lapsedFull):
      return .init(code: code, gate: .subscriptionFixRequired)
    case .free(.lapsedLight(_, hasTrialedFull: false)):
      return .init(code: code, gate: .trialRequired)
    case .free(.lapsedLight(_, hasTrialedFull: true)):
      return .init(code: code, gate: .planUpgradeRequired)
    }
  }
}
