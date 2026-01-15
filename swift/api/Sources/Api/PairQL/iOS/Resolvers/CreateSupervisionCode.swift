import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CreateSupervisionCode: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let now = get(dependency: \.date.now)
    let generator = get(dependency: \.verificationCode)
    let deviceId = IOSApp.Device.Id(input.deviceId)

    let existing = try? await ctx.db.find(deviceId)

    if let existing, let code = existing.supervisionClaimCode,
       let expiresAt = existing.claimCodeExpiresAt {
      if expiresAt > now {
        return Output(code: code, expiresAt: expiresAt)
      } else {
        var updated = existing
        updated.supervisionClaimCode = nil
        updated.claimCodeExpiresAt = nil
        try await ctx.db.update(updated)
      }
    }

    for _ in 1 ... 20 {
      let code = generator.generate()
      let codeExists = try await IOSApp.Device.query()
        .where(.supervisionClaimCode == code)
        .exists(in: ctx.db)
      if codeExists {
        continue
      }

      let expiresAt = now + .days(7)

      if var device = existing {
        device.supervisionClaimCode = code
        device.claimCodeExpiresAt = expiresAt
        device.modelIdentifier = input.modelIdentifier
        device.iosVersion = input.iosVersion
        device.appVersion = input.appVersion
        try await ctx.db.update(device)
      } else {
        try await ctx.db.create(IOSApp.Device(
          id: deviceId,
          modelIdentifier: input.modelIdentifier,
          appVersion: input.appVersion,
          iosVersion: input.iosVersion,
          supervisionClaimCode: code,
          claimCodeExpiresAt: expiresAt,
        ))
      }

      ModelIdentifier.alertIfUnknown(input.modelIdentifier)

      return Output(code: code, expiresAt: expiresAt)
    }

    let msg = "Unexpected collision failure creating supervision code"
    await get(dependency: \.slack).error(msg)
    get(dependency: \.postmark).toSuperAdmin("Unexpected error", msg)

    throw Abort(.internalServerError)
  }
}
