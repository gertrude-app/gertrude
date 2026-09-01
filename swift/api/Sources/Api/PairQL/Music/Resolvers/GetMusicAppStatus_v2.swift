import MusicRoute

extension GetMusicAppStatus_v2: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    await ctx.db.logDeprecated("GetMusicAppStatus(v2)")
    let output = try await GetMusicAppStatus_v3.resolve(
      with: .init(
        deviceId: input.deviceId,
        modelIdentifier: input.modelIdentifier,
        iosVersion: input.iosVersion,
        appVersion: input.appVersion,
      ),
      in: ctx,
    )
    switch output {
    case .unclaimed(let code, let expiresAt):
      return .unclaimed(code: code, expiresAt: expiresAt)
    case .claimed(let token, let childId, let childName, let entitlement):
      let legacyEntitlement: GetMusicAppStatus_v2.Entitlement = switch entitlement {
      case .active, .trial: .active
      case .unavailable: .unavailable
      }
      return .claimed(
        token: token,
        childId: childId,
        childName: childName,
        entitlement: legacyEntitlement,
      )
    }
  }
}
