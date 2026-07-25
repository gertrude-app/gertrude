import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetSuspensionRequests: Pair {
  static let auth: ClientAuth = .parent

  struct Request: PairOutput, PairNestable {
    let id: MacApp.SuspendFilterRequest.Id
    let personId: Child.Id
    let personName: String
    let deviceName: String?
    let requestedDurationInSeconds: Int
    let reason: String?
    let extraMonitoringOptions: [String: String]
    let createdAt: Date
  }

  typealias Output = [Request]
}

extension GetSuspensionRequests: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    guard !people.isEmpty else { return [] }

    let computerUsers = try await ComputerUser.query()
      .where(.childId |=| people.map(\.id))
      .all(in: context.db)
    guard !computerUsers.isEmpty else { return [] }

    let peopleById = people.reduce(into: [Child.Id: Child]()) { result, person in
      result[person.id] = person
    }
    let computerUsersById = computerUsers.reduce(
      into: [ComputerUser.Id: ComputerUser](),
    ) { result, computerUser in
      result[computerUser.id] = computerUser
    }
    let computerIdsByPersonId = computerUsers.reduce(
      into: [Child.Id: Set<Computer.Id>](),
    ) { result, computerUser in
      result[computerUser.childId, default: []].insert(computerUser.computerId)
    }
    let cutoff = get(dependency: \.date.now) - .hours(2)
    let requests = try await MacApp.SuspendFilterRequest.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.status == RequestStatus.pending)
      .where(.createdAt >= cutoff)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
    guard !requests.isEmpty else { return [] }

    let requestedComputerIds = Set(requests.compactMap {
      computerUsersById[$0.computerUserId]?.computerId
    })
    let computers = try await Computer.query()
      .where(.id |=| Array(requestedComputerIds))
      .all(in: context.db)
    let computersById = computers.reduce(into: [Computer.Id: Computer]()) { result, computer in
      result[computer.id] = computer
    }

    return requests.compactMap { request in
      guard
        let computerUser = computerUsersById[request.computerUserId],
        let person = peopleById[computerUser.childId]
      else { return nil }
      let deviceName = (computerIdsByPersonId[person.id]?.count ?? 0) > 1
        ? computersById[computerUser.computerId].map {
          $0.customName ?? $0.model.shortDescription
        }
        : nil
      let extraMonitoringOptions = Semver(computerUser.appVersion)! >= .init("2.1.0")!
        ? person.extraMonitoringOptions.mapKeys(\.magicString)
        : [:]
      return Request(
        id: request.id,
        personId: person.id,
        personName: person.name,
        deviceName: deviceName,
        requestedDurationInSeconds: request.duration.rawValue,
        reason: request.requestComment,
        extraMonitoringOptions: extraMonitoringOptions,
        createdAt: request.createdAt,
      )
    }
  }
}
