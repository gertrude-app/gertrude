import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL
import TaggedMoney

struct SubscriptionsOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var monthlyRevenue: Int
    var annualRevenue: Int
    var fullPlanCount: Int
    var fullPlanAnnualRevenue: Int
    var lightPlanCount: Int
    var lightPlanAnnualRevenue: Int
    var podcastAnnualRevenue: Int
    var trialingCount: Int
    var totalAccounts: Int
    var recentSignups: [RecentSignupOutput]
  }

  struct RecentSignupOutput: PairNestable {
    var date: Date
    var email: String
    var engagement: String
  }
}

extension SubscriptionsOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let data = try await AnalyticsQuery.shared.data()

    var fullPlanCount = 0
    var fullPlanAnnualCents = 0
    var lightPlanCount = 0
    var lightPlanAnnualCents = 0
    var trialingCount = 0

    var signups: [RecentSignupOutput] = []

    for parent in data.parents.values {
      if let sub = parent.subscription, sub.stripeStatus.isLive {
        switch sub.tier {
        case .light:
          lightPlanCount += 1
          lightPlanAnnualCents += 83 * 12
        case .full:
          if sub.stripeStatus == .trialing {
            trialingCount += 1
          } else if sub.stripeStatus.isPaying {
            fullPlanCount += 1
            fullPlanAnnualCents += (sub.isLegacyPrice ? 500 : 1000) * 12
          }
        }
      }

      let engagement = if parent.isActive
        || parent.hasCompletedSupervision
        || parent.hasConnectedFreeIOSDevice {
        "engaged"
      } else if parent.numComputerUsers > 0 || parent.hasIncompleteSupervision {
        "partial"
      } else {
        "none"
      }

      signups.append(.init(
        date: parent.createdAt,
        email: parent.email.rawValue,
        engagement: engagement,
      ))
    }

    let podcastSubscriptions = try await context.db.count(DistinctOriginalIDPaidCount.self)
    let podcastAnnualCents = podcastSubscriptions * 850

    let totalAnnualCents = fullPlanAnnualCents + lightPlanAnnualCents + podcastAnnualCents
    return .init(
      monthlyRevenue: totalAnnualCents / 100 / 12,
      annualRevenue: totalAnnualCents / 100,
      fullPlanCount: fullPlanCount,
      fullPlanAnnualRevenue: fullPlanAnnualCents / 100,
      lightPlanCount: lightPlanCount,
      lightPlanAnnualRevenue: lightPlanAnnualCents / 100,
      podcastAnnualRevenue: podcastAnnualCents / 100,
      trialingCount: trialingCount,
      totalAccounts: data.overview.allTimeSignups,
      recentSignups: signups,
    )
  }
}
