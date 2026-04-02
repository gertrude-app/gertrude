import DuetSQL
import Foundation
import Gertie
import PairQL

struct HandleUnlockRequests: Pair {
  static let auth: ClientAuth = .parent

  struct KeyData: PairNestable {
    var keychainId: Keychain.Id
    var key: Gertie.Key
    var comment: String?
    var expiration: Date?
  }

  struct Decision: PairNestable {
    var unlockRequestId: UnlockRequest.Id
    var status: RequestStatus
    var key: KeyData?
    var responseComment: String?
  }

  struct Input: PairInput {
    var decisions: [Decision]
    var duplicateRequestIds: [UnlockRequest.Id]
  }
}

// resolver

extension HandleUnlockRequests: Resolver {
  static func resolve(with input: Input, in context: ParentContext) async throws -> Output {
    var acceptedCount = 0
    var rejectedCount = 0
    var targets: [String] = []
    var keychainIds: Set<Keychain.Id> = []
    var userDevice: ComputerUser?

    struct LegacyMessage {
      var id: UUID
      var status: RequestStatus
      var target: String
      var comment: String?
    }
    var legacyMessages: [LegacyMessage] = []

    for decision in input.decisions {
      var unlockRequest = try await context.db.find(decision.unlockRequestId)
      let device = try await unlockRequest.computerUser(in: context.db)
      if userDevice == nil {
        try await context.verifiedChild(from: device.childId)
        userDevice = device
      }

      unlockRequest.status = decision.status
      unlockRequest.responseComment = decision.responseComment
      try await context.db.update(unlockRequest)

      let target = unlockRequest.target ?? ""
      targets.append(target)
      legacyMessages.append(.init(
        id: unlockRequest.id.rawValue,
        status: decision.status,
        target: target,
        comment: decision.responseComment,
      ))

      switch decision.status {
      case .accepted:
        acceptedCount += 1
        if let keyData = decision.key {
          let keychain = try await context.parent.keychain(keyData.keychainId, in: context.db)
          keychainIds.insert(keychain.id)
          let existingKeys = try await keychain.keys(in: context.db)
          if var existing = existingKeys.first(where: { $0.key == keyData.key }) {
            var needsUpdate = false
            if let comment = keyData.comment, comment != existing.comment {
              existing.comment = comment
              needsUpdate = true
            }
            if keyData.expiration != existing.deletedAt {
              existing.deletedAt = keyData.expiration
              needsUpdate = true
            }
            if needsUpdate {
              try await context.db.update(existing)
            }
          } else {
            try await context.db.create(Key(
              keychainId: keychain.id,
              key: keyData.key,
              comment: keyData.comment,
              deletedAt: keyData.expiration,
            ))
          }
        }
      case .rejected:
        rejectedCount += 1
      case .pending:
        break
      }
    }

    let websockets = get(dependency: \.websockets)
    for keychainId in keychainIds {
      try await websockets.send(.userUpdated, to: .usersWith(keychain: keychainId))
    }

    if let userDevice {
      if userDevice.appSemver >= Semver("2.9.0") {
        let ids = legacyMessages.map(\.id)
        try await websockets.send(
          .unlockRequestsHandled(
            ids: ids,
            accepted: acceptedCount,
            rejected: rejectedCount,
            targets: targets.sorted(),
          ),
          to: .userDevice(userDevice.id),
        )
      } else {
        for msg in legacyMessages {
          try await websockets.send(
            .unlockRequestUpdated_v2(
              id: msg.id,
              status: msg.status,
              target: msg.target,
              comment: msg.comment,
            ),
            to: .userDevice(userDevice.id),
          )
        }
      }
    }

    if !input.duplicateRequestIds.isEmpty {
      try await UnlockRequest.query()
        .where(.id |=| input.duplicateRequestIds)
        .delete(in: context.db)
    }

    return .success
  }
}
