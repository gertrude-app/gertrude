import DuetSQL
import IOSRoute
import Vapor

extension IOSRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .unauthed(let unauthed):
      switch unauthed {
      case .blockRules(let input):
        let output = try await BlockRules.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .blockRules_v2(let input):
        let output = try await BlockRules_v2.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .checkSupervisionFlowStatus(let input):
        let output = try await CheckSupervisionFlowStatus.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .connectDevice_v2(let input):
        let output = try await ConnectDevice_v2.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .createSupervisionClaimCode(let input):
        let output = try await CreateSupervisionClaimCode.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .defaultBlockRules(let input):
        let output = try await DefaultBlockRules.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .logIOSEvent(let input):
        let output = try await LogIOSEvent.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .logIOSEvent_v2(let input):
        let output = try await LogIOSEvent_v2.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .recoveryDirective(let input):
        let output = try await RecoveryDirective.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .recoveryDirective_v2(let input):
        let output = try await RecoveryDirective_v2.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .connectAccountFeatureFlag:
        let output = try await ConnectAccountFeatureFlag.resolve(in: context)
        return try await self.respond(with: output)
      }

    case .authed(let uuid, let authedRoute):
      let token = try await IOSApp.Token.query()
        .where(.value == uuid)
        .first(in: context.db, orThrow: context.error(
          id: "3aecf9fd",
          type: .unauthorized,
          debugMessage: "child ios device token not found",
          appTag: .iosDeviceTokenNotFound,
        ))

      // TODO(perf): this is a fairly hot path, should probably join here
      let device = try await token.device(in: context.db)
      guard let child = try await device.child(in: context.db) else {
        throw context.error(
          id: "7d4e8f21",
          type: .unauthorized,
          debugMessage: "device has no associated child",
          appTag: .iosDeviceTokenNotFound,
        )
      }

      let childContext = IOSApp.ChildContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        child: child,
        device: device,
      )
      return try await AuthedRoute.respond(to: authedRoute, in: childContext)
    }
  }
}
