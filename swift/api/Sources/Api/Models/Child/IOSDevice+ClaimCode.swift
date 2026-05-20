import Dependencies
import DuetSQL
import Vapor

extension IOSDevice {
  struct ClaimCode {
    var code: Int
    var expiresAt: Date
  }

  mutating func ensureClaimCode(
    for app: GertrudeIOSApp,
    in db: any DuetSQL.Client,
  ) async throws -> ClaimCode {
    let now = get(dependency: \.date.now)
    let generator = get(dependency: \.verificationCode)

    if let claimCode = self.claimCode,
       let expiresAt = self.claimCodeExpiresAt,
       expiresAt > now {
      // already have a claim code, return it idempotently
      return ClaimCode(code: claimCode, expiresAt: expiresAt)
    } else if let claimCode = self.claimCode, self.claimedAt != nil {
      // already claimed, shouldn't be called, but prevent generating a new one
      return ClaimCode(code: claimCode, expiresAt: .distantFuture)
    }

    for _ in 1 ... 20 {
      let code = generator.generate()
      let codeExists = try await IOSDevice.query()
        .where(.claimCode == code)
        .exists(in: db)
      if codeExists {
        continue
      }

      let expiresAt = now + .days(7)
      self.claimCode = code
      self.claimCodeExpiresAt = expiresAt
      try await db.update(self)
      Task {
        await get(dependency: \.slack)
          .internal(app.slackChannel, "*\(app.claimLogLabel):* claim code `\(code)` created")
      }
      return ClaimCode(code: code, expiresAt: expiresAt)
    }

    let msg = "Unexpected collision failure creating IOSDevice claim code"
    await get(dependency: \.slack).error(msg)
    get(dependency: \.postmark).toSuperAdmin("Unexpected error", msg)
    throw Abort(.internalServerError)
  }
}
