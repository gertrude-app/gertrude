import Dependencies
import DuetSQL
import MacAppRoute

extension UploadAppIcon: Resolver {
  static func resolve(
    with input: Input,
    in context: MacApp.ChildContext,
  ) async throws -> Output {
    do {
      var app = try await CatalogedApp.query()
        .where(.bundleId == input.bundleId)
        .first(in: context.db)
      let preferredSourceAppVersion = self.preferredAppVersion(
        existing: app.iconSourceAppVersion,
        candidate: input.appVersion,
      )
      if app.iconContentHash == input.iconContentHash,
         app.iconUploadedAt != nil,
         app.icon != nil,
         preferredSourceAppVersion == app.iconSourceAppVersion {
        return .success
      }
      let isNewContent = app.iconContentHash != input.iconContentHash || app.icon == nil
      app.icon = input.iconData
      app.iconContentHash = input.iconContentHash
      if isNewContent || app.iconUploadedAt == nil {
        app.iconUploadedAt = get(dependency: \.date.now)
      }
      app.iconSourceAppVersion = preferredSourceAppVersion
      try await context.db.update(app)
    } catch {
      await get(dependency: \.slack).error(
        "Failed to upload app icon for `\(input.bundleId)`: \(error)",
      )
    }
    return .success
  }

  static func preferredAppVersion(existing: String?, candidate: String?) -> String? {
    guard let candidate,
          !candidate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      return existing
    }
    guard let comparison = LooseAppVersion.compare(candidate, existing) else {
      return existing
    }
    switch comparison {
    case .orderedAscending:
      return existing
    case .orderedSame, .orderedDescending:
      return candidate
    }
  }
}
