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
      let billing = ParentBilling(identity: identity, stripeSubscription: subscription)
      let entitlement = billing.entitlement(at: now)
      let (planCase, subscriptionStatus) = self.planDisplay(entitlement, subscription)
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
    _ entitlement: Entitlement,
    _ subscription: StripeSubscription?,
  ) -> (planCase: String, subscriptionStatus: String) {
    let subStatus = subscription?.stripeStatus.rawValue
    switch entitlement {
    case .free:
      return ("free", subStatus ?? "free")
    case .light:
      return ("light", subStatus ?? "light")
    case .fullTrial:
      if let sub = subscription, sub.tier == .light {
        return ("light", "trialingFull")
      }
      return ("full", "trialing")
    case .fullTrialGrace:
      if let sub = subscription, sub.tier == .light {
        return ("light", "trialExpired")
      }
      return ("full", "trialExpired")
    case .full:
      return ("full", subStatus ?? "full")
    case .complimentary:
      return ("full", "complimentary")
    }
  }
}
