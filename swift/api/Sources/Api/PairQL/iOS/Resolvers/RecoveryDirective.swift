import IOSRoute

extension RecoveryDirective: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    await context.db.logDeprecated("RecoveryDirective(v1)")

    let v2Input = RecoveryDirective_v2.Input(
      vendorId: input.vendorId,
      modelIdentifier: ModelIdentifier.fromLegacyDeviceType(input.deviceType),
      iOSVersion: input.iOSVersion,
      locale: input.locale,
      version: input.version,
    )

    return try await RecoveryDirective_v2.resolve(with: v2Input, in: context)
  }
}
