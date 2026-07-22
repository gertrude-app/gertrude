import DuetSQL
import Gertie
import MacAppRoute

extension CreateOnboardingAppKeys: Resolver {
  static func resolve(
    with bundleIds: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    try await context.verifyOnboardingToken("CreateOnboardingAppKeys", "2d9623fc")

    let browsers = try await Browser.query().all(in: context.db)
    let browserBundleIds = Set(browsers.map(\.match).compactMap(\.bundleId))

    var seen = Set<String>()
    let unique = bundleIds.filter { bundleId in
      bundleId.contains(".")
        && !browserBundleIds.contains(bundleId)
        && seen.insert(bundleId).inserted
    }

    guard !unique.isEmpty else { return .success }

    let child = context.child
    let existing = try await child.unrestrictedMacApps(in: context.db)
    let existingSlugs = Set(existing.compactMap { app -> String? in
      if case .identifiedAppSlug(let slug) = app.scope { return slug }
      return nil
    })
    let existingBundleIds = Set(existing.compactMap { app -> String? in
      if case .bundleId(let id) = app.scope.normalized { return id }
      return nil
    })

    let matchedRows = try await AppBundleId.query()
      .where(.bundleId |=| Array(unique))
      .all(in: context.db)
    let bundleIdToAppId = Dictionary(
      matchedRows.map { ($0.bundleId, $0.identifiedAppId) },
      uniquingKeysWith: { first, _ in first },
    )
    let appIds = Set(bundleIdToAppId.values)
    let identifiedApps = appIds.isEmpty ? [] : try await IdentifiedApp.query()
      .where(.id |=| Array(appIds))
      .all(in: context.db)
    let appIdToSlug = Dictionary(
      identifiedApps.map { ($0.id, $0.slug) },
      uniquingKeysWith: { first, _ in first },
    )
    let allAppBundleIds = appIds.isEmpty ? [] : try await AppBundleId.query()
      .where(.identifiedAppId |=| Array(appIds))
      .all(in: context.db)
    var slugBundleIds: [String: Set<String>] = [:]
    for row in allAppBundleIds {
      if let slug = appIdToSlug[row.identifiedAppId] {
        slugBundleIds[slug, default: []].insert(row.bundleId)
      }
    }

    var createdSlugs = Set<String>()
    var newApps: [UnrestrictedMacApp] = []
    for bundleId in unique {
      if let appId = bundleIdToAppId[bundleId],
         let slug = appIdToSlug[appId] {
        let coveredByLegacyApp = slugBundleIds[slug, default: []]
          .contains(where: { existingBundleIds.contains($0) })
        if !coveredByLegacyApp,
           !existingSlugs.contains(slug),
           createdSlugs.insert(slug).inserted {
          newApps.append(UnrestrictedMacApp(
            scope: .identifiedAppSlug(slug),
            childId: child.id,
          ))
        }
      } else if !existingBundleIds.contains(bundleId) {
        newApps.append(UnrestrictedMacApp(
          scope: .bundleId(bundleId),
          childId: child.id,
        ))
      }
    }

    if !newApps.isEmpty {
      try await context.db.create(newApps)
    }

    return .success
  }
}
