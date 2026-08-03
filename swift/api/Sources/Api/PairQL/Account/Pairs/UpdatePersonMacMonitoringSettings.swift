import Dependencies
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
    var person = try await context.person(input.personId)
    if !input.screenshotsEnabled, person.filteringDisabled {
      throw context.error(
        id: "c3578cf8",
        type: .badRequest,
        debugMessage: "filteringDisabled=true requires screenshotsEnabled=true",
        userMessage: "Screenshots must stay enabled while internet filtering is disabled.",
        showContactSupport: false,
      )
    }

    let resolution = max(1, input.screenshotsResolution)
    let frequency = max(10, input.screenshotsFrequency)
    guard
      person.keyloggingEnabled != input.keyloggingEnabled
      || person.showSuspensionActivity != input.showSuspensionActivity
      || person.screenshotsEnabled != input.screenshotsEnabled
      || person.screenshotsResolution != resolution
      || person.screenshotsFrequency != frequency
    else {
      return .success
    }

    var decreases: [String] = []
    if person.keyloggingEnabled, !input.keyloggingEnabled {
      decreases.append("keylogging disabled")
    }
    if person.screenshotsEnabled, !input.screenshotsEnabled {
      decreases.append("screenshots disabled")
    }
    if person.showSuspensionActivity, !input.showSuspensionActivity {
      decreases.append("suspension activity visibility disabled")
    }
    if person.screenshotsResolution > resolution {
      decreases.append("screenshots resolution decreased")
    }
    if person.screenshotsFrequency < frequency {
      decreases.append("screenshots frequency decreased")
    }

    person.keyloggingEnabled = input.keyloggingEnabled
    person.showSuspensionActivity = input.showSuspensionActivity
    person.screenshotsEnabled = input.screenshotsEnabled
    person.screenshotsResolution = resolution
    person.screenshotsFrequency = frequency
    if !decreases.isEmpty {
      dashSecurityEvent(
        .monitoringDecreased,
        "for child: \(person.name), \(decreases.joined(separator: ", "))",
        in: context.legacyContext,
      )
    }
    try await context.db.update(person)
    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(person.id))
    return .success
  }
}
