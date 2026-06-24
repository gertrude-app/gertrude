import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct ParentDetail: Pair {
  static let auth: ClientAuth = .superAdmin

  struct Input: PairInput {
    var id: UUID
  }

  struct Output: PairOutput {
    var id: Parent.Id
    var email: String
    var status: String
    var planStatus: PlanStatus
    var subscription: SubscriptionOutput?
    var createdAt: Date
    var children: [ChildOutput]
    var keychains: [KeychainOutput]
    var notifications: [NotificationOutput]
  }

  struct SubscriptionOutput: PairNestable {
    var tier: StripeSubscription.Tier
    var stripeStatus: StripeSubscription.StripeStatus
    var stripeId: String
    var currentPeriodEnd: Date
    var isLegacyPrice: Bool
  }

  struct ChildOutput: PairNestable {
    var id: Child.Id
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var filteringDisabled: Bool
    var createdAt: Date
    var installations: [InstallationOutput]
    var iosDevices: [IOSDeviceOutput]
    var keychains: [ChildKeychainOutput]
  }

  struct IOSDeviceOutput: PairNestable {
    var id: IOSDevice.Id
    var modelName: String
    var modelIdentifier: String
    var iosVersion: String
    var apps: [DeviceAppOutput]
    var supervisionStatus: String?
    var lastCheckin: Date?
    var createdAt: Date
  }

  struct DeviceAppOutput: PairNestable {
    var app: String
    var appVersion: String
    var connected: Bool
  }

  struct ChildKeychainOutput: PairNestable {
    var id: Keychain.Id
    var name: String
    var numKeys: Int
    var isPublic: Bool
  }

  struct InstallationOutput: PairNestable {
    var id: ComputerUser.Id
    var appVersion: String
    var filterVersion: String?
    var osVersion: String?
    var modelIdentifier: String
    var modelFamily: DeviceModelFamily
    var modelTitle: String
    var createdAt: Date
  }

  struct KeychainOutput: PairNestable {
    var id: Keychain.Id
    var name: String
    var numKeys: Int
    var isPublic: Bool
  }

  struct NotificationOutput: PairNestable {
    var id: Parent.Notification.Id
    var trigger: String
  }
}

extension ParentDetail: Resolver {
  static func resolve(with input: Input, in context: Context) async throws -> Output {
    let parent = try await context.db.find(Parent.Id(input.id)) as Parent
    let subscription = try await parent.subscription(in: context.db)

    let children = try await Child.query()
      .where(.parentId == parent.id)
      .all(in: context.db)

    let keychains = try await Keychain.query()
      .where(.parentId == parent.id)
      .all(in: context.db)

    let notifications = try await Parent.Notification.query()
      .where(.parentId == parent.id)
      .all(in: context.db)

    var childOutputs: [ChildOutput] = []
    for child in children {
      let computerUsers = try await ComputerUser.query()
        .where(.childId == child.id)
        .all(in: context.db)

      var installations: [InstallationOutput] = []
      for cu in computerUsers {
        let computer = try await Computer.query()
          .where(.id == cu.computerId)
          .first(in: context.db)
        installations.append(InstallationOutput(
          id: cu.id,
          appVersion: cu.appVersion,
          filterVersion: computer.filterVersion?.description,
          osVersion: computer.osVersion?.description,
          modelIdentifier: computer.modelIdentifier,
          modelFamily: computer.model.family,
          modelTitle: computer.model.shortDescription,
          createdAt: cu.createdAt,
        ))
      }

      let devices = try await child.iosDevices(in: context.db)
      var iosDeviceOutputs: [IOSDeviceOutput] = []
      for device in devices {
        var apps: [DeviceAppOutput] = []

        let blockerInstall = try await BlockerApp.Install.query()
          .where(.deviceId == device.id)
          .all(in: context.db)
          .first
        if let blockerInstall {
          let connected = try await BlockerApp.Token.query()
            .where(.installId == blockerInstall.id)
            .exists(in: context.db)
          apps.append(DeviceAppOutput(
            app: "blocker",
            appVersion: blockerInstall.appVersion,
            connected: connected,
          ))
        }

        if let podcastInstall = try await device.podcastInstall(in: context.db) {
          let connected = try await PodcastApp.Token.query()
            .where(.installId == podcastInstall.id)
            .exists(in: context.db)
          apps.append(DeviceAppOutput(
            app: "am",
            appVersion: podcastInstall.appVersion,
            connected: connected,
          ))
        } else if let latestPodcastEvent = try await PodcastEvent.query()
          .where(.deviceId == device.id.rawValue)
          .orderBy(.createdAt, .desc)
          .limit(1)
          .all(in: context.db)
          .first {
          apps.append(DeviceAppOutput(
            app: "am",
            appVersion: latestPodcastEvent.appVersion,
            connected: false,
          ))
        }

        if let musicInstall = try await device.musicInstall(in: context.db) {
          let connected = try await MusicApp.Token.query()
            .where(.installId == musicInstall.id)
            .exists(in: context.db)
          apps.append(DeviceAppOutput(
            app: "music",
            appVersion: musicInstall.appVersion,
            connected: connected,
          ))
        }

        let supervision = try await device.supervision(in: context.db)
        let blockerConnected = apps.contains { $0.app == "blocker" && $0.connected }
        let status: String? = if let supervision {
          supervision.status(device: device).rawValue
        } else if blockerConnected {
          "connected"
        } else {
          nil
        }
        let lastCheckin = try await IOSEvent.query()
          .where(.deviceId == device.id.rawValue)
          .where(.kind == "checkin")
          .orderBy(.createdAt, .desc)
          .limit(1)
          .all(in: context.db)
          .first
        iosDeviceOutputs.append(IOSDeviceOutput(
          id: device.id,
          modelName: device.modelName,
          modelIdentifier: device.modelIdentifier,
          iosVersion: device.iosVersion,
          apps: apps,
          supervisionStatus: status,
          lastCheckin: lastCheckin?.createdAt,
          createdAt: device.createdAt,
        ))
      }

      let childKeychains = try await child.keychains(in: context.db)
      var childKeychainOutputs: [ChildKeychainOutput] = []
      for keychain in childKeychains {
        let keyCount = try await Key.query()
          .where(.keychainId == keychain.id)
          .count(in: context.db)
        childKeychainOutputs.append(ChildKeychainOutput(
          id: keychain.id,
          name: keychain.name,
          numKeys: keyCount,
          isPublic: keychain.isPublic,
        ))
      }

      childOutputs.append(ChildOutput(
        id: child.id,
        name: child.name,
        keyloggingEnabled: child.keyloggingEnabled,
        screenshotsEnabled: child.screenshotsEnabled,
        filteringDisabled: child.filteringDisabled,
        createdAt: child.createdAt,
        installations: installations,
        iosDevices: iosDeviceOutputs,
        keychains: childKeychainOutputs,
      ))
    }

    var keychainOutputs: [KeychainOutput] = []
    for keychain in keychains {
      let keyCount = try await Key.query()
        .where(.keychainId == keychain.id)
        .count(in: context.db)
      keychainOutputs.append(KeychainOutput(
        id: keychain.id,
        name: keychain.name,
        numKeys: keyCount,
        isPublic: keychain.isPublic,
      ))
    }

    let notificationOutputs: [NotificationOutput] = notifications
      .map { (notif: Parent.Notification) in
        NotificationOutput(
          id: notif.id,
          trigger: notif.trigger.rawValue,
        )
      }

    let analyticsData = try await AnalyticsQuery.shared.data()
    let parentData = analyticsData.parents[parent.id]
    let status = parentData?.status.rawValue ?? "unknown"

    @Dependency(\.date.now) var now
    let billing = try await parent.billingAccountSnapshot(in: context.db, at: now)
    let subscriptionOutput = subscription.map {
      SubscriptionOutput(
        tier: $0.tier,
        stripeStatus: $0.stripeStatus,
        stripeId: $0.stripeId.rawValue,
        currentPeriodEnd: $0.currentPeriodEnd,
        isLegacyPrice: $0.isLegacyPrice,
      )
    }

    return .init(
      id: parent.id,
      email: parent.email.rawValue,
      status: status,
      planStatus: billing.planStatus,
      subscription: subscriptionOutput,
      createdAt: parent.createdAt,
      children: childOutputs,
      keychains: keychainOutputs,
      notifications: notificationOutputs,
    )
  }
}
