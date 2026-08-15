import PairQL

struct GetPersonInstalledMacApps: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
  }

  typealias Output = GetInstalledMacApps.Output
}

extension GetPersonInstalledMacApps: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    return try await GetInstalledMacApps.resolve(
      with: person.id,
      in: context.legacyContext,
    )
  }
}
