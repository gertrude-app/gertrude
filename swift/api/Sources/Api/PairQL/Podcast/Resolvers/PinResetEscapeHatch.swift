import Dependencies
import PodcastRoute

extension PinResetEscapeHatch: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let authorized = if let allowed = ctx.env.getUUID("PODCAST_PIN_RESET_DEVICE_ID") {
      allowed == input.deviceId || allowed == input.vendorId
    } else {
      false
    }

    await with(dependency: \.slack).internal(
      .podcasts,
      """
      Received podcast *PinResetEscapeHatch* request
      authorized: `\(authorized)`
      input: `\(input)`
      """,
    )

    return .init(authorized: authorized)
  }
}
