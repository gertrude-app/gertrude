import DuetSQL
import Foundation
import PairQL
import PodcastRoute
import Vapor

struct ClaimAmDevice: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let code: Int
    let child: ClaimIOSDevice.ChildAssignment
  }

  struct Output: PairOutput {
    let childName: String
    let modelName: String
    let iosVersion: String
    let code: Int
    let subscription: AmSubscriptionState
  }
}

extension ClaimAmDevice: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await claimDevice(
      intent: .podcasts,
      code: input.code,
      child: input.child,
      baseId: "894c4af3", // 894c4af3-1, 894c4af3-2, 894c4af3-3, 894c4af3-4
      in: context,
      onResume: { device, child in
        try await self.output(device: device, child: child, code: input.code, in: context)
      },
      onFresh: { device, child in
        try await self.output(device: device, child: child, code: input.code, in: context)
      },
    )
  }

  static func output(
    device: IOSDevice,
    child: Child,
    code: Int,
    in context: ParentContext,
  ) async throws -> Output {
    guard let install = try await device.podcastInstall(in: context.db) else {
      logIOSUnusual("7487a3d4", "AM claim on device with no podcast install")
      let msg = "Gertrude AM is not set up on this device."
      throw context.error("7487a3d4", .notFound, user: msg)
    }
    let account = try await context.currentBillingAccount()
    return .init(
      childName: child.name,
      modelName: device.modelName,
      iosVersion: device.iosVersion,
      code: code,
      subscription: account.amSubscriptionState(forInstall: install),
    )
  }
}
