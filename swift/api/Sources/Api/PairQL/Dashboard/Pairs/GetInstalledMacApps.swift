import DuetSQL
import Foundation
import PairQL

struct GetInstalledMacApps: Pair {
  static let auth: ClientAuth = .parent

  struct App: PairOutput {
    var bundleId: String
    var name: String
    var category: String?
    var identifiedAppSlug: String?
    var iconHash: String?
  }

  typealias Input = Api.Child.Id
  typealias Output = [App]
}

// resolver

extension GetInstalledMacApps: Resolver {
  static func resolve(
    with id: Api.Child.Id,
    in context: ParentContext,
  ) async throws -> Output {
    let child = try await context.verifiedChild(from: id)
    let installed = try await InstalledMacApp.query()
      .where(.childId == child.id)
      .all(in: context.db)

    let macAppIds = Array(Set(installed.map(\.macAppId)))
    guard !macAppIds.isEmpty else { return [] }

    async let catalogedAppsAsync = CatalogedApp.query()
      .where(.id |=| macAppIds)
      .all(in: context.db)

    let catalogedApps = try await catalogedAppsAsync.uniqued(on: \.bundleId)
    let bundleIds = catalogedApps.map(\.bundleId)

    async let appBundleIdsAsync = AppBundleId.query()
      .where(.bundleId |=| bundleIds)
      .all(in: context.db)

    let appBundleIds = try await appBundleIdsAsync
    let identifiedAppIds = Array(Set(appBundleIds.map(\.identifiedAppId)))
    let identifiedApps = identifiedAppIds.isEmpty ? [] : try await IdentifiedApp.query()
      .where(.id |=| identifiedAppIds)
      .all(in: context.db)

    let slugByAppId: [IdentifiedApp.Id: String] = identifiedApps
      .reduce(into: [:]) { $0[$1.id] = $1.slug }
    let slugByBundleId: [String: String] = appBundleIds
      .reduce(into: [:]) { dict, item in
        if let slug = slugByAppId[item.identifiedAppId] {
          dict[item.bundleId] = slug
        }
      }

    return catalogedApps
      .sorted { $0.name.lowercased() < $1.name.lowercased() }
      .map { app in
        .init(
          bundleId: app.bundleId,
          name: app.name,
          category: app.category,
          identifiedAppSlug: slugByBundleId[app.bundleId],
          iconHash: app.iconContentHash,
        )
      }
  }
}
