import DuetSQL
import MusicRoute
import Vapor

extension GetMusicAppStatus_v3: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let install = try await MusicApp.Install.ensureExists(
      deviceId: IOSDevice.Id(input.deviceId),
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )
    let device = try await install.device(in: ctx.db)

    let musicClaim = try await Claim.find(device.id, intent: .music, in: ctx.db)
    if let musicClaim, musicClaim.claimedAt != nil {
      guard let childId = musicClaim.childId else {
        logIOSUnusual("9a6d1f2c", "music claim claimedAt w/ no child, device=\(device.id)")
        throw Abort(.internalServerError)
      }
      let child = try await ctx.db.find(childId)

      let token = try await ctx.db.findOrCreate(
        MusicApp.Token(installId: install.id),
        conflictOn: [.installId],
      )
      let entitlement = try await musicSubscriptionState(for: token, child: child, in: ctx)

      return .claimed(
        token: token.value.rawValue,
        childId: child.id.rawValue,
        childName: child.name,
        entitlement: entitlement,
      )
    }

    if let child = try await device.child(in: ctx.db) {
      let claim = try await device.ensureClaim(intent: .music, in: ctx.db)
      try await completeClaim(claim, for: child, in: ctx.db)
      let token = try await ctx.db.findOrCreate(
        MusicApp.Token(installId: install.id),
        conflictOn: [.installId],
      )
      let entitlement = try await musicSubscriptionState(for: token, child: child, in: ctx)

      return .claimed(
        token: token.value.rawValue,
        childId: child.id.rawValue,
        childName: child.name,
        entitlement: entitlement,
      )
    }

    let claim = try await device.ensureClaim(intent: .music, in: ctx.db)
    return .unclaimed(code: claim.code, expiresAt: claim.expiresAt)
  }
}

extension BillingAccountSnapshot {
  func hasMusicAccess(for token: MusicApp.Token) -> Bool {
    self.can(.useGertrudeMusic)
      || token.hasActiveTrial(at: self.date)
  }

  func hasMusicAccess(forAny tokens: [MusicApp.Token]) -> Bool {
    self.can(.useGertrudeMusic)
      || tokens.contains { $0.hasActiveTrial(at: self.date) }
  }

  func musicSubscriptionState(for token: MusicApp.Token) -> MusicSubscriptionState {
    if self.can(.useGertrudeMusic) {
      return .active
    }
    if self.hasMusicAccess(for: token) {
      return .trial(expiresAt: token.trialExpiresAt)
    }
    return .unavailable
  }
}

private func musicSubscriptionState(
  for token: MusicApp.Token,
  child: Child,
  in ctx: Context,
) async throws -> MusicSubscriptionState {
  let parent = try await child.parent(in: ctx.db)
  let account = try await parent.billingAccountSnapshot(
    in: ctx.db,
    at: get(dependency: \.date.now),
  )
  return account.musicSubscriptionState(for: token)
}
