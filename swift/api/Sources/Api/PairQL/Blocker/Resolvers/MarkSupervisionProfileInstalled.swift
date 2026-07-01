import BlockerRoute
import Vapor

extension MarkSupervisionProfileInstalled: NoInputResolver {
  static func resolve(in ctx: BlockerApp.ChildContext) async throws -> Output {
    guard var supervision = try await ctx.device.supervision(in: ctx.db) else {
      logIOSUnexpected("d3b4f6e2", "mark profile installed without supervision")
      throw Abort(.badRequest)
    }

    if !supervision.profileInstalled {
      supervision.profileInstalledAt = get(dependency: \.date.now)
      try await ctx.db.update(supervision)

      try await ctx.db.create(IOSEvent(
        eventId: "1c6f6ca8",
        kind: .supervision,
        detail: "profile_installed_confirmed",
        deviceId: ctx.device.id,
        modelIdentifier: ctx.device.modelIdentifier,
        iosVersion: ctx.device.iosVersion,
      ))

      Task {
        let parent = try await ctx.child.parent(in: ctx.db)
        let claim = try? await Claim.find(ctx.device.id, intent: .blockerSupervise, in: ctx.db)
        let claimCodeText = claim.map { String($0.code) } ?? "unknown"
        await get(dependency: \.slack).internal(
          .info,
          """
          *iOS supervision complete!* filter confirmed running
          Parent: \(parent.adminSiteLink(.slack))
          Claim code: `\(claimCodeText)`
          """,
        )
        get(dependency: \.postmark).toSuperAdmin(
          "iOS Supervision Complete",
          """
          Supervision profile installed and filter confirmed running.<br/>
          Parent: \(parent.adminSiteLink(.email))<br/>
          Claim code: \(claimCodeText)
          """,
        )
      }
    }

    return .success
  }
}
