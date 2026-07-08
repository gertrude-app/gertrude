import BlockerRoute
import GertieApp
import IOSAppsRoute

extension LogIOSEvent_v2: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("LogIOSEvent(v2)")

    return try await LogAppEvent.resolve(with: LogEventRequest(
      app: .blocker,
      eventId: input.eventId,
      level: .info,
      domain: input.inferredLegacyDomain,
      detail: input.normalizedDetail,
      deviceId: input.vendorId,
      modelIdentifier: input.modelIdentifier,
      appVersion: input.appVersion,
      iosVersion: input.iOSVersion,
    ), in: context)
  }
}

private extension LogIOSEvent_v2.Input {
  var inferredLegacyDomain: String? {
    if self.detail?.contains("[onboarding]") == true {
      "onboarding"
    } else if self.detail?.contains("controller proxy") == true
      || self.detail?.contains("filter install") == true {
      "filter"
    } else {
      nil
    }
  }

  var normalizedDetail: String? {
    var detail = self.detail
    if detail?.hasPrefix("[onboarding]: ") == true {
      detail = String(detail!.dropFirst("[onboarding]: ".count))
    } else if detail?.hasPrefix("[onboarding] ") == true {
      detail = String(detail!.dropFirst("[onboarding] ".count))
    }
    return detail
  }
}
