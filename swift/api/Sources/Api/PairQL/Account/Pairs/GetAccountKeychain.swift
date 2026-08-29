import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetAccountKeychain: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let keychainId: Keychain.Id
  }

  struct KeyRecord: PairNestable {
    let id: Key.Id
    let key: Gertie.Key
    let comment: String?
    let expiration: Date?
    let appName: String?
  }

  struct AppOption: PairNestable {
    let name: String
    let slug: String
    let bundleId: String?
    let iconHash: String?
  }

  struct Output: PairOutput {
    let id: Keychain.Id
    let name: String
    let description: String?
    let warning: String?
    let isPublic: Bool
    let keys: [KeyRecord]
    let apps: [AppOption]
  }
}

extension GetAccountKeychain: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let legacyOutput = try await GetAdminKeychain.resolve(
      with: input.keychainId,
      in: context.legacyContext,
    )
    let apps = try await IdentifiedApp.query()
      .orderBy(.name, .asc)
      .all(in: context.db)
    let appIds = apps.map(\.id)
    let appBundleIds = appIds.isEmpty
      ? []
      : try await AppBundleId.query()
      .where(.identifiedAppId |=| appIds)
      .all(in: context.db)
    let appNames = appNames(apps: apps, bundleIds: appBundleIds)
    let appOptions = try await appOptions(
      apps: apps,
      bundleIds: appBundleIds,
      in: context.db,
    )

    return .init(
      id: legacyOutput.summary.id,
      name: legacyOutput.summary.name,
      description: legacyOutput.summary.description,
      warning: legacyOutput.summary.warning,
      isPublic: legacyOutput.summary.isPublic,
      keys: legacyOutput.keys.map {
        .init(
          id: $0.id,
          key: $0.key,
          comment: $0.comment,
          expiration: $0.expiration,
          appName: appNames.name(for: $0.key),
        )
      },
      apps: appOptions,
    )
  }
}

private struct KeyAppNames {
  let bySlug: [String: String]
  let byBundleId: [String: String]

  func name(for key: Gertie.Key) -> String? {
    guard let scope = singleAppScope(for: key) else { return nil }
    switch scope {
    case .identifiedAppSlug(let slug):
      return self.bySlug[slug]
    case .bundleId(let bundleId):
      return self.byBundleId[bundleId.normalizedBundleId]
    }
  }
}

private func appNames(
  apps: [IdentifiedApp],
  bundleIds: [AppBundleId],
) -> KeyAppNames {
  let namesByAppId = Dictionary(
    apps.map { ($0.id, $0.name) },
    uniquingKeysWith: { first, _ in first },
  )

  return KeyAppNames(
    bySlug: Dictionary(
      apps.map { ($0.slug, $0.name) },
      uniquingKeysWith: { first, _ in first },
    ),
    byBundleId: Dictionary(
      bundleIds.compactMap { row in
        namesByAppId[row.identifiedAppId].map {
          (row.bundleId.normalizedBundleId, $0)
        }
      },
      uniquingKeysWith: { first, _ in first },
    ),
  )
}

private func appOptions(
  apps: [IdentifiedApp],
  bundleIds: [AppBundleId],
  in db: any DuetSQL.Client,
) async throws -> [GetAccountKeychain.AppOption] {
  let bundleIdsByAppId = Dictionary(grouping: bundleIds, by: \.identifiedAppId)
  let primaryBundleIds = Dictionary(uniqueKeysWithValues: apps.compactMap { app in
    preferredBundleId(in: bundleIdsByAppId[app.id] ?? []).map { (app.id, $0) }
  })
  let normalizedBundleIds = Array(Set(bundleIds.map(\.bundleId.normalizedBundleId)))
  let catalogedApps = normalizedBundleIds.isEmpty
    ? []
    : try await CatalogedApp.query()
    .where(.bundleId |=| normalizedBundleIds)
    .all(in: db)
  let iconHashesByBundleId = Dictionary(
    catalogedApps.compactMap { app in
      app.iconContentHash.map { (app.bundleId, $0) }
    },
    uniquingKeysWith: { first, _ in first },
  )

  return apps.map { app in
    let bundleId = primaryBundleIds[app.id]
    return .init(
      name: app.name,
      slug: app.slug,
      bundleId: bundleId,
      iconHash: preferredIconHash(
        in: bundleIdsByAppId[app.id] ?? [],
        iconHashesByBundleId: iconHashesByBundleId,
      ),
    )
  }
}

private func preferredIconHash(
  in bundleIds: [AppBundleId],
  iconHashesByBundleId: [String: String],
) -> String? {
  for bundleId in sortedBundleIds(bundleIds) {
    if let iconHash = iconHashesByBundleId[bundleId.bundleId.normalizedBundleId] {
      return iconHash
    }
  }
  return nil
}

private func preferredBundleId(in bundleIds: [AppBundleId]) -> String? {
  sortedBundleIds(bundleIds)
    .first
    .map(\.bundleId.normalizedBundleId)
}

private func sortedBundleIds(_ bundleIds: [AppBundleId]) -> [AppBundleId] {
  bundleIds.sorted { lhs, rhs in
    if lhs.count != rhs.count {
      return lhs.count > rhs.count
    }
    let lhsId = lhs.bundleId.normalizedBundleId
    let rhsId = rhs.bundleId.normalizedBundleId
    if lhsId.count != rhsId.count {
      return lhsId.count < rhsId.count
    }
    return lhsId < rhsId
  }
}

private func singleAppScope(for key: Gertie.Key) -> AppScope.Single? {
  switch key {
  case .skeleton(let scope):
    scope
  case .domain(_, .single(let scope)),
       .anySubdomain(_, .single(let scope)),
       .domainRegex(_, .single(let scope)),
       .path(_, .single(let scope)),
       .ipAddress(_, .single(let scope)):
    scope
  case .domain, .anySubdomain, .domainRegex, .path, .ipAddress:
    nil
  }
}
