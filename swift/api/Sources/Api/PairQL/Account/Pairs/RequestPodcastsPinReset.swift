import PairQL

struct RequestPodcastsPinReset: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let deviceId: IOSDevice.Id
  }

  typealias Output = RequestAmPinReset.Output
}

extension RequestPodcastsPinReset: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    _ = try await context.iosDevice(input.deviceId)
    return try await RequestAmPinReset.resolve(
      with: .init(deviceId: input.deviceId),
      in: context.legacyContext,
    )
  }
}
