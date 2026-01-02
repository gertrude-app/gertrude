import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CreatePendingSupervision: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let now = get(dependency: \.date.now)
    let generator = get(dependency: \.verificationCode)

    let existing = try? await IOSApp.PendingSupervision.query()
      .where(.vendorId == input.vendorId)
      .first(in: ctx.db)

    if let existing {
      if existing.expiresAt > now {
        return Output(code: existing.code, expiresAt: existing.expiresAt)
      } else {
        try await ctx.db.delete(existing.id)
      }
    }

    for _ in 1 ... 20 {
      let code = generator.generate()
      let exists = try await IOSApp.PendingSupervision.query()
        .where(.code == .int(code))
        .exists(in: ctx.db)
      if exists {
        continue
      }
      let model = try await ctx.db.create(IOSApp.PendingSupervision(
        code: code,
        vendorId: input.vendorId,
        deviceType: input.deviceType,
        iosVersion: input.iosVersion,
        appVersion: input.appVersion,
        claimedByParentId: nil,
        childId: nil,
        expiresAt: now + .days(7),
      ))
      return Output(code: model.code, expiresAt: model.expiresAt)
    }

    let msg = "Unexpected collision failure creating pending supervision"
    await get(dependency: \.slack).error(msg)
    get(dependency: \.postmark).toSuperAdmin("Unexpected error", msg)

    throw Abort(.internalServerError)
  }
}
