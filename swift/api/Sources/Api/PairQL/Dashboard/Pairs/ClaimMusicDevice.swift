import Foundation
import PairQL

struct ClaimMusicDevice: Pair {
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
  }
}

extension ClaimMusicDevice: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await claimDevice(
      for: .music,
      code: input.code,
      child: input.child,
      baseId: "43ecc09c",
      in: context,
      onResume: { device, child in
        try await self.output(device: device, child: child, code: input.code, in: context)
      },
      beforeClaim: { device in
        try await self.requireMusicInstall(for: device, eventId: "11369678", in: context)
        let account = try await context.currentBillingAccount()
        try requireGertrudeMusicAccess(in: context, billing: account)
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
    try await self.requireMusicInstall(for: device, eventId: "7e6db2f2", in: context)
    let account = try await context.currentBillingAccount()
    try requireGertrudeMusicAccess(in: context, billing: account)
    return .init(
      childName: child.name,
      modelName: device.modelName,
      iosVersion: device.iosVersion,
      code: code,
    )
  }

  static func requireMusicInstall(
    for device: IOSDevice,
    eventId: String,
    in context: ParentContext,
  ) async throws {
    guard try await device.musicInstall(in: context.db) != nil else {
      logIOSUnusual(eventId, "Music claim on device with no music install")
      let msg = "Gertrude Music is not set up on this device."
      throw context.error(eventId, .notFound, user: msg)
    }
  }
}
