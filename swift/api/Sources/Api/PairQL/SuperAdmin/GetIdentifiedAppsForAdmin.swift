import DuetSQL
import PairQL

struct GetIdentifiedAppsForAdmin: Pair {
  static let auth: ClientAuth = .superAdmin

  struct App: PairOutput {
    struct BundleId: PairNestable {
      let id: AppBundleId.Id
      let bundleId: String
    }

    struct Category: PairNestable {
      let id: AppCategory.Id
      let name: String
      let slug: String
    }

    let id: IdentifiedApp.Id
    let name: String
    let slug: String
    let launchable: Bool
    var bundleIds: [BundleId]
    let category: Category?
  }

  typealias Output = [App]
}

// resolver

extension GetIdentifiedAppsForAdmin: NoInputResolver {
  static func resolve(in context: Context) async throws -> Output {
    async let apps = try await context.db.select(all: IdentifiedApp.self)
    async let bundleIds = try await context.db.select(all: AppBundleId.self)
    async let categories = try await context.db.select(all: AppCategory.self)

    let categoryMap: [AppCategory.Id: App.Category] = try await (categories)
      .reduce(into: [:]) { $0[$1.id] = .init(id: $1.id, name: $1.name, slug: $1.slug) }

    var appMap: [IdentifiedApp.Id: App] = try await (apps)
      .reduce(into: [:]) { map, identifiedApp in
        map[identifiedApp.id] = .init(
          id: identifiedApp.id,
          name: identifiedApp.name,
          slug: identifiedApp.slug,
          launchable: identifiedApp.launchable,
          bundleIds: [],
          category: identifiedApp.categoryId.flatMap { categoryMap[$0] },
        )
      }

    for bundleId in try await bundleIds {
      appMap[bundleId.identifiedAppId]?.bundleIds.append(
        .init(id: bundleId.id, bundleId: bundleId.bundleId),
      )
    }

    return Array(appMap.values).sorted { $0.name < $1.name }
  }
}
