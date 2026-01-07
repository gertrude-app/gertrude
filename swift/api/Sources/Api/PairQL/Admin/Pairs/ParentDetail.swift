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
    var subscriptionStatus: String
    var subscriptionId: String?
    var monthlyPriceInCents: Int
    var createdAt: Date
    var children: [ChildOutput]
    var keychains: [KeychainOutput]
    var notifications: [NotificationOutput]
  }

  struct ChildOutput: PairNestable {
    var id: Child.Id
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var createdAt: Date
    var installations: [InstallationOutput]
    var keychains: [ChildKeychainOutput]
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
    let parent = try await Parent.query()
      .where(.id == .uuid(input.id))
      .first(in: context.db, orThrow: context.error("c8f93d61", .notFound, "Parent not found"))

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
        createdAt: child.createdAt,
        installations: installations,
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

    return .init(
      id: parent.id,
      email: parent.email.rawValue,
      status: status,
      subscriptionStatus: parent.subscriptionStatus.rawValue,
      subscriptionId: parent.subscriptionId?.rawValue,
      monthlyPriceInCents: parent.monthlyPrice.rawValue,
      createdAt: parent.createdAt,
      children: childOutputs,
      keychains: keychainOutputs,
      notifications: notificationOutputs,
    )
  }
}
