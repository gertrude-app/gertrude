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
    let device = try await install.device(in: ctx.db)

    let existing = try await device.supervision(in: ctx.db)
    if let existing, existing.claimCodeExpiresAt > now {
      return Output(code: existing.claimCode, expiresAt: existing.claimCodeExpiresAt)
    } else if let existing, existing.claimed {
      return Output(code: existing.claimCode, expiresAt: .distantFuture)
    }

    for _ in 1 ... 20 {
      let code = generator.generate()
      let codeExists = try await BlockerApp.Supervision.query()
        .where(.claimCode == code)
        .exists(in: ctx.db)
      if codeExists {
        continue
      }

      let supervision: BlockerApp.Supervision
      if var existing { // refresh expired supervision
        existing.claimCode = code
        existing.claimCodeExpiresAt = now + .days(7)
        supervision = existing
        try await ctx.db.update(supervision)
      } else {
        supervision = try await ctx.db.create(BlockerApp.Supervision(
          deviceId: device.id,
          claimCode: code,
          claimCodeExpiresAt: now + .days(7),
        ))
      }

      Task {
        await get(dependency: \.slack)
          .internal(.info, "*iOS supervision:* claim code `\(code)` created")
      }

      return Output(code: code, expiresAt: supervision.claimCodeExpiresAt)
    }

    let msg = "Unexpected collision failure creating supervision"
    await get(dependency: \.slack).error(msg)
    get(dependency: \.postmark).toSuperAdmin("Unexpected error", msg)

    throw Abort(.internalServerError)
  }
}
