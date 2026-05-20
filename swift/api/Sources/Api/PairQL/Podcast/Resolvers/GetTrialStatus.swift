import Dependencies
import DuetSQL
import Foundation
import PodcastRoute
import Vapor

extension GetTrialStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let install = try await PodcastApp.Install.ensureExists(
      deviceId: IOSDevice.Id(input.deviceId),
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )
    let device = try await install.device(in: ctx.db)
    let now = get(dependency: \.date.now)

    if device.claimedAt != nil {
      guard let child = try await device.child(in: ctx.db) else {
        logIOSUnusual("c1f4a9d2", "podcast device claimedAt w/ no child, device=\(device.id)")
        throw Abort(.internalServerError)
      }

      let token: PodcastApp.Token = if let existing = try? await PodcastApp.Token.query()
        .where(.installId == install.id)
        .first(in: ctx.db) {
        existing
      } else {
        try await ctx.db.create(PodcastApp.Token(installId: install.id))
      }

      let parent = try await child.parent(in: ctx.db)
      let account = try await parent.billingAccountSnapshot(in: ctx.db, at: now)

      return .claimed(
        token: token.value.rawValue,
        childId: child.id.rawValue,
        childName: child.name,
        subscription: account.amSubscriptionState,
      )
    }

    let legacy = try await ctx.db.customQuery(
      EarliestGrandfatherableLegacyIapForDevice.self,
      withBindings: [.uuid(input.deviceId)],
    )

    if let paidAt = legacy.first?.createdAt, now < paidAt + .days(365) {
      return .legacyGrandfathered(paidAt: paidAt, expiresAt: paidAt + .days(365))
    }

    let trialEnd = install.createdAt + .days(30)
    if trialEnd > now {
      let days = Int(ceil(trialEnd.timeIntervalSince(now) / 86400))
      return .trial(daysRemaining: max(days, 1))
    }

    return .trialExpired
  }
}
