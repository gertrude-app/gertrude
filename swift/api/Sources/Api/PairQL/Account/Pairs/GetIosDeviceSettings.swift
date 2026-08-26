import DuetSQL
import PairQL
import PodcastRoute

struct GetIosDeviceSettings: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let deviceId: IOSDevice.Id
  }

  struct BlockGroup: PairNestable {
    let id: BlockerApp.BlockGroup.Id
    let name: String
    let description: String
    let longDescription: String
    let optIn: Bool
  }

  struct ProfileSettings: PairNestable {
    let preventProtectionRemoval: Bool
    let allowDeletingApps: Bool
    let allowFactoryReset: Bool
    let allowInstallingApps: Bool
  }

  struct Blocker: PairNestable {
    let allBlockGroups: [BlockGroup]
    let enabledBlockGroupIds: [BlockerApp.BlockGroup.Id]
    let isSupervised: Bool
    let profileSettings: ProfileSettings
  }

  struct Podcasts: PairNestable {
    let subscription: AmSubscriptionState
  }

  struct Music: PairNestable {
    let requiresPayment: Bool
  }

  struct Output: PairOutput {
    let deviceId: IOSDevice.Id
    let personId: Child.Id
    let deviceName: String
    let modelIdentifier: String
    let iosVersion: String
    let blocker: Blocker?
    let podcasts: Podcasts?
    let music: Music?
  }
}

extension GetIosDeviceSettings: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let (device, person) = try await context.iosDevice(input.deviceId)
    return try await Output(
      deviceId: device.id,
      personId: person.id,
      deviceName: device.modelName,
      modelIdentifier: device.modelIdentifier,
      iosVersion: device.iosVersion,
      blocker: self.blocker(for: device, in: context),
      podcasts: self.podcasts(for: device, in: context),
      music: self.music(for: device, in: context),
    )
  }

  static func music(
    for device: IOSDevice,
    in context: AccountOwnerContext,
  ) async throws -> Music? {
    guard let install = try await device.musicInstall(in: context.db),
          try await install.hasToken(in: context.db) else {
      return nil
    }
    let requiresPayment = try await context.currentBillingAccount()
      .paymentActionForMissingCapability(.useGertrudeMusic) != nil
    return Music(requiresPayment: requiresPayment)
  }

  static func podcasts(
    for device: IOSDevice,
    in context: AccountOwnerContext,
  ) async throws -> Podcasts? {
    guard let install = try await device.podcastInstall(in: context.db),
          try await install.hasToken(in: context.db) else {
      return nil
    }
    let subscription = try await context.currentBillingAccount()
      .amSubscriptionState(forInstall: install)
    return Podcasts(subscription: subscription)
  }

  static func blocker(
    for device: IOSDevice,
    in context: AccountOwnerContext,
  ) async throws -> Blocker? {
    guard let install = try? await device.blockerInstall(in: context.db),
          try await install.hasToken(in: context.db) else {
      return nil
    }

    async let allBlockGroupsAsync = BlockerApp.BlockGroup.query()
      .orderBy(.name, .asc)
      .all(in: context.db)
    async let enabledBlockGroupsAsync = device.blockGroups(in: context.db)
    async let supervisionAsync = device.supervision(in: context.db)

    let allBlockGroups = try await allBlockGroupsAsync
    let enabledBlockGroups = try await enabledBlockGroupsAsync
    let supervision = try await supervisionAsync
    let settings = try await BlockerApp.ProfileSettings
      .ensure(for: device.id, in: context.db)

    return Blocker(
      allBlockGroups: allBlockGroups.map { .init(
        id: $0.id,
        name: $0.name,
        description: $0.description,
        longDescription: $0.longDescription,
        optIn: $0.optIn,
      ) },
      enabledBlockGroupIds: enabledBlockGroups.map(\.id),
      isSupervised: supervision?.supervised ?? false,
      profileSettings: .init(
        preventProtectionRemoval: settings.isProfileLocked,
        allowDeletingApps: settings.allowAppRemoval,
        allowFactoryReset: settings.allowEraseContentAndSettings,
        allowInstallingApps: settings.allowAppInstallation,
      ),
    )
  }
}
