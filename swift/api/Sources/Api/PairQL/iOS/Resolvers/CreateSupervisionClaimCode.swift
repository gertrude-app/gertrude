import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CreateSupervisionClaimCode: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    ModelIdentifier.alertIfUnknown(input.modelIdentifier)
    let now = get(dependency: \.date.now)
    let generator = get(dependency: \.verificationCode)
    let deviceId = IOSApp.Device.Id(input.deviceId)

    let device = try await IOSApp.Device.ensureExists(
      id: deviceId,
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )

    let existing = try await device.supervision(in: ctx.db)
    if let existing, existing.claimCodeExpiresAt > now {
      return Output(code: existing.claimCode, expiresAt: existing.claimCodeExpiresAt)
    } else if let existing, existing.claimed {
      return Output(code: existing.claimCode, expiresAt: .distantFuture)
    }

    for _ in 1 ... 20 {
      let code = generator.generate()
      let codeExists = try await IOSApp.Supervision.query()
        .where(.claimCode == code)
        .exists(in: ctx.db)
      if codeExists {
        continue
      }

      let supervision: IOSApp.Supervision
      if var existing { // refresh expired supervision
        existing.claimCode = code
        existing.claimCodeExpiresAt = now + .days(7)
        supervision = existing
        try await ctx.db.update(supervision)
      } else {
        supervision = try await ctx.db.create(IOSApp.Supervision(
          deviceId: device.id,
          claimCode: code,
          claimCodeExpiresAt: now + .days(7),
        ))
      }

      return Output(code: code, expiresAt: supervision.claimCodeExpiresAt)
    }

    let msg = "Unexpected collision failure creating supervision"
    await get(dependency: \.slack).error(msg)
    get(dependency: \.postmark).toSuperAdmin("Unexpected error", msg)

    throw Abort(.internalServerError)
  }
}
