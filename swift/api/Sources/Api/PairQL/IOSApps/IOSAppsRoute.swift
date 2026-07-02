import GertieApp
import IOSAppsRoute
import Vapor

extension IOSAppsRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .unauthed(let unauthed):
      switch unauthed {
      case .appUpdateCheck(let input):
        let output = try await AppUpdateCheck.resolve(with: input, in: context)
        return try await self.respond(with: output)
      }
    }
  }
}

extension AppUpdateCheck: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    AppUpdateCheckResponse(status: AppUpdateCatalog.resolve(
      app: input.app,
      device: .init(
        deviceId: input.deviceId,
        appVersion: input.appVersion,
        buildNumber: input.buildNumber,
        modelIdentifier: input.modelIdentifier,
        iosVersion: input.iosVersion,
        locale: input.locale,
      ),
      now: get(dependency: \.date.now),
    ))
  }
}
