import Foundation
import MusicRoute
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
    let childId: Child.Id
    let deviceId: IOSDevice.Id
    let subscription: MusicSubscriptionState?
  }
}

extension ClaimMusicDevice: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    try await claimDevice(
      intent: .music,
      code: input.code,
      child: input.child,
      baseId: "43ecc09c", // 43ecc09c-1, 43ecc09c-2, 43ecc09c-3, 43ecc09c-4
      in: context,
      onResume: { device, child in
        try await self.output(device, child, input.code, in: context)
      },
      beforeClaim: { device in
        try await self.requireMusicInstall(for: device, eventId: "11369678", in: context)
      },
      onFresh: { device, child in
        let output = try await self.output(device, child, input.code, in: context)
        let account = try await context.currentBillingAccount()
        if !account.can(.useGertrudeMusic) {
          await RepeatTrialCanary.alertIfReclaimed(.music, device, child, in: context)
        }
        return output
      },
    )
  }

  static func output(
    _ device: IOSDevice,
    _ child: Child,
    _ code: Int,
    in context: ParentContext,
  ) async throws -> Output {
    let install = try await self.requireMusicInstall(for: device, eventId: "7e6db2f2", in: context)
    return try await .init(
      childName: child.name,
      modelName: device.modelName,
      iosVersion: device.iosVersion,
      code: code,
      childId: child.id,
      deviceId: device.id,
      subscription: self.subscription(for: install, in: context),
    )
  }

  static func subscription(
    for install: MusicApp.Install,
    in context: ParentContext,
  ) async throws -> MusicSubscriptionState? {
    let account = try await context.currentBillingAccount()
    guard try await install.hasToken(in: context.db) else {
      return account.can(.useGertrudeMusic) ? .active : nil
    }
    guard let token = try await install.token(in: context.db) else {
      return account.can(.useGertrudeMusic) ? .active : nil
    }
    return account.musicSubscriptionState(for: token)
  }

  @discardableResult
  static func requireMusicInstall(
    for device: IOSDevice,
    eventId: String,
    in context: ParentContext,
  ) async throws -> MusicApp.Install {
    guard let install = try await device.musicInstall(in: context.db) else {
      logIOSUnusual(eventId, "Music claim on device with no music install")
      let msg = "Gertrude Music is not set up on this device."
      throw context.error(eventId, .notFound, user: msg)
    }
    return install
  }
}
