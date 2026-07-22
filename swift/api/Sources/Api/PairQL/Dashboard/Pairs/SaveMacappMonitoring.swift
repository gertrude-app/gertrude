import DuetSQL
import Gertie
import PairQL

struct SaveMacappMonitoring: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var id: Child.Id
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var showSuspensionActivity: Bool
  }
}

extension SaveMacappMonitoring: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    var child = try await context.verifiedChild(from: input.id)
    if child.filteringDisabled, !input.screenshotsEnabled {
      throw context.error(
        id: "f1c9a64d",
        type: .badRequest,
        debugMessage: "filteringDisabled=true requires screenshotsEnabled=true",
        userMessage: "Internet filtering can only be disabled if screenshots are enabled.",
        showContactSupport: false,
      )
    }
    if let details = monitoringDecreased(child: child, input: input) {
      let detail = "for child: \(child.name), \(details)"
      dashSecurityEvent(.monitoringDecreased, detail, in: context)
    }
    child.keyloggingEnabled = input.keyloggingEnabled
    child.screenshotsEnabled = input.screenshotsEnabled
    child.screenshotsResolution = input.screenshotsResolution
    child.screenshotsFrequency = max(10, input.screenshotsFrequency)
    child.showSuspensionActivity = input.showSuspensionActivity
    try await context.db.update(child)

    try await with(dependency: \.websockets)
      .send(.userUpdated, to: .user(child.id))
    return .success
  }
}

func monitoringDecreased(child: Child, input: SaveMacappMonitoring.Input) -> String? {
  var parts: [String] = []
  if child.keyloggingEnabled, !input.keyloggingEnabled {
    parts.append("keylogging disabled")
  }
  if child.screenshotsEnabled, !input.screenshotsEnabled {
    parts.append("screenshots disabled")
  }
  if child.screenshotsResolution > input.screenshotsResolution {
    parts.append("screenshots resolution decreased")
  }
  if child.screenshotsFrequency < input.screenshotsFrequency {
    parts.append("screenshots frequency decreased")
  }
  if child.showSuspensionActivity, !input.showSuspensionActivity {
    parts.append("suspension activity visibility disabled")
  }
  return parts.isEmpty ? nil : parts.joined(separator: ", ")
}
