import DuetSQL
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
    let keychain = try await defaultKeychain(for: child, in: context.db)

    let existingKeys = try await Key.query()
      .where(.keychainId == keychain.id)
      .all(in: context.db)
    let existingSlugs = Set(existingKeys.compactMap { key -> String? in
      if case .skeleton(scope: .identifiedAppSlug(let slug)) = key.key { return slug }
      return nil
    })
    let existingBundleIds = Set(existingKeys.compactMap { key -> String? in
      if case .skeleton(scope: .bundleId(let id)) = key.key { return id }
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
    for bundleId in unique {
      if let appId = bundleIdToAppId[bundleId],
         let slug = appIdToSlug[appId] {
        let coveredByLegacyKey = slugBundleIds[slug, default: []]
          .contains(where: { existingBundleIds.contains($0) })
        if !coveredByLegacyKey,
           !existingSlugs.contains(slug),
           createdSlugs.insert(slug).inserted {
          try await context.db.create(Key(
            keychainId: keychain.id,
            key: .skeleton(scope: .identifiedAppSlug(slug)),
          ))
        }
      } else if !existingBundleIds.contains(bundleId) {
        try await context.db.create(Key(
          keychainId: keychain.id,
          key: .skeleton(scope: .bundleId(bundleId)),
        ))
      }
    }

    return .success
  }
}

private func defaultKeychain(
  for child: Child,
  in db: any DuetSQL.Client,
) async throws -> Keychain {
  let keychains = try await ChildKeychain.query()
    .where(.childId == child.id)
    .all(in: db)
  let keychainIds = keychains.map(\.keychainId)

  if !keychainIds.isEmpty {
    let all = try await Keychain.query()
      .where(.id |=| keychainIds)
      .orderBy(.createdAt, .asc)
      .all(in: db)
    let defaultName = "\(child.name)'s Keychain"
    return all.first { $0.name == defaultName } ?? all[0]
  }

  let keychain = try await db.create(Keychain(
    parentId: child.parentId,
    name: "\(child.name)'s Keychain",
    isPublic: false,
  ))
  try await db.create(ChildKeychain(childId: child.id, keychainId: keychain.id))
  return keychain
}
