import DuetSQL
import MacAppRoute

extension CreateOnboardingBlockedApps: Resolver {
  static func resolve(
    with bundleIds: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    var seen = Set<String>()
    let unique = bundleIds.filter { bundleId in
      bundleId.contains(".") && seen.insert(bundleId).inserted
    }

    guard !unique.isEmpty else { return .success }

    let child = context.child
    let existing = try await BlockedMacApp.query()
      .where(.childId == child.id)
      .all(in: context.db)
    let existingIds = Set(existing.map(\.identifier))

    let newBundleIds = unique.filter { !existingIds.contains($0) }
    guard !newBundleIds.isEmpty else { return .success }

    let models = newBundleIds.map { BlockedMacApp(identifier: $0, childId: child.id) }
    try await context.db.create(models)

    return .success
  }
}
