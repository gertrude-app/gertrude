import PodcastRoute

extension GetPodcastAppConfig: Resolver {
  static func resolve(with _: Input, in _: Context) async throws -> Output {
    .init(
      explainAccountText: nil,
      accountPriceText: nil,
    )
  }
}
