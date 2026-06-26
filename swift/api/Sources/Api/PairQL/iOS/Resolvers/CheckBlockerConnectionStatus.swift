import Dependencies
import DuetSQL
import IOSRoute
import Vapor

extension CheckBlockerConnectionStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    guard let claim = try await Claim.find(code: input.code, in: ctx.db) else {
      return .notFound
    }
    let device = try await claim.device(in: ctx.db)

    if device.id.rawValue != input.vendorId {
      logIOSUnusual("c1f0a9e4", "vendorId mismatch, c=\(input.code), v=\(input.vendorId)")
      return .notFound
    }

    if claim.intent != .blockerConnect {
      logIOSUnusual("d4a91f3c", "intent mismatch, c=\(input.code), intent=\(claim.intent)")
      return .notFound
    }

    guard let childId = device.childId else {
      if claim.expiresAt < get(dependency: \.date.now) {
        logIOSUnusual("b7d35e10", "expired, code=\(input.code)")
        return .expired
      }
      return .pending
    }

    let child = try await ctx.db.find(childId)
    let install = try await device.blockerInstall(in: ctx.db)
    let token = try await ctx.db.findOrCreate(
      BlockerApp.Token(installId: install.id),
      conflictOn: [.installId],
    )

    return .connected(ChildIOSDeviceData_v2(
      childId: child.id.rawValue,
      token: token.value.rawValue,
      deviceId: device.id.rawValue,
      childName: child.name,
      supervised: nil,
    ))
  }
}
