import DuetSQL
import Foundation
import PairQL
import Vapor

struct SaveExtendedSupervisionControls: Pair {
  static let auth: ClientAuth = .parent

  struct Bookmark: PairNestable {
    var url: String
    var title: String
  }

  struct Controls: PairNestable {
    var whitelistedAppBundleIds: [String]?
    var webAllowList: [Bookmark]?
  }

  struct Input: PairInput {
    var deviceId: IOSDevice.Id
    var controls: Controls
  }
}

extension SaveExtendedSupervisionControls: Resolver {
  static func resolve(with input: Input, in ctx: ParentContext) async throws -> Output {
    let device: IOSDevice = try await ctx.db.find(input.deviceId)
    let children = try await ctx.children()
    guard children.first(where: { $0.id == device.childId }) != nil else {
      throw Abort(.unauthorized)
    }

    let billing = try await ctx.currentBillingAccount()
    guard billing.can(.manageExtendedSupervisionControls) else {
      throw ctx.error(
        "0e7d41b9",
        .paymentRequired,
        user: "Your Gertrude account does not include extended supervision controls.",
      )
    }

    let supervision = try await device.supervision(in: ctx.db)
    guard supervision?.supervised == true else {
      throw ctx.error(
        "b4f2c6a1",
        .badRequest,
        user: "Extended supervision controls require a supervised device.",
      )
    }

    var settings = try await BlockerApp.ProfileSettings.ensure(for: device.id, in: ctx.db)
    settings.whitelistedAppBundleIds = input.controls.whitelistedAppBundleIds
    settings.webAllowList = input.controls.webAllowList
      .map { $0.map { .init(url: $0.url, title: $0.title) } }
    try await ctx.db.update(settings)

    return .success
  }
}
