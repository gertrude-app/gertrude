import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CreateSupervisionClaimCode: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    ModelIdentifier.alertIfUnknown(input.modelIdentifier)
    let now = get(dependency: \.date.now)
    let generator = get(dependency: \.verificationCode)
    let deviceId = IOSDevice.Id(input.deviceId)

    let install = try await BlockerApp.Install.ensureExists(
      deviceId: deviceId,
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )
    var device = try await install.device(in: ctx.db)
    if try await device.supervision(in: ctx.db) == nil {
      _ = try await ctx.db.create(BlockerApp.Supervision(deviceId: device.id))
    }

    if let claimCode = device.claimCode,
       let expiresAt = device.claimCodeExpiresAt,
       expiresAt > now {
      return Output(code: claimCode, expiresAt: expiresAt)
    } else if let claimCode = device.claimCode, device.claimedAt != nil {
      return Output(code: claimCode, expiresAt: .distantFuture)
    }

    for _ in 1 ... 20 {
      let code = generator.generate()
      let codeExists = try await IOSDevice.query()
        .where(.claimCode == code)
        .exists(in: ctx.db)
      if codeExists {
        continue
      }

      let expiresAt = now + .days(7)
      device.claimCode = code
      device.claimCodeExpiresAt = expiresAt
      try await ctx.db.update(device)

      Task {
        await get(dependency: \.slack)
          .internal(.info, "*iOS supervision:* claim code `\(code)` created")
      }

      return Output(code: code, expiresAt: expiresAt)
    }

    let msg = "Unexpected collision failure creating supervision"
    await get(dependency: \.slack).error(msg)
    get(dependency: \.postmark).toSuperAdmin("Unexpected error", msg)

    throw Abort(.internalServerError)
  }
}
