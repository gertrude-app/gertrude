import DuetSQL
import PodcastRoute

extension CreateClaimCode: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let device = try await ctx.db.find(IOSDevice.Id(input.deviceId))
    let claim = try await device.ensureClaim(intent: .podcasts, in: ctx.db)
    return Output(code: claim.code, expiresAt: claim.expiresAt)
  }
}
