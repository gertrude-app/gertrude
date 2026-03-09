import IOSRoute
import Vapor

extension MarkSupervisionProfileInstalled: NoInputResolver {
  static func resolve(in ctx: IOSApp.ChildContext) async throws -> Output {
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
        await get(dependency: \.slack).internal(
          .info,
          """
          *iOS supervision complete!* filter confirmed running, \
          code `\(code)`, parent `\(parent.adminSiteLink(.slack))`
          """,
        )
        get(dependency: \.postmark).toSuperAdmin(
          "iOS Supervision Complete",
          """
          Supervision profile installed and filter confirmed running.<br/>
          Parent: \(parent.adminSiteLink(.email))<br/>
          Claim code: \(supervision.claimCode)
          """,
        )
      }
    }

    return .success
  }
}
