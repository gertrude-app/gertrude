import Dependencies
import DuetSQL
import Foundation
import Gertie
import MacAppRoute

extension CreateOnboardingAppKeys: Resolver {
  static func resolve(
    with bundleIds: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    let now = get(dependency: \.date.now)
    let tokenAge = now.timeIntervalSince(context.token.createdAt)
    if tokenAge > 60 * 30 {
      throw context.error(
        id: "2d9623fc",
        type: .unauthorized,
        debugMessage: "token too old for onboarding key creation",
      )
    }

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
    let existingBundleIds = Set(existingKeys.compactMap { key -> String? in
      if case .skeleton(scope: .bundleId(let id)) = key.key { return id }
      return nil
    })

    let newBundleIds = unique.filter { !existingBundleIds.contains($0) }
    guard !newBundleIds.isEmpty else { return .success }

    for bundleId in newBundleIds {
      try await context.db.create(Key(
        keychainId: keychain.id,
        key: .skeleton(scope: .bundleId(bundleId)),
      ))
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
