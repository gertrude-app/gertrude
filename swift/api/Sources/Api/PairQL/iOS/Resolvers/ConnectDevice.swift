import IOSRoute

extension ConnectDevice: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    await ctx.db.logDeprecated("ConnectDevice(v1)")

    let v2Input = ConnectDevice_v2.Input(
      verificationCode: input.verificationCode,
      vendorId: input.vendorId,
      modelIdentifier: ModelIdentifier.fromLegacyDeviceType(input.deviceType),
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    )

    return try await ConnectDevice_v2.resolve(with: v2Input, in: ctx)
  }
}
