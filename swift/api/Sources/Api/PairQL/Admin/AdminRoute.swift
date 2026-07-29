import DuetSQL
import Foundation
import PairQL
import Vapor

enum AdminRoute: PairRoute {
  case authed(UUID, AuthedAdminRoute)
  case unauthed(UnauthedAdminRoute)
}

extension AdminRoute {
  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.authed)) {
      Headers { Field("X-SuperAdminToken") { UUID.parser() } }
      AuthedAdminRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedAdminRoute.router
    }
  }
}

extension AdminRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    let response: Response
    switch route {
    case .authed(let uuid, let authedRoute):
      _ = try await SuperAdminToken.query()
        .where(.value == uuid)
        .first(
          in: context.db,
          orThrow: context.error("7df93d61", .loggedOut, "Admin token not found or expired"),
        )
      response = try await AuthedAdminRoute.respond(to: authedRoute, in: context)
    case .unauthed(let route):
      response = try await UnauthedAdminRoute.respond(to: route, in: context)
    }
    response.headers.responseCompression = .enable
    return response
  }
}
