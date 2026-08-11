import PairQL

struct UpdatePersonMacMonitoringSettings: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
    let keyloggingEnabled: Bool
    let showSuspensionActivity: Bool
    let screenshotsEnabled: Bool
    let screenshotsResolution: Int
    let screenshotsFrequency: Int
  }
}

extension UpdatePersonMacMonitoringSettings: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    try await SaveMacappMonitoring.resolve(
      with: .init(
        id: input.personId,
        keyloggingEnabled: input.keyloggingEnabled,
        screenshotsEnabled: input.screenshotsEnabled,
        screenshotsResolution: input.screenshotsResolution,
        screenshotsFrequency: input.screenshotsFrequency,
        showSuspensionActivity: input.showSuspensionActivity,
      ),
      in: context.legacyContext,
    )
  }
}
