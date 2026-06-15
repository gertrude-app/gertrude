import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetAllDevices: Pair {
  static let auth: ClientAuth = .parent

  struct MacComputer: PairNestable {
    var id: Computer.Id
    var name: String?
    var modelIdentifier: String
    var modelTitle: String
    var users: [ComputerChild]
  }

  struct ComputerChild: PairNestable {
    var id: Api.Child.Id
    var name: String
    var status: ChildComputerStatus
  }

  struct IOSDevice: PairNestable {
    var id: Api.IOSDevice.Id
    var childId: Api.Child.Id
    var childName: String
    var modelName: String
    var deviceType: String
    var iosVersion: String
    var pendingSetup: Bool
  }

  struct Output: PairOutput {
    var computers: [MacComputer]
    var iosDevices: [IOSDevice]
  }
}

// resolver

extension GetAllDevices: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let children = try await Api.Child.query()
      .where(.parentId == context.parent.id)
      .all(in: context.db)

    let childMap: [Api.Child.Id: Api.Child] = children
      .reduce(into: [:]) { map, child in map[child.id] = child }

    async let computerUsersAsync = ComputerUser.query()
      .where(.childId |=| children.map(\.id))
      .all(in: context.db)
    async let iosDevicesAsync = Api.IOSDevice.query()
      .where(.childId |=| children.map(\.id))
      .all(in: context.db)

    let computerUsers = try await computerUsersAsync
    let iosDevices = try await iosDevicesAsync

    async let computersAsync = Computer.query()
      .where(.id |=| computerUsers.map(\.computerId))
      .all(in: context.db)
    async let supervisionsAsync = BlockerApp.Supervision.query()
      .where(.deviceId |=| iosDevices.map(\.id))
      .all(in: context.db)
    async let blockerConnectedDeviceIdsAsync = BlockerApp.Token.connectedDeviceIds(
      among: iosDevices.map(\.id),
      in: context.db,
    )
    async let amConnectedDeviceIdsAsync = PodcastApp.Token.connectedDeviceIds(
      among: iosDevices.map(\.id),
      in: context.db,
    )
    async let musicConnectedDeviceIdsAsync = MusicApp.Token.connectedDeviceIds(
      among: iosDevices.map(\.id),
      in: context.db,
    )

    let computers = try await computersAsync
    let supervisionMap: [Api.IOSDevice.Id: BlockerApp.Supervision] = try await supervisionsAsync
      .reduce(into: [:]) { map, s in map[s.deviceId] = s }
    let blockerConnectedDeviceIds = try await blockerConnectedDeviceIdsAsync
    let amConnectedDeviceIds = try await amConnectedDeviceIdsAsync
    let musicConnectedDeviceIds = try await musicConnectedDeviceIdsAsync

    @Dependency(\.websockets) var websockets

    let macComputers: [MacComputer] = try await computers.concurrentMap { computer in
      let users = computerUsers.filter { $0.computerId == computer.id }
      return try await MacComputer(
        id: computer.id,
        name: computer.customName,
        modelIdentifier: computer.modelIdentifier,
        modelTitle: computer.model.shortDescription,
        users: users.concurrentMap { computerUser in
          await ComputerChild(
            id: computerUser.childId,
            name: childMap[computerUser.childId]?.name ?? "",
            status: websockets.status(computerUser.id),
          )
        },
      )
    }

    let iosDeviceItems: [IOSDevice] = iosDevices.compactMap { device in
      guard let childId = device.childId else { return nil }
      let pendingSetup: Bool = if let supervision = supervisionMap[device.id] {
        !supervision.profileInstalled
      } else {
        !blockerConnectedDeviceIds.contains(device.id)
          && !amConnectedDeviceIds.contains(device.id)
          && !musicConnectedDeviceIds.contains(device.id)
      }
      return IOSDevice(
        id: device.id,
        childId: childId,
        childName: childMap[childId]?.name ?? "",
        modelName: device.modelName,
        deviceType: device.deviceType,
        iosVersion: device.iosVersion,
        pendingSetup: pendingSetup,
      )
    }

    return Output(computers: macComputers, iosDevices: iosDeviceItems)
  }
}
