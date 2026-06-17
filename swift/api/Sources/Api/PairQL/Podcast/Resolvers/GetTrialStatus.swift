import Dependencies
import DuetSQL
import Foundation
import PodcastRoute

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

    if let child = try await device.child(in: ctx.db) {
      let token = try await ctx.db.findOrCreate(
        PodcastApp.Token(installId: install.id),
        conflictOn: [.installId],
      )

      let parent = try await child.parent(in: ctx.db)
      let account = try await parent.billingAccountSnapshot(in: ctx.db, at: now)

      return .connected(
        token: token.value.rawValue,
        childId: child.id.rawValue,
        childName: child.name,
        subscription: account.amSubscriptionState(forInstall: install),
      )
    }

    let legacy = try await ctx.db.customQuery(
      EarliestGrandfatherableLegacyIapForDevice.self,
      withBindings: [.uuid(input.deviceId)],
    )

    if let paidAt = legacy.first?.createdAt,
       now < paidAt + PodcastApp.LegacyIap.grantWindow {
      let accessEndsAt = paidAt + PodcastApp.LegacyIap.grantWindow
      return .legacyGrandfathered(
        accessEndsAt: accessEndsAt,
        showMigrationNag: PodcastApp.LegacyIap.showMigrationNag(
          accessEndsAt: accessEndsAt,
          now: now,
        ),
        migrationUrl: nil,
      )
    }

    let trialEnd = install.createdAt + PodcastApp.Install.trialPeriod
    if trialEnd > now {
      return .trial(expiresAt: trialEnd)
    }

    return .trialExpired(since: trialEnd)
  }
}
