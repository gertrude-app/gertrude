import DuetSQL
import PairQL
import TSCodable

struct GetPeople: Pair {
  static let auth: ClientAuth = .parent

  struct Person: PairOutput, PairNestable {
    let id: Child.Id
    let name: String
    let devices: [Device]
  }

  @TSCodable
  enum Device: PairNestable {
    case mac(MacDevice)
    case ios(IOSDevice)
  }

  struct MacDevice: PairNestable {
    let id: ComputerUser.Id
    let name: String?
    let macOSVersion: String?
    let modelName: String
    let modelIdentifier: String
    let online: Bool
  }

  struct IOSDevice: PairNestable {
    enum DeviceType: String, PairNestable {
      case iphone
      case ipad
    }

    let id: Api.IOSDevice.Id
    let type: DeviceType
    let iOSVersion: String
    let modelName: String
    let modelIdentifier: String
  }

  typealias Output = [Person]
}

// resolver

extension GetPeople: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    guard !people.isEmpty else { return [] }

    let personIds = people.map(\.id)
    async let computerUsersAsync = ComputerUser.query()
      .where(.childId |=| personIds)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
    async let iOSDevicesAsync = Api.IOSDevice.query()
      .where(.childId |=| personIds)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)

    let computerUsers = try await computerUsersAsync
    let iOSDevices = try await iOSDevicesAsync
    let computers = try await Computer.query()
      .where(.id |=| computerUsers.map(\.computerId))
      .all(in: context.db)
    let computersById = computers.reduce(into: [Computer.Id: Computer]()) { result, computer in
      result[computer.id] = computer
    }

    let macDevices = try await computerUsers.concurrentMap {
      computerUser -> (Child.Id, Device)? in
      guard let computer = computersById[computerUser.computerId] else { return nil }
      let online = await computerUser.status() != .offline
      return (
        computerUser.childId,
        .mac(.init(
          id: computerUser.id,
          name: computer.customName,
          macOSVersion: computer.osVersion?.description,
          modelName: computer.model.shortDescription,
          modelIdentifier: computer.modelIdentifier,
          online: online,
        )),
      )
    }.compactMap(\.self)

    let mobileDevices = iOSDevices.compactMap { device -> (Child.Id, Device)? in
      guard let personId = device.childId else { return nil }
      return (
        personId,
        .ios(.init(
          id: device.id,
          type: device.deviceType == "iPad" ? .ipad : .iphone,
          iOSVersion: device.iosVersion,
          modelName: device.modelName,
          modelIdentifier: device.modelIdentifier,
        )),
      )
    }

    return people.map { person in
      Person(
        id: person.id,
        name: person.name,
        devices: (macDevices + mobileDevices)
          .filter { $0.0 == person.id }
          .map(\.1),
      )
    }
  }
}
