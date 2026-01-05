import IOSRoute

extension ConnectedRules: Resolver {
  static func resolve(with input: Input, in ctx: IOSApp.ChildContext) async throws -> Output {
    await ctx.db.logDeprecated("ConnectedRules(v1)")

    let v2Input = ConnectedRules_v2.Input(
      vendorId: input.vendorId,
      modelIdentifier: ModelIdentifier.fromLegacyDeviceType(input.deviceType),
      appVersion: input.appVersion,
      iosVersion: input.iosVersion,
    )

    return try await ConnectedRules_v2.resolve(with: v2Input, in: ctx)
  }
}
