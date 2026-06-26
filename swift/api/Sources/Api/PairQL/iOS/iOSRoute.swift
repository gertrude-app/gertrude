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
      case .checkBlockerConnectionStatus(let input):
        let output = try await CheckBlockerConnectionStatus.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .checkSupervisionFlowStatus(let input):
        let output = try await CheckSupervisionFlowStatus.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .connectDevice_v2(let input):
        let output = try await ConnectDevice_v2.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .createBlockerClaimCode(let input):
        let output = try await CreateBlockerClaimCode.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .createSupervisionClaimCode(let input):
        let output = try await CreateSupervisionClaimCode.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .crossPromos(let input):
        let output = try await CrossPromos.resolve(with: input, in: context)
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
      case .getBlockGroups(let input):
        let output = try await GetBlockGroups.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .blockRules_v3(let input):
        let output = try await BlockRules_v3.resolve(with: input, in: context)
        return try await self.respond(with: output)
      }

    case .authed(let uuid, let authedRoute):
      let token = try await BlockerApp.Token.query()
        .where(.value == uuid)
        .first(in: context.db, orThrow: context.error(
          id: "3aecf9fd",
          type: .unauthorized,
          debugMessage: "child ios device token not found",
          appTag: .iosDeviceTokenNotFound,
        ))

      // TODO(perf): this is a fairly hot path, should probably join here
      let install = try await token.install(in: context.db)
      let device = try await install.device(in: context.db)
      guard let child = try await device.child(in: context.db) else {
        throw context.error(
          id: "7d4e8f21",
          type: .unauthorized,
          debugMessage: "device has no associated child",
          appTag: .iosDeviceTokenNotFound,
        )
      }

      context.telemetry.parentId = child.parentId
      let childContext = BlockerApp.ChildContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        child: child,
        device: device,
        install: install,
        telemetry: context.telemetry,
      )
      return try await AuthedRoute.respond(to: authedRoute, in: childContext)
    }
  }
}
