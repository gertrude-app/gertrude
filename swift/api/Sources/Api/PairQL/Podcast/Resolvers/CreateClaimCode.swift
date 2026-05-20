import DuetSQL
import PodcastRoute

extension CreateClaimCode: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    var device = try await ctx.db.find(IOSDevice.Id(input.deviceId))
    let claimCode = try await device.ensureClaimCode(for: .podcasts, in: ctx.db)
    return Output(code: claimCode.code, expiresAt: claimCode.expiresAt)
  }
}
