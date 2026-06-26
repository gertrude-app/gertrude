import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CreateSupervisionClaimCode: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    let install = try await BlockerApp.Install.ensureExists(
      deviceId: IOSDevice.Id(input.deviceId),
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )
    let device = try await install.device(in: ctx.db)
    var supervision = try await device.supervision(in: ctx.db)
    if supervision == nil {
      supervision = try await ctx.db.create(BlockerApp.Supervision(deviceId: device.id))
    }

    if var claimed = try await Claim.find(device.id, intent: .blockerSupervise, in: ctx.db),
       claimed.claimedAt != nil, supervision?.supervisedAt == nil {
      try await claimed.renewIfPendingSupervision(supervision: supervision, in: ctx.db)
      return Output(code: claimed.code, expiresAt: claimed.expiresAt)
    }

    let claim = try await device.ensureClaim(intent: .blockerSupervise, in: ctx.db)
    return Output(code: claim.code, expiresAt: claim.expiresAt)
  }
}
