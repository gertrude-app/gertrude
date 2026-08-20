import Dependencies
import Foundation
import PairQL

struct GetComputerStatuses: Pair {
  static let auth: ClientAuth = .parent

  enum SnapshotFreshness: String, PairNestable {
    case fresh
    case stale
    case unsupported
    case missing
  }

  struct ComputerStatus: PairOutput {
    let computerUserId: ComputerUser.Id
    let computerId: Computer.Id
    let childId: Child.Id
    let status: ChildComputerStatus
    let apiReachable: Bool
    let effectiveFilterStatus: ChildComputerStatus?
    let snapshotReceivedAt: Date?
    let snapshotFreshness: SnapshotFreshness
  }

  typealias Output = [ComputerStatus]
}

extension GetComputerStatuses: NoInputResolver {
  static func resolve(in context: ParentContext) async throws -> Output {
    let computerUsers = try await context.computerUsers()
    @Dependency(\.websockets) var websockets

    return try await computerUsers.concurrentMap { computerUser in
      let details = await websockets.statusDetails(computerUser.id)
      return ComputerStatus(
        computerUserId: computerUser.id,
        computerId: computerUser.computerId,
        childId: computerUser.childId,
        status: details.legacyStatus,
        apiReachable: details.apiReachable,
        effectiveFilterStatus: details.effectiveFilterStatus,
        snapshotReceivedAt: details.snapshotReceivedAt,
        snapshotFreshness: .init(details.snapshotFreshness),
      )
    }
  }
}

extension GetComputerStatuses.SnapshotFreshness {
  init(_ freshness: ComputerUserStatus.SnapshotFreshness) {
    switch freshness {
    case .fresh: self = .fresh
    case .stale: self = .stale
    case .unsupported: self = .unsupported
    case .missing: self = .missing
    }
  }
}
