import DuetSQL
import MusicRoute
import PairQL
import Vapor

extension MusicRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .authed(let uuid, let authedRoute):
      let token = try await MusicApp.Token.query()
        .where(.value == uuid)
        .first(in: context.db, orThrow: context.error(
          id: "2b2a110a",
          type: .loggedOut,
          debugMessage: "music app token not found",
        ))

      let install = try await token.install(in: context.db)
      let device = try await install.device(in: context.db)
      guard let child = try await device.child(in: context.db) else {
        throw context.error(
          id: "364b4b8d",
          type: .loggedOut,
          debugMessage: "music device has no associated child",
        )
      }

      context.telemetry.parentId = child.parentId
      let installContext = MusicApp.InstallContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        install: install,
        device: device,
        child: child,
        telemetry: context.telemetry,
      )
      return try await AuthedRoute.respond(to: authedRoute, in: installContext)

    case .unauthed(let unauthed):
      switch unauthed {
      case .crossPromos(let input):
        let output = try await CrossPromos.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .getMusicAppStatus(let input):
        let output = try await GetMusicAppStatus.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .getMusicAppStatus_v2(let input):
        let output = try await GetMusicAppStatus_v2.resolve(with: input, in: context)
        return try await self.respond(with: output)
      }
    }
  }
}

func requireGertrudeMusicAccess(
  in context: some ResolverContext,
  billing: BillingAccountSnapshot,
) throws {
  guard billing.can(.useGertrudeMusic) else {
    throw context.error(
      "ad0437fe",
      .paymentRequired,
      user: "Gertrude Music requires a Gertrude Medium or Full subscription.",
    )
  }
}
