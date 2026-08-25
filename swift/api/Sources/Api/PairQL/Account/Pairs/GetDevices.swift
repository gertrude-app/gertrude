import DuetSQL
import Foundation
import PairQL

struct GetDevices: Pair {
  static let auth: ClientAuth = .parent

  struct Mac: PairNestable {
    struct Person: PairNestable {
      let id: Child.Id
      let name: String
    }

    let id: Computer.Id
    let name: String?
    let modelName: String
    let modelIdentifier: String
    let macOSVersion: String?
    let people: [Person]
  }

  struct Mobile: PairNestable {
    enum DeviceType: String, PairNestable {
      case iphone
      case ipad
    }

    enum ConnectedApp: String, PairNestable {
      case blocker
      case podcasts
      case music
    }

    enum SupervisionStatus: String, PairNestable {
      case pendingClaim
      case claimed
      case supervised
      case complete
    }

    struct Person: PairNestable {
      let id: Child.Id
      let name: String
    }

    let id: IOSDevice.Id
    let type: DeviceType
    let modelName: String
    let modelIdentifier: String
    let iOSVersion: String
    let person: Person
    let connectedApps: [ConnectedApp]
    let supervisionStatus: SupervisionStatus?
  }

  struct Output: PairOutput {
    let macs: [Mac]
    let mobileDevices: [Mobile]
  }
}

extension GetDevices: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    guard !people.isEmpty else { return .init(macs: [], mobileDevices: []) }

    let peopleById = people.reduce(into: [Child.Id: Child]()) { result, person in
      result[person.id] = person
    }
    let personIds = people.map(\.id)

    async let computerUsersAsync = ComputerUser.query()
      .where(.childId |=| personIds)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
    async let mobileDevicesAsync = IOSDevice.query()
      .where(.childId |=| personIds)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)

    let computerUsers = try await computerUsersAsync
    let mobileDevices = try await mobileDevicesAsync
    let mobileDeviceIds = mobileDevices.map(\.id)

    async let computersAsync = Computer.query()
      .where(.id |=| computerUsers.map(\.computerId))
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
    async let blockerDeviceIdsAsync = BlockerApp.Token.connectedDeviceIds(
      among: mobileDeviceIds,
      in: context.db,
    )
    async let podcastDeviceIdsAsync = PodcastApp.Token.connectedDeviceIds(
      among: mobileDeviceIds,
      in: context.db,
    )
    async let musicDeviceIdsAsync = MusicApp.Token.connectedDeviceIds(
      among: mobileDeviceIds,
      in: context.db,
    )
    async let supervisionsAsync = BlockerApp.Supervision.query()
      .where(.deviceId |=| mobileDeviceIds)
      .all(in: context.db)
    async let supervisionClaimsAsync = Claim.query()
      .where(.deviceId |=| mobileDeviceIds)
      .where(.intent == ClaimIntent.blockerSupervise)
      .orderBy(.createdAt, .desc)
      .all(in: context.db)

    let computers = try await computersAsync
    let blockerDeviceIds = try await blockerDeviceIdsAsync
    let podcastDeviceIds = try await podcastDeviceIdsAsync
    let musicDeviceIds = try await musicDeviceIdsAsync
    let supervisions = try await supervisionsAsync
    let supervisionClaims = try await supervisionClaimsAsync
    let supervisionsByDeviceId = supervisions.reduce(
      into: [IOSDevice.Id: BlockerApp.Supervision](),
    ) { result, supervision in
      result[supervision.deviceId] = supervision
    }
    let latestSupervisionClaimsByDeviceId = supervisionClaims.reduce(
      into: [IOSDevice.Id: Claim](),
    ) { result, claim in
      if result[claim.deviceId] == nil {
        result[claim.deviceId] = claim
      }
    }

    let macs = computers.map { computer in
      var seenPersonIds = Set<Child.Id>()
      let connectedPeople = computerUsers
        .filter { $0.computerId == computer.id }
        .compactMap { computerUser -> Mac.Person? in
          guard seenPersonIds.insert(computerUser.childId).inserted,
                let person = peopleById[computerUser.childId]
          else {
            return nil
          }
          return .init(id: person.id, name: person.name)
        }

      return Mac(
        id: computer.id,
        name: computer.customName,
        modelName: computer.model.shortDescription,
        modelIdentifier: computer.modelIdentifier,
        macOSVersion: computer.osVersion?.description,
        people: connectedPeople,
      )
    }

    let mobile = mobileDevices.compactMap { device -> Mobile? in
      guard let personId = device.childId, let person = peopleById[personId] else {
        return nil
      }

      var connectedApps: [Mobile.ConnectedApp] = []
      if blockerDeviceIds.contains(device.id) {
        connectedApps.append(.blocker)
      }
      if podcastDeviceIds.contains(device.id) {
        connectedApps.append(.podcasts)
      }
      if musicDeviceIds.contains(device.id) {
        connectedApps.append(.music)
      }

      let supervisionStatus = supervisionsByDeviceId[device.id].map { supervision in
        Mobile.SupervisionStatus(
          supervision.status(
            claimedAt: latestSupervisionClaimsByDeviceId[device.id]?.claimedAt,
          ),
        )
      }

      return Mobile(
        id: device.id,
        type: device.deviceType == "iPad" ? .ipad : .iphone,
        modelName: device.modelName,
        modelIdentifier: device.modelIdentifier,
        iOSVersion: device.iosVersion,
        person: .init(id: person.id, name: person.name),
        connectedApps: connectedApps,
        supervisionStatus: supervisionStatus,
      )
    }

    return .init(macs: macs, mobileDevices: mobile)
  }
}

extension GetDevices.Mobile.SupervisionStatus {
  init(_ status: BlockerApp.Supervision.Status) {
    switch status {
    case .pendingClaim: self = .pendingClaim
    case .claimed: self = .claimed
    case .supervised: self = .supervised
    case .complete: self = .complete
    }
  }
}
