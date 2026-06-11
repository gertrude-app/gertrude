import PodcastRoute

extension CrossPromos: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    // TODO: suppress promos for apps already used via Input.deviceId
    .init(promos: [])
  }
}
