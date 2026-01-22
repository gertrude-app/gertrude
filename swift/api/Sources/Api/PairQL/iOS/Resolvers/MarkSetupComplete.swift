import IOSRoute
import Vapor

extension MarkSetupComplete: NoInputResolver {
  static func resolve(in ctx: IOSApp.ChildContext) async throws -> Output {
    guard ctx.device.isSupervised else {
      logIOSUnexpected("e2c4cfbd", "mark setup complete on unsupervised")
      throw Abort(.badRequest)
    }

    if !ctx.device.isProfileInstalled {
      var device = ctx.device
      device.isProfileInstalled = true
      try await ctx.db.update(device)

      try await ctx.db.create(IOSEvent(
        eventId: "1c6f6ca8",
        kind: .supervision,
        detail: "profile_installed_confirmed",
        deviceId: device.id,
        modelIdentifier: device.modelIdentifier,
        iosVersion: device.iosVersion,
      ))
    }

    return .success
  }
}
