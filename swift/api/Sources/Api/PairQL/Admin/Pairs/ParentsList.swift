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
    let subscriptions = try await Subscription.query()
      .where(.parentId |=| parentIds)
      .all(in: context.db)
    let subscriptionMap = Dictionary(uniqueKeysWithValues: subscriptions.map { ($0.parentId, $0) })

    let analyticsData = try await AnalyticsQuery.shared.data()

    let summaries = parents.map { parent -> ParentSummary in
      let parentData = analyticsData.parents[parent.id]
      let subscription = subscriptionMap[parent.id]
      let plan = Plan(subscription: subscription)
      let (planCase, subscriptionStatus) = self.planDisplay(plan, subscription)
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
    _ plan: Plan,
    _ subscription: Subscription?,
  ) -> (planCase: String, subscriptionStatus: String) {
    switch plan {
    case .free:
      ("free", "free")
    case .light(.paid):
      ("light", "paid")
    case .light(.overdue):
      ("light", "overdue")
    case .full(.complimentary):
      ("full", "complimentary")
    case .full(.trialing(let kind, _)):
      switch kind {
      case .full:
        ("full", "trialing")
      case .fromLight:
        ("light", "trialingFull")
      }
    case .full(.trialExpired(let kind)):
      switch kind {
      case .full:
        ("full", "trialExpired")
      case .fromLight:
        ("light", "trialExpired")
      }
    case .full(.paid):
      ("full", "paid")
    case .full(.overdue):
      ("full", "overdue")
    }
  }
}
