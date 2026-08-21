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

  struct Output: PairOutput {
    let id: Keychain.Id
    let name: String
    let description: String?
    let warning: String?
    let isPublic: Bool
    let keys: [KeyRecord]
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
    let appNames = try await appNames(for: legacyOutput.keys.map(\.key), in: context.db)

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
      return self.byBundleId[normalizedBundleId(bundleId)]
    }
  }
}

private func appNames(
  for keys: [Gertie.Key],
  in db: any DuetSQL.Client,
) async throws -> KeyAppNames {
  let scopes = keys.compactMap(singleAppScope)
  let slugs = Set(scopes.compactMap { scope -> String? in
    guard case .identifiedAppSlug(let slug) = scope else { return nil }
    return slug
  })
  let bundleIds = Set(scopes.compactMap { scope -> String? in
    guard case .bundleId(let bundleId) = scope else { return nil }
    return normalizedBundleId(bundleId)
  })

  let slugApps = slugs.isEmpty
    ? []
    : try await IdentifiedApp.query()
    .where(.slug |=| Array(slugs))
    .all(in: db)
  let bundleCandidates = bundleIds.flatMap { [$0, ".\($0)"] }
  let bundleRows = bundleCandidates.isEmpty
    ? []
    : try await AppBundleId.query()
    .where(.bundleId |=| bundleCandidates)
    .all(in: db)
  let bundleAppIds = Set(bundleRows.map(\.identifiedAppId))
  let bundleApps = bundleAppIds.isEmpty
    ? []
    : try await IdentifiedApp.query()
    .where(.id |=| Array(bundleAppIds))
    .all(in: db)
  let namesByAppId = Dictionary(
    bundleApps.map { ($0.id, $0.name) },
    uniquingKeysWith: { first, _ in first },
  )

  return KeyAppNames(
    bySlug: Dictionary(
      slugApps.map { ($0.slug, $0.name) },
      uniquingKeysWith: { first, _ in first },
    ),
    byBundleId: Dictionary(
      bundleRows.compactMap { row in
        namesByAppId[row.identifiedAppId].map {
          (normalizedBundleId(row.bundleId), $0)
        }
      },
      uniquingKeysWith: { first, _ in first },
    ),
  )
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

private func normalizedBundleId(_ bundleId: String) -> String {
  bundleId.first == "." ? String(bundleId.dropFirst()) : bundleId
}
