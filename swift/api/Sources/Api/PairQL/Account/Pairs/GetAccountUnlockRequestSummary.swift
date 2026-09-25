import DuetSQL
import Foundation
import Gertie
import PairQL

struct GetAccountUnlockRequestSummary: Pair {
  static let auth: ClientAuth = .parent

  struct Person: PairNestable {
    let id: Child.Id
    let name: String
    let pendingCount: Int
    let targets: [String]
  }

  struct Output: PairOutput {
    let totalCount: Int
    let people: [Person]
  }
}

extension GetAccountUnlockRequestSummary: NoInputResolver {
  static func resolve(in context: AccountOwnerContext) async throws -> Output {
    let people = try await context.people()
    guard !people.isEmpty else {
      return .init(totalCount: 0, people: [])
    }

    let computerUsers = try await ComputerUser.query()
      .where(.childId |=| people.map(\.id))
      .all(in: context.db)
    guard !computerUsers.isEmpty else {
      return .init(totalCount: 0, people: [])
    }

    let personIdsByComputerUserId = Dictionary(
      uniqueKeysWithValues: computerUsers.map { ($0.id, $0.childId) },
    )
    let requests = try await UnlockRequest.query()
      .where(.computerUserId |=| computerUsers.map(\.id))
      .where(.status == RequestStatus.pending)
      .orderBy(.createdAt, .asc)
      .all(in: context.db)
    let requestsByPersonId = Dictionary(grouping: requests) {
      personIdsByComputerUserId[$0.computerUserId]
    }

    let summaries = people.compactMap { person -> Person? in
      guard let requests = requestsByPersonId[person.id], !requests.isEmpty else {
        return nil
      }

      var seenTargets = Set<String>()
      let targets = requests.compactMap { request -> String? in
        guard let target = unlockRequestSummaryTarget(request),
              seenTargets.insert(target).inserted else { return nil }
        return target
      }

      return .init(
        id: person.id,
        name: person.name,
        pendingCount: requests.count,
        targets: targets,
      )
    }.sorted {
      if $0.pendingCount != $1.pendingCount {
        return $0.pendingCount > $1.pendingCount
      }
      return $0.name < $1.name
    }

    return .init(totalCount: requests.count, people: summaries)
  }
}

private func unlockRequestSummaryTarget(_ request: UnlockRequest) -> String? {
  if let hostname = request.hostname {
    return hostname
  }
  if let ipAddress = request.ipAddress {
    return ipAddress
  }
  guard let rawUrl = request.url,
        let url = URL(string: rawUrl),
        let hostname = url.host else { return nil }
  return url.path == "/" ? hostname : hostname + url.path
}
