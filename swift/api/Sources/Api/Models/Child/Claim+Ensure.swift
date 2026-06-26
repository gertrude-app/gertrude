import Dependencies
import DuetSQL
import Vapor

extension Claim {
  static let lifespan: TimeInterval = .days(7)
  static let supervisionRenewalDuration: TimeInterval = .days(21)

  static func find(code: Int, in db: any DuetSQL.Client) async throws -> Claim? {
    try await Claim.query()
      .where(.code == code)
      .all(in: db)
      .first
  }

  static func find(
    _ deviceId: IOSDevice.Id,
    intent: ClaimIntent,
    in db: any DuetSQL.Client,
  ) async throws -> Claim? {
    try await Claim.query()
      .where(.deviceId == deviceId)
      .all(in: db)
      .filter { $0.intent == intent }
      .sorted { $0.createdAt > $1.createdAt }
      .first
  }

  func device(in db: any DuetSQL.Client) async throws -> IOSDevice {
    try await db.find(self.deviceId)
  }

  func reusable(for intent: ClaimIntent, now: Date) -> Bool {
    self.intent == intent
      && self.expiresAt > now
      && (intent.requiresSupervision || self.claimedAt == nil)
  }

  static func ensureActive(
    intent: ClaimIntent,
    deviceId: IOSDevice.Id,
    in db: any DuetSQL.Client,
  ) async throws -> Claim {
    let now = get(dependency: \.date.now)
    let existing = try await Claim.query()
      .where(.deviceId == deviceId)
      .all(in: db)
    if let live = existing.first(where: { $0.reusable(for: intent, now: now) }) {
      return live
    }

    // no reusable claim; clear any stale unclaimed claim for this (device, intent) so the
    // partial unique index on (device_id, intent) WHERE claimed_at IS NULL permits a fresh mint
    for stale in existing where stale.intent == intent && stale.claimedAt == nil {
      try await Claim.query().where(.id == stale.id).delete(in: db)
    }

    let generator = get(dependency: \.verificationCode)
    for _ in 1 ... 20 {
      let code = generator.generate()
      let taken = try await Claim.query()
        .where(.code == code)
        .exists(in: db)
      if taken {
        continue
      }
      do {
        return try await db.create(Claim(
          code: code,
          intent: intent,
          deviceId: deviceId,
          expiresAt: now + Self.lifespan,
        ))
      } catch {
        // a concurrent mint may have won the (device_id, intent) partial unique index;
        // reuse the now-existing live claim instead of erroring
        let live = try await Claim.query()
          .where(.deviceId == deviceId)
          .all(in: db)
          .first(where: { $0.reusable(for: intent, now: now) })
        if let live {
          return live
        }
        throw error
      }
    }

    let msg = "Unexpected collision failure creating claim code"
    await get(dependency: \.slack).error(msg)
    get(dependency: \.postmark).toSuperAdmin("Unexpected error", msg)
    throw Abort(.internalServerError)
  }

  mutating func complete(childId: Child.Id, in db: any DuetSQL.Client) async throws {
    self.childId = childId
    self.claimedAt = get(dependency: \.date.now)
    try await db.update(self)
  }

  mutating func renewIfPendingSupervision(
    supervision: BlockerApp.Supervision?,
    in db: any DuetSQL.Client,
  ) async throws {
    let now = get(dependency: \.date.now)
    guard
      self.claimedAt != nil,
      self.expiresAt <= now,
      let supervision,
      supervision.supervisedAt == nil
    else {
      return
    }
    self.expiresAt = now + Self.supervisionRenewalDuration
    try await db.update(self)
  }
}

extension IOSDevice {
  func ensureClaim(
    intent: ClaimIntent,
    in db: any DuetSQL.Client,
  ) async throws -> Claim {
    try await Claim.ensureActive(intent: intent, deviceId: self.id, in: db)
  }
}
