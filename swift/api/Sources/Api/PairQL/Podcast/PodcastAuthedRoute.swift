import Dependencies
import PodcastRoute
import Vapor

extension PodcastApp {
  struct InstallContext: ResolverContext {
    let requestId: String
    let dashboardUrl: String
    let install: PodcastApp.Install
    let device: IOSDevice
    let child: Child
    let telemetry: TelemetryBag

    @Dependency(\.db) var db
    @Dependency(\.env) var env
  }
}

extension AuthedRoute: RouteResponder {
  static func respond(to route: Self, in ctx: PodcastApp.InstallContext) async throws -> Response {
    switch route {
    case .getAccountStatus:
      let output = try await GetAccountStatus.resolve(in: ctx)
      return try await self.respond(with: output)
    case .consumePinResetCode(let input):
      let output = try await ConsumePinResetCode.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    }
  }
}
