import DuetSQL
import Foundation
import PairQL
import Vapor

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
    try await self.validateMusicInstallExists(forCode: input.code, in: context)

    return try await claimDevice(
      for: .music,
      code: input.code,
      child: input.child,
      baseId: "43ecc09c",
      in: context,
      onResume: { device, child in
        try await self.output(device: device, child: child, code: input.code, in: context)
      },
      onFresh: { device, child in
        try await self.output(device: device, child: child, code: input.code, in: context)
      },
    )
  }

  static func validateMusicInstallExists(
    forCode code: Int,
    in context: ParentContext,
  ) async throws {
    guard let device = try? await IOSDevice.query()
      .where(.claimCode == code)
      .first(in: context.db) else {
      logIOSUnusual("f84c03fe", "Music claim code not found")
      let msg = "Code not found. Double-check and try again."
      throw context.error("f84c03fe", .notFound, user: msg)
    }

    guard try await device.musicInstall(in: context.db) != nil else {
      logIOSUnusual("11369678", "Music claim on device with no music install")
      let msg = "Gertrude Music is not set up on this device."
      throw context.error("11369678", .notFound, user: msg)
    }
  }

  static func output(
    device: IOSDevice,
    child: Child,
    code: Int,
    in context: ParentContext,
  ) async throws -> Output {
    guard try await device.musicInstall(in: context.db) != nil else {
      logIOSUnusual("7e6db2f2", "Music claim on device with no music install")
      let msg = "Gertrude Music is not set up on this device."
      throw context.error("7e6db2f2", .notFound, user: msg)
    }
    return .init(
      childName: child.name,
      modelName: device.modelName,
      iosVersion: device.iosVersion,
      code: code,
    )
  }
}
