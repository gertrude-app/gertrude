import DuetSQL
import Foundation
import GertieIOS
import PairQL
import Vapor

struct UpdateIOSDevice: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var deviceId: IOSDevice.Id
    var enabledBlockGroups: [BlockerApp.BlockGroup.Id]
    var webPolicy: WebContentFilterPolicy.Kind
    var webPolicyDomains: [String]
    var isProfileLocked: Bool
    var allowAppRemoval: Bool
    var allowEraseContentAndSettings: Bool
  }
}

extension UpdateIOSDevice: Resolver {
  static func resolve(with input: Input, in ctx: ParentContext) async throws -> Output {
    let device: IOSDevice = try await ctx.db.find(input.deviceId)
    let children = try await ctx.children()
    guard children.first(where: { $0.id == device.childId }) != nil else {
      throw Abort(.unauthorized)
    }
    let deletedPivots = try await BlockerApp.DeviceBlockGroup.query()
      .where(.deviceId == input.deviceId)
      .all(in: ctx.db)
    try await BlockerApp.DeviceBlockGroup.query()
      .where(.id |=| deletedPivots.map(\.id))
      .delete(in: ctx.db)
    do {
      try await ctx.db.create(input.enabledBlockGroups.map { blockGroupId in
        BlockerApp.DeviceBlockGroup(
          deviceId: input.deviceId,
          blockGroupId: blockGroupId,
        )
      })
    } catch {
      try await ctx.db.create(deletedPivots)
    }

    var install = try await device.install(in: ctx.db)
    install.webPolicy = input.webPolicy.rawValue
    install.isProfileLocked = input.isProfileLocked
    install.allowAppRemoval = input.allowAppRemoval
    install.allowEraseContentAndSettings = input.allowEraseContentAndSettings
    try await ctx.db.update(install)

    try await BlockerApp.WebPolicyDomain.query()
      .where(.deviceId == input.deviceId)
      .delete(in: ctx.db)

    try await ctx.db.create(input.webPolicyDomains.map {
      BlockerApp.WebPolicyDomain(deviceId: input.deviceId, domain: $0)
    })

    return .success
  }
}
