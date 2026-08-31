import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetMacDevice: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let deviceId: Computer.Id
  }

  struct Person: PairNestable {
    let id: Child.Id
    let name: String
    let status: ChildComputerStatus
  }

  struct TargetVersions: PairNestable {
    let stable: String?
    let beta: String?
    let canary: String?
  }

  struct Output: PairOutput {
    let id: Computer.Id
    let name: String?
    let modelName: String
    let modelIdentifier: String
    let macOSVersion: String?
    let appVersion: String?
    let releaseChannel: ReleaseChannel
    let targetVersions: TargetVersions
    let people: [Person]
  }
}

extension GetMacDevice: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let computer = try await context.computer(input.deviceId)
    let computerUsers = try await computer.computerUsers(in: context.db)
    let appVersion = computerUsers.compactMap { Semver($0.appVersion) }.max()
    var seenPersonIds = Set<Child.Id>()
    let personIds = computerUsers.compactMap { computerUser in
      seenPersonIds.insert(computerUser.childId).inserted ? computerUser.childId : nil
    }
    let people: [Child] = if personIds.isEmpty {
      []
    } else {
      try await Child.query()
        .where(.id |=| personIds)
        .where(.parentId == context.accountOwner.id)
        .all(in: context.db)
    }
    let peopleById = people.reduce(into: [Child.Id: Child]()) { result, person in
      result[person.id] = person
    }
    let connectedPeople = try await personIds.concurrentMap { personId in
      guard let person = peopleById[personId] else { return nil as Person? }
      return try await Person(
        id: person.id,
        name: person.name,
        status: consolidatedChildComputerStatus(person.id, computerUsers),
      )
    }.compactMap(\.self)

    async let stableTarget = self.targetVersion(
      for: .stable,
      currentVersion: appVersion,
      in: context,
    )
    async let betaTarget = self.targetVersion(
      for: .beta,
      currentVersion: appVersion,
      in: context,
    )
    async let canaryTarget = self.targetVersion(
      for: .canary,
      currentVersion: appVersion,
      in: context,
    )
    let targetVersions = try await TargetVersions(
      stable: stableTarget,
      beta: betaTarget,
      canary: canaryTarget,
    )

    return Output(
      id: computer.id,
      name: computer.customName,
      modelName: computer.model.shortDescription,
      modelIdentifier: computer.modelIdentifier,
      macOSVersion: computer.osVersion?.description,
      appVersion: appVersion?.description,
      releaseChannel: computer.appReleaseChannel,
      targetVersions: targetVersions,
      people: connectedPeople,
    )
  }

  private static func targetVersion(
    for channel: ReleaseChannel,
    currentVersion: Semver?,
    in context: AccountOwnerContext,
  ) async throws -> String? {
    guard let currentVersion else { return nil }
    return try await resolveLatestRelease(
      channel,
      currentVersion.description,
      context.db,
    ).semver
  }
}
