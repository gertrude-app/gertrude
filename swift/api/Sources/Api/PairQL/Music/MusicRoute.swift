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
          type: .unauthorized,
          debugMessage: "music app token not found",
        ))

      let install = try await token.install(in: context.db)
      let device = try await install.device(in: context.db)
      guard let child = try await device.child(in: context.db) else {
        throw context.error(
          id: "364b4b8d",
          type: .unauthorized,
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
      case .getMusicAppStatus(let input):
        let output = try await GetMusicAppStatus.resolve(with: input, in: context)
        return try await self.respond(with: output)
      case .getMusicOnboardingConfig:
        let output = try await GetMusicOnboardingConfig.resolve(in: context)
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

extension GetMusicAppStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    let install = try await MusicApp.Install.ensureExists(
      deviceId: IOSDevice.Id(input.deviceId),
      modelIdentifier: input.modelIdentifier,
      iosVersion: input.iosVersion,
      appVersion: input.appVersion,
      in: ctx.db,
    )
    let device = try await install.device(in: ctx.db)

    let musicClaim = try await Claim.find(device.id, intent: .music, in: ctx.db)
    if let musicClaim, musicClaim.claimedAt != nil {
      guard let childId = musicClaim.childId else {
        logIOSUnusual("9a6d1f2c", "music claim claimedAt w/ no child, device=\(device.id)")
        throw Abort(.internalServerError)
      }
      let child = try await ctx.db.find(childId)

      let token = try await ctx.db.findOrCreate(
        MusicApp.Token(installId: install.id),
        conflictOn: [.installId],
      )
      let entitlement = try await musicEntitlement(for: child, in: ctx)

      return .claimed(
        token: token.value.rawValue,
        childId: child.id.rawValue,
        childName: child.name,
        entitlement: entitlement,
      )
    }

    if let child = try await device.child(in: ctx.db) {
      let claim = try await device.ensureClaim(intent: .music, in: ctx.db)
      try await completeClaim(claim, for: child, in: ctx.db)
      let token = try await ctx.db.findOrCreate(
        MusicApp.Token(installId: install.id),
        conflictOn: [.installId],
      )
      let entitlement = try await musicEntitlement(for: child, in: ctx)

      return .claimed(
        token: token.value.rawValue,
        childId: child.id.rawValue,
        childName: child.name,
        entitlement: entitlement,
      )
    }

    let claim = try await device.ensureClaim(intent: .music, in: ctx.db)
    return .unclaimed(code: claim.code, expiresAt: claim.expiresAt)
  }
}

extension GetMusicOnboardingConfig: NoInputResolver {
  static func resolve(in _: Context) async throws -> Output {
    .init(
      // use {{device}} placeholder -> "iPhone"/"iPad"
      explainAccountText: nil,
      // use {{device}} placeholder -> "<name>’s iPhone"/"<name>’s iPad"
      subscriptionRequiredText: nil,
    )
  }
}

func musicEntitlement(
  for child: Child,
  in ctx: Context,
) async throws -> GetMusicAppStatus.Entitlement {
  let parent = try await child.parent(in: ctx.db)
  let account = try await parent.billingAccountSnapshot(
    in: ctx.db,
    at: get(dependency: \.date.now),
  )
  guard account.can(.useGertrudeMusic) else {
    return .unpaid(remediationUrl: URL(string: "\(ctx.dashboardUrl)/settings"))
  }
  return .active
}
