import Dependencies
import Foundation
import PodcastRoute

extension GetAccountStatus: NoInputResolver {
  static func resolve(in ctx: PodcastApp.InstallContext) async throws -> Output {
    @Dependency(\.date.now) var now
    let parent = try await ctx.child.parent(in: ctx.db)
    let account = try await parent.billingAccountSnapshot(in: ctx.db, at: now)

    return Output(
      childId: ctx.child.id.rawValue,
      childName: ctx.child.name,
      subscription: account.amSubscriptionState(forInstall: ctx.install),
    )
  }
}

extension BillingAccountSnapshot {
  func amSubscriptionState(forInstall install: PodcastApp.Install) -> AmSubscriptionState {
    let amTrialEnd = install.createdAt + PodcastApp.Install.trialPeriod
    let amTrialActive = self.date < amTrialEnd

    switch self.planStatus {
    case .complimentary:
      return .complimentary
    case .full(.current(let renewalDate)), .light(.current(let renewalDate)):
      return .active(expiresAt: renewalDate)
    case .fullTrial(let trialExpiration, let substrate):
      if case .current(let renewalDate) = substrate?.status {
        return .active(expiresAt: renewalDate)
      }
      let legacyFloor = self.billingIdentity?.legacyAmIapPaidAt
        .map { $0 + PodcastApp.LegacyIap.grantWindow } ?? .distantPast
      // pick whichever live trial ends later, then floor to legacy if it outlasts
      if amTrialEnd > trialExpiration {
        return .amTrial(expiresAt: max(amTrialEnd, legacyFloor))
      }
      return .fullTrial(expiresAt: max(trialExpiration, legacyFloor))
    case .free, .fullTrialGrace, .full(.pastDue), .light(.pastDue):
      let legacyPaidAt = self.billingIdentity?.legacyAmIapPaidAt
      let legacyAccessEnd = legacyPaidAt.map { $0 + PodcastApp.LegacyIap.grantWindow }
      let legacyActive = legacyAccessEnd.map { self.date < $0 } ?? false

      if legacyActive, let legacyAccessEnd, amTrialActive, amTrialEnd > legacyAccessEnd {
        return .amTrial(expiresAt: amTrialEnd)
      }
      if legacyActive, let legacyAccessEnd {
        return .legacyGrandfathered(
          accessEndsAt: legacyAccessEnd,
          showMigrationNag: PodcastApp.LegacyIap.showMigrationNag(
            accessEndsAt: legacyAccessEnd,
            now: self.date,
          ),
          migrationUrl: nil,
        )
      }
      if amTrialActive {
        return .amTrial(expiresAt: amTrialEnd)
      }
      if let legacyPaidAt {
        return .legacyExpired(paidAt: legacyPaidAt, remediationUrl: nil)
      }
      return .unpaid(remediationUrl: nil)
    }
  }
}
