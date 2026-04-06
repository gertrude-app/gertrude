import DuetSQL
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
  }
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
    } else {
      guard let existingId = input.existingAppId else { throw Abort(.badRequest) }
      let existing = try await context.db.find(IdentifiedApp.self, byId: existingId.rawValue)
      identifiedAppId = existing.id
      name = existing.name
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

    return .init(identifiedAppId: identifiedAppId, name: name)
  }
}
