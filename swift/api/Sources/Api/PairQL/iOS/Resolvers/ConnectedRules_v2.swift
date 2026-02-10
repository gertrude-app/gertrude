import DuetSQL
import IOSRoute

extension ConnectedRules_v2: Resolver {
  static func resolve(with input: Input, in ctx: IOSApp.ChildContext) async throws -> Output {
    let groups = try await ctx.device.blockGroups(in: ctx.db)
    let blockRules = try await IOSApp.BlockRule.query()
      .where(.or(
        .groupId |=| groups.map { .uuid($0.id) },
        .deviceId == ctx.device.id,
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)
      .map(\.rule)

    var device = ctx.device
    if device.shouldUpdateModelIdentifier(to: input.modelIdentifier) {
      device.modelIdentifier = input.modelIdentifier
    }
    device.appVersion = input.appVersion
    device.iosVersion = input.iosVersion
    if device != ctx.device {
      try await ctx.db.update(device)
    }

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    return .init(
      blockRules: blockRules,
      // NB: for now always nil, for 1.7.0 launch, safety w/ supervised users,
      // but we can turn it on later, and the app will set it, if we decide it's correct
      webPolicy: nil,
    )
  }
}
