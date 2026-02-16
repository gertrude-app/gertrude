import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct MacOverview: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Output: PairOutput {
    var activeParents: Int
    var childrenOfActiveParents: Int
    var allTimeChildren: Int
    var allTimeAppInstallations: Int
    var onboardedParents: Int
    var noActionParents: Int
  }
}

extension MacOverview: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    let data = try await AnalyticsQuery.shared.data()
    var onboarded = 0
    var noAction = 0
    for parent in data.parents.values {
      switch parent.status {
      case .onboarded: onboarded += 1
      case .noAction: noAction += 1
      case .active: break
      }
    }
    return .init(
      activeParents: data.overview.activeParents,
      childrenOfActiveParents: data.overview.childrenOfActiveParents,
      allTimeChildren: data.overview.allTimeChildren,
      allTimeAppInstallations: data.overview.allTimeAppInstallations,
      onboardedParents: onboarded,
      noActionParents: noAction,
    )
  }
}
