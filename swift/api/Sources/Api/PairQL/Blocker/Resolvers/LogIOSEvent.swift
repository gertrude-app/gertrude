import BlockerRoute

extension LogIOSEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("LogIOSEvent(v1)")

    let v2Input = LogIOSEvent_v2.Input(
      eventId: input.eventId,
      kind: input.kind,
      modelIdentifier: ModelIdentifier.fromLegacyDeviceType(input.deviceType),
      iOSVersion: input.iOSVersion,
      appVersion: "0.0.0", // unknown in v1
      vendorId: input.vendorId,
      detail: input.detail,
    )

    return try await LogIOSEvent_v2.resolve(with: v2Input, in: context)
  }
}
