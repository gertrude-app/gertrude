import Dependencies
import DuetSQL
import Gertie
import GertieIOS
import IOSRoute

extension BlockRules_v3: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let disabledGroupIds = input.disabledGroups.map { Postgres.Data.uuid($0) }
    let deviceId: IOSApp.Device.Id? = input.deviceId == .init(.zero) ? nil : .init(input.deviceId)
    let rules = try await IOSApp.BlockRule.query()
      .where(.or(
        .groupId != nil .&& .groupId |!=| disabledGroupIds,
        deviceId.map { .deviceId == $0 } ?? .never,
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)

    let blockRules = rules.map(\.rule)
    let rulesHash = iosBlockRulesHash(blockRules)
    with(dependency: \.logger).info(
      "BlockRules_v3: device=\(input.deviceId), v=\(input.appVersion), rules=\(blockRules.count), hash=\(rulesHash)",
    )

    if let deviceId,
       let device = try? await ctx.db.find(deviceId) as IOSApp.Device {
      _ = try? await ctx.db.create(IOSEvent(
        eventId: "06329f27",
        kind: .checkin,
        detail: "rules=\(blockRules.count), hash=\(rulesHash)",
        deviceId: deviceId,
        modelIdentifier: device.modelIdentifier,
        iosVersion: device.iosVersion,
      ))
    }

    return blockRules
  }
}
