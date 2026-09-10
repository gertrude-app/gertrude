import PairQL

struct CreateMacConnectionCode: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
  }

  enum Gate: String, PairNestable {
    case trialRequired
    case planUpgradeRequired
    case subscriptionFixRequired
  }

  struct Output: PairOutput {
    let code: Int
    let gate: Gate?
  }
}

extension CreateMacConnectionCode: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let legacyOutput = try await MacAppConnectionCode.resolve(
      with: .init(childId: input.personId),
      in: context.legacyContext,
    )
    return .init(
      code: legacyOutput.code,
      gate: legacyOutput.gate.map(Gate.init),
    )
  }
}

extension CreateMacConnectionCode.Gate {
  init(_ legacyGate: MacAppConnectionGate) {
    switch legacyGate {
    case .trialRequired:
      self = .trialRequired
    case .planUpgradeRequired:
      self = .planUpgradeRequired
    case .subscriptionFixRequired:
      self = .subscriptionFixRequired
    }
  }
}
