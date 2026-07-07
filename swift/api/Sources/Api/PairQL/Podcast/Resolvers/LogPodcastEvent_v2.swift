import GertieApp
import IOSAppsRoute
import PodcastRoute

extension LogPodcastEvent_v2: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("LogPodcastEvent(v2)")

    let (level, domain) = podcastEventLevelAndDomain(input.kind)

    return try await LogAppEvent.resolve(with: LogEventRequest(
      app: .podcasts,
      eventId: input.eventId,
      level: level,
      domain: domain,
      detail: input.detail,
      deviceId: input.installId,
      modelIdentifier: input.modelIdentifier,
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    ), in: context)
  }
}
