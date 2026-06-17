import GertieBlocker
import IOSRoute

extension ConnectAccountFeatureFlag: NoInputResolver {
  static func resolve(in ctx: Context) async throws -> Output {
    await .init(
      isEnabled: true,
      offerScreenText: "You can connect this device to a free Gertrude parent account for more controls and features.",
      explainScreenText: "Connecting to a free Gertrude account allows the parent to modify settings remotely after setup and get access to new controls and features as they are released. It’s not required though, all the core blocking features will always work without an account.",
      releasedAppStoreVersion: with(dependency: \.ephemeral).getLatestIOSAppStoreVersion(),
    )
  }
}
