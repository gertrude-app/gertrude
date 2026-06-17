import Dependencies
import DuetSQL
import Gertie
import GertieBlocker
import IOSRoute

extension BlockRules_v3: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    var disabledGroupIds = input.disabledGroups.map { Postgres.Data.uuid($0) }
    let deviceId: IOSDevice.Id? = input.deviceId == .init(.zero) ? nil : .init(input.deviceId)
    let (device, optInExclusions) = try await optInBlockGroupExclusions(deviceId, in: ctx.db)
    disabledGroupIds.append(contentsOf: optInExclusions)

    let rules = try await BlockerApp.BlockRule.query()
      .where(.or(
        .groupId != nil .&& .groupId |!=| disabledGroupIds,
        deviceId.map { .deviceId == $0 } ?? .never,
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)

    let blockRules = rules.map(\.rule).frozenEncodable
    let rulesHash = iosBlockRulesHash(blockRules)
    with(dependency: \.logger).info(
      "BlockRules_v3: device=\(input.deviceId), v=\(input.appVersion), rules=\(blockRules.count), hash=\(rulesHash)",
    )

    if let device {
      _ = try? await ctx.db.create(IOSEvent(
        eventId: "06329f27",
        kind: .checkin,
        detail: "rules=\(blockRules.count), hash=\(rulesHash)",
        deviceId: device.id,
        modelIdentifier: device.modelIdentifier,
        iosVersion: device.iosVersion,
      ))
    }

    return blockRules
  }
}

// on 4/16 in response to a user reporting that whatsapp blocking blocked calls,
// which i had also experienced personally, i weakened the rules. however,
// more people complained about the weakened rules than the call blocking, and
// the weakened rules were near useless, so on 4/27 we restored the stronger rules
// but made them opt-in only for connected accounts, and hidden from non-connected
// while contining to serve them to grandfathered devices, ref: a9712745
func optInBlockGroupExclusions(
  _ deviceId: IOSDevice.Id?,
  in db: any DuetSQL.Client,
) async throws -> (device: IOSDevice?, excludedGroupIds: [Postgres.Data]) {
  let cutoff = ISO8601DateFormatter().date(from: "2026-04-27T12:41:29Z")!
  let device: IOSDevice? = if let deviceId {
    try? await db.find(deviceId) as IOSDevice
  } else {
    nil
  }
  let isNewDevice = (device?.createdAt ?? .now) >= cutoff
  guard isNewDevice else { return (device, []) }
  let optInGroups = try await BlockerApp.BlockGroup.query()
    .where(.optIn == true)
    .all(in: db)
  return (device, optInGroups.map { Postgres.Data.uuid($0.id.rawValue) })
}
