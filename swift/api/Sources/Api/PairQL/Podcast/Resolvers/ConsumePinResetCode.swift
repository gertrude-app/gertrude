import Dependencies
import PodcastRoute

extension ConsumePinResetCode: Resolver {
  static func resolve(with input: Input, in ctx: PodcastApp.InstallContext) async throws -> Output {
    guard let installId = await with(dependency: \.ephemeral)
      .consumePinResetCode(input.code) else {
      throw ctx.error(
        id: "8a2d1f3c",
        type: .notFound,
        debugMessage: "pin reset code not found or expired",
        appTag: .incorrectConfirmationCode,
      )
    }
    guard installId == ctx.install.id else {
      throw ctx.error(
        id: "5e0c9b47",
        type: .unauthorized,
        debugMessage: "pin reset code does not belong to authed install",
        appTag: .incorrectConfirmationCode,
      )
    }
    return .success
  }
}
