import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct ParentsList: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var page: Int
    var pageSize: Int?
  }

  struct Output: PairOutput {
    var parents: [ParentSummary]
    var totalCount: Int
    var page: Int
    var totalPages: Int
  }

  struct ParentSummary: PairNestable {
    var id: Parent.Id
    var email: String
    var createdAt: Date
    var planCase: String
    var subscriptionStatus: String
    var numChildren: Int
    var macDeviceCount: Int
    var iosDeviceCount: Int
    var macAppStatus: String
  }
}

extension ParentsList: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let pageSize = input.pageSize ?? 30
    let page = max(1, input.page)
    let offset = (page - 1) * pageSize

    let baseQuery = Parent.query()
      .where(.not(.like(.email, "%.smoke-test-%")))
      .where(.not(.like(.email, "e2e-user-%")))
      .where(.emailVerifiedAt != nil)

    let totalCount = try await baseQuery.count(in: context.db)
    let totalPages = max(1, Int(ceil(Double(totalCount) / Double(pageSize))))

    let parents = try await baseQuery
      .orderBy(.createdAt, .desc)
      .limit(pageSize)
      .offset(offset)
      .all(in: context.db)

    // TODO: shouldn't have to do this, shared query should handle
    // @see https://github.com/gertrude-app/gertrude/issues/478
    let parentIds = parents.map(\.id)
    let subscriptions = try await StripeSubscription.query()
      .where(.parentId |=| parentIds)
      .all(in: context.db)
    let subscriptionMap = Dictionary(uniqueKeysWithValues: subscriptions.map { ($0.parentId, $0) })

    let identityMap = try await BillingIdentity.query()
      .where(.parentId |=| parentIds)
      .all(in: context.db)
      .reduce(into: [Parent.Id: BillingIdentity]()) { $0[$1.parentId] = $1 }

    let analyticsData = try await AnalyticsQuery.shared.data()
    @Dependency(\.date.now) var now

    let summaries = parents.map { parent -> ParentSummary in
      let parentData = analyticsData.parents[parent.id]
      let identity = identityMap[parent.id] ?? BillingIdentity(parentId: parent.id)
      let subscription = subscriptionMap[parent.id]
      let billing = BillingAccountSnapshot(
        billingIdentity: identity,
        stripeSubscription: subscription,
        date: now,
      )
      let (planCase, subscriptionStatus) = self.planDisplay(billing.planStatus)
      return ParentSummary(
        id: parent.id,
        email: parent.email.rawValue,
        createdAt: parent.createdAt,
        planCase: planCase,
        subscriptionStatus: subscriptionStatus,
        numChildren: parentData?.numChildren ?? 0,
        macDeviceCount: parentData?.numComputerUsers ?? 0,
        iosDeviceCount: parentData?.numIOSDevices ?? 0,
        macAppStatus: parentData?.status.rawValue ?? "unknown",
      )
    }

    return .init(
      parents: summaries,
      totalCount: totalCount,
      page: page,
      totalPages: totalPages,
    )
  }

  private static func planDisplay(
    _ planStatus: PlanStatus,
  ) -> (planCase: String, subscriptionStatus: String) {
    switch planStatus {
    case .free:
      return ("free", "free")
    case .light(.current):
      return ("light", "paid")
    case .light(.pastDue):
      return ("light", "overdue")
    case .medium(.current):
      return ("medium", "paid")
    case .medium(.pastDue):
      return ("medium", "overdue")
    case .fullTrial(_, let substrate):
      if let substrate, substrate.tier != .full {
        if case .pastDue = substrate.status {
          return (substrate.tier.rawValue, "overdue")
        }
        return (substrate.tier.rawValue, "trialingFull")
      }
      return ("full", "trialing")
    case .fullTrialGrace(_, let substrate):
      if let substrate, substrate.tier != .full {
        if case .pastDue = substrate.status {
          return (substrate.tier.rawValue, "overdue")
        }
        return (substrate.tier.rawValue, "trialExpired")
      }
      return ("full", "trialExpired")
    case .full(.current):
      return ("full", "paid")
    case .full(.pastDue):
      return ("full", "overdue")
    case .complimentary:
      return ("full", "complimentary")
    }
  }
}
