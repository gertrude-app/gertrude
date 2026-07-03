import Dependencies
import IOSRoute
import Vapor

extension BlockerApp {
  struct ChildContext: ResolverContext {
    let requestId: String
    let dashboardUrl: String
    let child: Child
    let device: IOSDevice
    let install: BlockerApp.Install
    let telemetry: TelemetryBag

    @Dependency(\.db) var db
  }
}

extension AuthedRoute: RouteResponder {
  static func respond(to route: Self, in ctx: BlockerApp.ChildContext) async throws -> Response {
    switch route {
    case .connectedRules_v2(let input):
      let output = try await ConnectedRules_v2.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .createSuspendFilterRequest(let input):
      let output = try await CreateSuspendFilterRequest.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .markSupervisionProfileInstalled:
      let output = try await MarkSupervisionProfileInstalled.resolve(in: ctx)
      return try await self.respond(with: output)
    case .pollFilterSuspensionDecision(let input):
      let output = try await PollFilterSuspensionDecision.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .screenshotUploadUrl(let input):
      let output = try await ScreenshotUploadUrl.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    case .selfReportSupervision(let input):
      let output = try await SelfReportSupervision.resolve(with: input, in: ctx)
      return try await self.respond(with: output)
    }
  }
}
