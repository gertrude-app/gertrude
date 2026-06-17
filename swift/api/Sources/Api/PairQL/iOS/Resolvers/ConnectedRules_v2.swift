import Crypto
import Dependencies
import DuetSQL
import GertieBlocker
import IOSRoute

extension ConnectedRules_v2: Resolver {
  static func resolve(with input: Input, in ctx: BlockerApp.ChildContext) async throws -> Output {
    let groups = try await ctx.device.blockGroups(in: ctx.db)
    let blockRules = try await BlockerApp.BlockRule.query()
      .where(.or(
        .groupId |=| groups.map { .uuid($0.id) },
        .deviceId == ctx.device.id,
      ))
      .orderBy(.id, .asc)
      .all(in: ctx.db)
      .map(\.rule)
      .frozenEncodable

    let rulesHash = iosBlockRulesHash(blockRules)
    let deviceId = ctx.device.id.lowercased
    with(dependency: \.logger).info(
      "ConnectedRules_v2: device=\(deviceId), rules=\(blockRules.count), hash=\(rulesHash)",
    )

    _ = try? await ctx.db.create(IOSEvent(
      eventId: "b977cfdc",
      kind: .checkin,
      detail: "rules=\(blockRules.count), hash=\(rulesHash)",
      deviceId: ctx.device.id,
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
    ))

    var device = ctx.device
    if device.shouldUpdateModelIdentifier(to: input.modelIdentifier) {
      device.modelIdentifier = input.modelIdentifier
    }
    device.iosVersion = input.iosVersion
    if device != ctx.device {
      try await ctx.db.update(device)
    }

    var install = ctx.install
    install.appVersion = input.appVersion
    if install != ctx.install {
      try await ctx.db.update(install)
    }

    ModelIdentifier.alertIfUnknown(input.modelIdentifier)

    return .init(
      blockRules: blockRules.map(\.frozen),
      // NB: for now always nil, for 1.7.0 launch, safety w/ supervised users,
      // but we can turn it on later, and the app will set it, if we decide it's correct
      webPolicy: nil,
    )
  }
}

func iosBlockRulesHash(_ rules: [GertieBlocker.BlockRule]) -> String {
  let data = try! JSONEncoder().encode(rules)
  let digest = SHA256.hash(data: data)
  return digest.prefix(4).map { String(format: "%02x", $0) }.joined()
}
