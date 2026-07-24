import PairQL

struct DecideSuspensionRequest: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = DecideFilterSuspensionRequest.Input
}

extension DecideSuspensionRequest: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await DecideFilterSuspensionRequest.resolve(
      with: input,
      in: context.legacyContext,
    )
  }
}
