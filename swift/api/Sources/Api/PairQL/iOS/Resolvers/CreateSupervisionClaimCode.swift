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
    var device = try await install.device(in: ctx.db)
    if try await device.supervision(in: ctx.db) == nil {
      _ = try await ctx.db.create(BlockerApp.Supervision(deviceId: device.id))
    }

    let claimCode = try await device.ensureClaimCode(for: .blocker, in: ctx.db)
    return Output(code: claimCode.code, expiresAt: claimCode.expiresAt)
  }
}
