import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetChild: Pair {
  static let auth: ClientAuth = .parent

  struct Child: PairOutput {
    var id: Api.Child.Id
    var name: String
    var keyloggingEnabled: Bool
    var screenshotsEnabled: Bool
    var screenshotsResolution: Int
    var screenshotsFrequency: Int
    var showSuspensionActivity: Bool
    var keychains: [UserKeychainSummary]
    var downtime: PlainTimeWindow?
    var computers: [Computer]
    var iosDevices: [IOSDevice]
    var blockedApps: [UserBlockedApp.DTO]?
    var createdAt: Date
  }

  struct Computer: PairNestable {
    var id: ComputerUser.Id
    var computerId: Api.Computer.Id
    var status: ChildComputerStatus
    var modelFamily: DeviceModelFamily
    var modelTitle: String
    var modelIdentifier: String
    var customName: String?
  }

  struct IOSDevice: PairNestable {
    var id: IOSApp.Device.Id
    var modelName: String
    var deviceType: String
    var iosVersion: String
    var pendingClaimCode: Int?
  }

  typealias Input = Api.Child.Id
  typealias Output = Child
}

// resolver

extension GetChild: Resolver {
  static func resolve(
    with id: Api.Child.Id,
    in context: ParentContext,
  ) async throws -> Output {
    let child = try await context.verifiedChild(from: id)
    async let childKeychains = childKeychainSummaries(for: child.id, in: context.db)
    let pairs = try await ComputerUser.query()
      .where(.childId == child.id)
      .all(in: context.db)
      .concurrentMap { (computerUser: ComputerUser) -> (GetChild.Computer, Semver) in
        let computer = try await computerUser.computer(in: context.db)
        return await (GetChild.Computer(
          id: computerUser.id,
          computerId: computer.id,
          status: computerUser.status(),
          modelFamily: computer.model.family,
          modelTitle: computer.model.shortDescription,
          modelIdentifier: computer.model.identifier,
          customName: computer.customName,
        ), computer.filterVersion ?? .zero)
      }
    let computers = pairs.map(\.0)
    let versions = pairs.map(\.1)

    let devices = try await child.iosDevices(in: context.db)

    var blockedApps: [UserBlockedApp.DTO]?
    if versions.contains(where: { $0 >= .init("2.6.0")! }) {
      blockedApps = try await (child.blockedApps(in: context.db)).map(\.dto)
    }

    return try await .init(
      id: child.id,
      name: child.name,
      keyloggingEnabled: child.keyloggingEnabled,
      screenshotsEnabled: child.screenshotsEnabled,
      screenshotsResolution: child.screenshotsResolution,
      screenshotsFrequency: child.screenshotsFrequency,
      showSuspensionActivity: child.showSuspensionActivity,
      keychains: childKeychains,
      downtime: child.downtime,
      computers: computers.uniqued(on: \.id),
      iosDevices: devices.concurrentMap { device in
        let supervision = try await device.supervision(in: context.db)
        return .init(
          id: device.id,
          modelName: device.modelName,
          deviceType: device.deviceType,
          iosVersion: device.iosVersion,
          pendingClaimCode: supervision?.supervised == false ? supervision?.claimCode : nil,
        )
      },
      blockedApps: blockedApps,
      createdAt: child.createdAt,
    )
  }
}
