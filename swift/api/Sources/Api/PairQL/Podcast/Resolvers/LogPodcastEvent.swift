import PodcastRoute

extension LogPodcastEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("LogPodcastEvent(v1)")

    let v2Input = LogPodcastEvent_v2.Input(
      eventId: input.eventId,
      kind: input.kind,
      label: input.label,
      detail: input.detail,
      installId: input.installId,
      modelIdentifier: ModelIdentifier.fromLegacyDeviceType(input.deviceType),
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    )

    return try await LogPodcastEvent_v2.resolve(with: v2Input, in: context)
  }
}
