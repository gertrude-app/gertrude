import DuetSQL
import Gertie
import PairQL
import Vapor

struct PromoteApp: Pair {
  static let auth: ClientAuth = .superAdmin

  struct NewApp: PairNestable {
    let name: String
    let slug: String
    let categoryId: AppCategory.Id?
    let launchable: Bool
  }

  struct Input: PairInput {
    let bundleId: String
    let newApp: NewApp?
    let existingAppId: IdentifiedApp.Id?
  }

  struct Output: PairOutput {
    let identifiedAppId: IdentifiedApp.Id
    let name: String
    let upgradedKeyCount: Int
  }
}

struct BundleIdScopedKey: CustomQueryable {
  static func query(bindings: [Postgres.Data]) -> SQL.Statement {
    let k = "\"\(Key.columnName(.key))\""
    var stmt = SQL.Statement("""
    SELECT \(Key.columnName(.id)), \(Key.columnName(.keychainId)), \(k)::text AS key_json
    FROM \(table: Key.self)
    WHERE \(Key.columnName(.deletedAt)) IS NULL AND (
      \(k)->>'type' = 'skeleton'
        AND \(k)->'scope'->>'type' = 'bundleId'
        AND \(k)->'scope'->>'bundleId' = \(" ")
    """)
    stmt.components.append(.binding(bindings[0]))
    stmt.components.append(.sql("""
      OR \(k)->>'type' != 'skeleton'
        AND \(k)->'scope'->'single'->>'type' = 'bundleId'
        AND \(k)->'scope'->'single'->>'bundleId' = \(" ")
    """))
    stmt.components.append(.binding(bindings[0]))
    stmt.components.append(.sql(")"))
    return stmt
  }

  var id: Key.Id
  var keychainId: Keychain.Id
  var keyJson: String
}

// resolver

extension PromoteApp: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    guard (input.newApp == nil) != (input.existingAppId == nil) else {
      throw context.error(
        "683d5d46",
        .serverError,
        "Exactly one of newApp or existingAppId must be provided",
      )
    }

    let identifiedAppId: IdentifiedApp.Id
    let name: String
    let slug: String

    if let newApp = input.newApp {
      let existingSlug = try? await IdentifiedApp.query()
        .where(.slug == newApp.slug)
        .first(in: context.db)
      if existingSlug != nil {
        throw context.error(
          "158390d2",
          .serverError,
          user: "Slug '\(newApp.slug)' is already in use",
        )
      }
      let created = try await context.db.create(IdentifiedApp(
        categoryId: newApp.categoryId,
        name: newApp.name,
        slug: newApp.slug,
        launchable: newApp.launchable,
      ))
      identifiedAppId = created.id
      name = newApp.name
      slug = newApp.slug
    } else {
      guard let existingId = input.existingAppId else { throw Abort(.badRequest) }
      let existing = try await context.db.find(IdentifiedApp.self, byId: existingId.rawValue)
      identifiedAppId = existing.id
      name = existing.name
      slug = existing.slug
    }

    let unidentifiedApp = try? await UnidentifiedApp.query()
      .where(.bundleId == input.bundleId)
      .first(in: context.db)

    try await context.db.create(AppBundleId(
      identifiedAppId: identifiedAppId,
      bundleId: input.bundleId,
      count: unidentifiedApp?.count ?? 0,
    ))

    if unidentifiedApp != nil {
      try await context.db.delete(
        UnidentifiedApp.self,
        where: .bundleId == input.bundleId,
      )
    }

    let upgradedKeyCount = try await upgradeExistingKeys(
      bundleId: input.bundleId,
      slug: slug,
      in: context,
    )

    return .init(
      identifiedAppId: identifiedAppId,
      name: name,
      upgradedKeyCount: upgradedKeyCount,
    )
  }
}

private func upgradeExistingKeys(
  bundleId: String,
  slug: String,
  in context: Context,
) async throws -> Int {
  let browsers = try await Browser.query().all(in: context.db)
  let browserBundleIds = Set(browsers.map(\.match).compactMap(\.bundleId))
  if browserBundleIds.contains(bundleId) {
    return 0
  }

  let candidates = try await context.db.customQuery(
    BundleIdScopedKey.self,
    withBindings: [.string(bundleId)],
  )

  if candidates.isEmpty {
    return 0
  }

  let keychainIds = Set(candidates.map(\.keychainId))
  var keychainKeys: [Keychain.Id: [Gertie.Key]] = [:]
  for keychainId in keychainIds {
    let keys = try await Key.query()
      .where(.keychainId == keychainId)
      .all(in: context.db)
    keychainKeys[keychainId] = keys.map(\.key)
  }

  var upgradedCount = 0
  for candidate in candidates {
    var key = try await context.db.find(Key.self, byId: candidate.id.rawValue)
    let upgraded = key.key.withUpgradedScope(toSlug: slug)
    let existingKeys = keychainKeys[candidate.keychainId] ?? []
    if existingKeys.contains(upgraded) {
      try await context.db.delete(Key.self, byId: key.id.rawValue)
    } else {
      key.key = upgraded
      key.updatedAt = Date()
      try await context.db.update(key)
    }
    upgradedCount += 1
  }

  return upgradedCount
}

extension Gertie.Key {
  func withUpgradedScope(toSlug slug: String) -> Gertie.Key {
    switch self {
    case .skeleton:
      .skeleton(scope: .identifiedAppSlug(slug))
    case .domain(let domain, _):
      .domain(domain: domain, scope: .single(.identifiedAppSlug(slug)))
    case .anySubdomain(let domain, _):
      .anySubdomain(domain: domain, scope: .single(.identifiedAppSlug(slug)))
    case .domainRegex(let pattern, _):
      .domainRegex(pattern: pattern, scope: .single(.identifiedAppSlug(slug)))
    case .path(let path, _):
      .path(path: path, scope: .single(.identifiedAppSlug(slug)))
    case .ipAddress(let ip, _):
      .ipAddress(ipAddress: ip, scope: .single(.identifiedAppSlug(slug)))
    }
  }
}
