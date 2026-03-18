import DuetSQL
import PairQL

struct GetUnidentifiedApps: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    let threshold: Int
    let limit: Int
  }

  struct App: PairNestable {
    let id: UnidentifiedApp.Id
    let bundleId: String
    let bundleName: String?
    let localizedName: String?
    let count: Int
    let launchable: Bool?
  }

  struct Output: PairOutput {
    let apps: [App]
    let totalAboveThreshold: Int
  }
}

// resolver

extension GetUnidentifiedApps: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let baseQuery = UnidentifiedApp.query().where(.count >= .int(input.threshold))
    let totalAboveThreshold = try await baseQuery.count(in: context.db)
    let effectiveLimit = input.limit > 0 ? input.limit : max(totalAboveThreshold, 20)
    let rows = try await baseQuery
      .orderBy(.count, .desc)
      .limit(effectiveLimit)
      .all(in: context.db)
    return .init(
      apps: rows.map { .init(
        id: $0.id,
        bundleId: $0.bundleId,
        bundleName: $0.bundleName,
        localizedName: $0.localizedName,
        count: $0.count,
        launchable: $0.launchable,
      ) },
      totalAboveThreshold: totalAboveThreshold,
    )
  }
}
