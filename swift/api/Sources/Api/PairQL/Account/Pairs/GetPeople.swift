import DuetSQL
import Foundation
import PairQL
import TSCodable

struct GetPeople: Pair {
  static let auth: ClientAuth = .parent

  struct Person: PairOutput, PairNestable {
    let id: Child.Id
    let name: String
    let relationship: Child.Relationship
    let devices: [Device]
    let screenshot: RecentScreenshot?
  }

  struct RecentScreenshot: PairNestable {
    let url: String
    let createdAt: Date
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
    let computerUserIdsByPersonId = Dictionary(grouping: computerUsers, by: \.childId)
      .mapValues { $0.map(\.id) }
    let recentScreenshotCutoff = Date(subtractingDays: 14)

    async let computersAsync = Computer.query()
      .where(.id |=| computerUsers.map(\.computerId))
      .all(in: context.db)
    async let recentScreenshotsAsync: [(Child.Id, Screenshot)?] = people.concurrentMap {
      person -> (Child.Id, Screenshot)? in
      guard let computerUserIds = computerUserIdsByPersonId[person.id] else { return nil }
      let screenshots = try await Screenshot.query()
        .where(.computerUserId |=| computerUserIds)
        .where(.createdAt >= recentScreenshotCutoff)
        .orderBy(.createdAt, .desc)
        .limit(1)
        .all(in: context.db)
      return screenshots.first.map { (person.id, $0) }
    }

    let computers = try await computersAsync
    let recentScreenshotPairs = try await recentScreenshotsAsync
    let recentScreenshotsByPersonId = Dictionary(
      uniqueKeysWithValues: recentScreenshotPairs.compactMap(\.self),
    )
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

    let aws = with(dependency: \.aws)
    let bucketUrl = with(dependency: \.env.s3.bucketUrl)
    return people.map { person in
      Person(
        id: person.id,
        name: person.name,
        relationship: person.relationship,
        devices: (macDevices + mobileDevices)
          .filter { $0.0 == person.id }
          .map(\.1),
        screenshot: recentScreenshotsByPersonId[person.id].map { screenshot in
          RecentScreenshot(
            url: signedScreenshotUrl(screenshot.url, bucketUrl: bucketUrl, aws: aws),
            createdAt: screenshot.createdAt,
          )
        },
      )
    }
  }
}
