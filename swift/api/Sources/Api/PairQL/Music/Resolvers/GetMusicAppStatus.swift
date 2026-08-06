import Foundation
import MusicRoute

extension GetMusicAppStatus: Resolver {
  static func resolve(with input: Input, in ctx: Context) async throws -> Output {
    await ctx.db.logDeprecated("GetMusicAppStatus(v1)")
    let output = try await GetMusicAppStatus_v2.resolve(
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
      return .claimed(
        token: token,
        childId: childId,
        childName: childName,
        entitlement: legacyEntitlement(entitlement, in: ctx),
      )
    }
  }
}

private func legacyEntitlement(
  _ entitlement: GetMusicAppStatus_v2.Entitlement,
  in ctx: Context,
) -> GetMusicAppStatus.Entitlement {
  switch entitlement {
  case .active:
    .active
  case .unavailable:
    .unpaid(remediationUrl: URL(string: "\(ctx.dashboardUrl)/settings"))
  }
}
