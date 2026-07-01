import BlockerRoute

extension CrossPromos: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    .init(promos: CrossPromoCatalog.select(app: .iosBlocker, for: .init(
      deviceId: input.deviceId,
      appVersion: input.appVersion,
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      locale: input.locale,
    )))
  }
}
