import DuetSQL
import PairQL

struct UpdateIosDeviceBlockedGroups: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let deviceId: IOSDevice.Id
    let enabledBlockGroupIds: [BlockerApp.BlockGroup.Id]
  }
}

extension UpdateIosDeviceBlockedGroups: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let (device, _) = try await context.iosDevice(input.deviceId)
    let existing = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == device.id)
      .all(in: context.db)

    try await context.db.withTransaction { tx in
      try await BlockerApp.DeviceBlockGroup.query()
        .where(.id |=| existing.map(\.id))
        .delete(in: tx)
      try await tx.create(Set(input.enabledBlockGroupIds).map { blockGroupId in
        BlockerApp.DeviceBlockGroup(
          deviceId: device.id,
          blockGroupId: blockGroupId,
        )
      })
    }

    return .success
  }
}
