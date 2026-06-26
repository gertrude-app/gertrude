import DuetSQL
import Foundation
import PairQL
import Vapor

enum AccountRoute: PairRoute {
  case authed(UUID, AuthedAccountRoute)
  case unauthed(UnauthedAccountRoute)
}

extension AccountRoute {
  nonisolated(unsafe) static let router = OneOf {
    Route(.case(Self.authed)) {
      Headers { Field("X-AccountToken") { UUID.parser() } }
      AuthedAccountRoute.router
    }
    Route(.case(Self.unauthed)) {
      UnauthedAccountRoute.router
    }
  }
}

extension AccountRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .authed(let uuid, let authedRoute):
      let token = try await Parent.DashToken.query()
        .where(.value == uuid)
        .first(
          in: context.db,
          orThrow: context.error("ac701d5e", .loggedOut, "Account token not found"),
        )

      let accountOwner = try await Parent.query()
        .where(.id == token.parentId)
        .first(in: context.db)

      context.telemetry.parentId = accountOwner.id
      let accountOwnerContext = AccountOwnerContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        accountOwner: accountOwner,
        ipAddress: context.ipAddress,
        telemetry: context.telemetry,
      )

      return try await AuthedAccountRoute.respond(to: authedRoute, in: accountOwnerContext)
    case .unauthed(let route):
      return try await UnauthedAccountRoute.respond(to: route, in: context)
    }
  }
}

// helpers

extension Conversion {
  static func accountInput<P: Pair>(
    _ Pair: P.Type,
  ) -> Self where Self == Conversions.JSON<P.Input> {
    .input(Pair, dateDecodingStrategy: .forgivingIso8601)
  }
}
