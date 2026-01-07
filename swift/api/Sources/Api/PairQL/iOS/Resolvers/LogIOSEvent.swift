import IOSRoute

extension LogIOSEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("LogIOSEvent(v1)")

    let v2Input = LogIOSEvent_v2.Input(
      eventId: input.eventId,
      kind: input.kind,
      modelIdentifier: ModelIdentifier.fromLegacyDeviceType(input.deviceType),
      iOSVersion: input.iOSVersion,
      vendorId: input.vendorId,
      detail: input.detail,
    )

    return try await LogIOSEvent_v2.resolve(with: v2Input, in: context)
  }
}
