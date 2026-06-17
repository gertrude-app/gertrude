import Foundation
import GertieBlocker
import PairQL
import Tagged
import Vapor

struct UpsertBlockRule: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    var id: BlockerApp.BlockRule.Id?
    var deviceId: IOSDevice.Id
    var rule: GertieBlocker.BlockRule
  }

  typealias Output = BlockerApp.BlockRule.Id
}

// resolver

extension UpsertBlockRule: Resolver {
  static func resolve(with input: Input, in ctx: ParentContext) async throws -> Output {
    let device = try await ctx.db.find(input.deviceId)
    guard let childId = device.childId else {
      throw Abort(.notFound)
    }
    try await ctx.verifiedChild(from: childId)

    if let id = input.id {
      var blockRule = try await ctx.db.find(id)
      if blockRule.deviceId != input.deviceId {
        throw Abort(.unauthorized)
      }
      blockRule.rule = input.rule
      try await ctx.db.update(blockRule)
      return id
    } else {
      let blockRule = BlockerApp.BlockRule(deviceId: input.deviceId, rule: input.rule)
      let rule = try await ctx.db.create(blockRule)
      return rule.id
    }
  }
}

extension BlockerApp.BlockRule.Id: @retroactive PairOutput {}
