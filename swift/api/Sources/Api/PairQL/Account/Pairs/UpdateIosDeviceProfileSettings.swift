import DuetSQL
import PairQL

struct UpdateIosDeviceProfileSettings: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let deviceId: IOSDevice.Id
    let preventProtectionRemoval: Bool
    let allowDeletingApps: Bool
    let allowFactoryReset: Bool
    let allowInstallingApps: Bool
  }
}

extension UpdateIosDeviceProfileSettings: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let (device, _) = try await context.iosDevice(input.deviceId)
    var settings = try await BlockerApp.ProfileSettings
      .ensure(for: device.id, in: context.db)
    settings.isProfileLocked = input.preventProtectionRemoval
    settings.allowAppRemoval = input.allowDeletingApps
    settings.allowEraseContentAndSettings = input.allowFactoryReset
    settings.allowAppInstallation = input.allowInstallingApps
    try await context.db.update(settings)
    return .success
  }
}
