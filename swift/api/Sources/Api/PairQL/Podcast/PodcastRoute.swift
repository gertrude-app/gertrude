import DuetSQL
import PodcastRoute
import Vapor

extension PodcastRoute: RouteResponder {
  static func respond(to route: Self, in context: Context) async throws -> Response {
    switch route {
    case .unauthed(let unauthed):
      switch unauthed {
      case .createClaimCode(let input):
        let output = try await CreateClaimCode.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .getTrialStatus(let input):
        let output = try await GetTrialStatus.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .logPodcastEvent(let input):
        let output = try await LogPodcastEvent.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .logPodcastEvent_v2(let input):
        let output = try await LogPodcastEvent_v2.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .logPodcastEvent_v3(let input):
        let output = try await LogPodcastEvent_v3.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .podcastProducts:
        let output = try await PodcastProducts.resolve(in: context)
        return try await self.respond(with: output)
      case .createDatabaseUpload(let input):
        let output = try await CreateDatabaseUpload.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .verifyPromoCode(let input):
        let output = try await VerifyPromoCode.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .verifyDbDownload(let input):
        let output = try await VerifyDbDownload.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .migratePodcastVendorId(let input):
        let output = try await MigratePodcastVendorId.resolve(with: input, in: context)
        return try await self.respond(with: output)
      }

    case .authed(let uuid, let authedRoute):
      let token = try await PodcastApp.Token.query()
        .where(.value == uuid)
        .first(in: context.db, orThrow: context.error(
          id: "9b3c5d8e",
          type: .unauthorized,
          debugMessage: "podcast app token not found",
          appTag: .amTokenNotFound,
        ))

      let install = try await token.install(in: context.db)
      let device = try await install.device(in: context.db)
      guard let child = try await device.child(in: context.db) else {
        throw context.error(
          id: "4a7f2b91",
          type: .unauthorized,
          debugMessage: "podcast device has no associated child",
          appTag: .amTokenNotFound,
        )
      }

      context.telemetry.parentId = child.parentId
      let installContext = PodcastApp.InstallContext(
        requestId: context.requestId,
        dashboardUrl: context.dashboardUrl,
        install: install,
        device: device,
        child: child,
        telemetry: context.telemetry,
      )
      return try await AuthedRoute.respond(to: authedRoute, in: installContext)
    }
  }
}
