import Dependencies
import DuetSQL
import IOSRoute

extension GetBlockGroups: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let groups = try await IOSApp.BlockGroup.query()
      .where(.optIn == false)
      .orderBy(.name, .asc)
      .all(in: ctx.db)

    with(dependency: \.logger)
      .info("GetBlockGroups: device=\(input.deviceId.lowercased), count=\(groups.count)")

    return groups.map {
      BlockGroupInfo(
        id: $0.id.rawValue,
        name: $0.name,
        shortDescription: $0.description,
        longDescription: $0.longDescription,
        imageSlug: $0.imageSlug,
      )
    }
  }
}
