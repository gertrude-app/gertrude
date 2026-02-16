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
      let planCase = switch plan {
      case .free: "free"
      case .light: "light"
      case .full: "full"
      }
      return ParentSummary(
        id: parent.id,
        email: parent.email.rawValue,
        createdAt: parent.createdAt,
        planCase: planCase,
        subscriptionStatus: self.subscriptionStatusString(for: subscription),
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

  private static func subscriptionStatusString(for subscription: Subscription?) -> String {
    guard let subscription else {
      return "free"
    }
    guard let billingStatus = subscription.billingStatus else {
      return "complimentary"
    }
    switch billingStatus {
    case .trialing:
      return "trialing"
    case .trialExpiringSoon:
      return "trialExpiringSoon"
    case .trialExpired:
      return "trialExpired"
    case .paid:
      return "paid"
    case .overdue:
      return "overdue"
    case .unpaid, .cancelled:
      return "unpaid"
    }
  }
}
