import PodcastRoute

extension LogPodcastEvent_v2: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("LogPodcastEvent(v2)")

    guard let deviceId = input.installId else {
      if context.env.mode == .prod {
        let slack = get(dependency: \.slack)
        await slack.internal(
          .info,
          "LogPodcastEvent(v2) received nil installId: eventId=`\(input.eventId)` label=`\(input.label)` model=`\(input.modelIdentifier)` appVersion=`\(input.appVersion)`",
        )
      }
      return .success
    }

    return try await LogPodcastEvent_v3.resolve(
      with: .init(
        eventId: input.eventId,
        kind: input.kind,
        label: input.label,
        detail: input.detail,
        deviceId: deviceId,
        modelIdentifier: input.modelIdentifier,
        appVersion: input.appVersion,
        iosVersion: input.iosVersion,
      ),
      in: context,
    )
  }
}
