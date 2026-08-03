import DuetSQL
import PairQL

struct GetPersonMacSettings: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
  }

  struct ScreenshotSettings: PairNestable {
    let enabled: Bool
    let resolution: Int
    let frequency: Int
    let canBeDisabled: Bool
  }

  struct Output: PairOutput {
    let keyloggingEnabled: Bool
    let showSuspensionActivity: Bool
    let screenshots: ScreenshotSettings
    let hasMacDevices: Bool
  }
}

extension GetPersonMacSettings: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    let hasMacDevices = try await ComputerUser.query()
      .where(.childId == person.id)
      .exists(in: context.db)
    return .init(
      keyloggingEnabled: person.keyloggingEnabled,
      showSuspensionActivity: person.showSuspensionActivity,
      screenshots: .init(
        enabled: person.screenshotsEnabled,
        resolution: person.screenshotsResolution,
        frequency: person.screenshotsFrequency,
        canBeDisabled: !person.filteringDisabled,
      ),
      hasMacDevices: hasMacDevices,
    )
  }
}
