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
      subscription: account.amSubscriptionState,
    )
  }
}

extension BillingAccountSnapshot {
  var amSubscriptionState: AmSubscriptionState {
    switch self.planStatus {
    case .complimentary:
      .active(expiresAt: nil)
    case .full(.current(let renewalDate)), .light(.current(let renewalDate)):
      .active(expiresAt: renewalDate)
    case .fullTrial(let trialExpiration):
      if let iapPaidAt = self.billingIdentity?.legacyAmIapPaidAt,
         iapPaidAt + .days(365) > trialExpiration {
        .active(expiresAt: iapPaidAt + .days(365))
      } else {
        .active(expiresAt: trialExpiration)
      }
    case .free, .fullTrialGrace, .full(.pastDue), .light(.pastDue):
      if let iapPaidAt = self.billingIdentity?.legacyAmIapPaidAt {
        self.date < iapPaidAt + .days(365)
          ? .legacyGrandfathered(
            paidAt: iapPaidAt,
            expiresAt: iapPaidAt + .days(365),
            remediationUrl: nil,
          )
          : .legacyExpired(paidAt: iapPaidAt, remediationUrl: nil)
      } else {
        .unpaid(remediationUrl: nil)
      }
    }
  }
}
