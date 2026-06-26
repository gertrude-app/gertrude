import PairQL

struct DeleteActivity: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let keystrokeLineIds: [KeystrokeLine.Id]
    let screenshotIds: [Screenshot.Id]
  }
}

// resolver

extension DeleteActivity: Resolver {
  static func resolve(with input: Input, in context: AccountOwnerContext) async throws -> Output {
    try await DeleteActivityItems_v2.resolve(
      with: .init(
        keystrokeLineIds: input.keystrokeLineIds,
        screenshotIds: input.screenshotIds,
      ),
      in: context.legacyContext,
    )
  }
}
