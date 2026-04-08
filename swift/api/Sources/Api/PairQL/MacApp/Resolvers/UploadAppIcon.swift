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
      app.icon = input.iconData
      app.iconContentHash = input.iconContentHash
      try await context.db.update(app)
    } catch {
      await get(dependency: \.slack).error(
        "Failed to upload app icon for `\(input.bundleId)`: \(error)",
      )
    }
    return .success
  }
}
