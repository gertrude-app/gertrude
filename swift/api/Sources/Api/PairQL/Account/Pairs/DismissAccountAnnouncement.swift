import PairQL

struct DismissAccountAnnouncement: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let id: DashAnnouncement.Id
  }
}

extension DismissAccountAnnouncement: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await DeleteEntity_v2.resolve(
      with: .init(id: input.id.rawValue, type: .announcement),
      in: context.legacyContext,
    )
  }
}
