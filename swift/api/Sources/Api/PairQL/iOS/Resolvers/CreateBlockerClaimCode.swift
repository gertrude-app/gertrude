import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CreateBlockerClaimCode: Resolver {
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
    let claim = try await device.ensureClaim(intent: .blockerConnect, in: ctx.db)
    return Output(code: claim.code, expiresAt: claim.expiresAt)
  }
}
