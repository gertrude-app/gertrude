import GertieApp
import IOSAppsRoute
import Vapor

extension IOSAppsRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .unauthed(let unauthed):
      switch unauthed {
      case .killSwitchCheck(let input):
        let output = try await KillSwitchCheck.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .logEvent(let input):
        let output = try await LogAppEvent.resolve(with: input, in: context)
        return try await self.respond(with: output)
      }
    }
  }
}

extension KillSwitchCheck: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    KillSwitchCheckResponse(status: KillSwitchCatalog.resolve(
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

extension LogAppEvent: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    switch input.app {
    case .music:
      try await resolveMusicEvent(input, in: context)
    case .blocker:
      try await resolveBlockerEvent(input, in: context)
    case .podcasts:
      try await resolvePodcastEvent(input, in: context)
    }
  }
}
