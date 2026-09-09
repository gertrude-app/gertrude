import Dependencies
import DuetSQL
import Foundation
import Gertie
import PairQL
import TSCodable

struct DecideUnlockRequests: Pair {
  static let auth: ClientAuth = .parent

  @TSCodable
  enum Action: PairNestable {
    case rejected
    case acceptedKey(
      keychainId: Keychain.Id?,
      key: Gertie.Key,
      comment: String?,
      expiration: Date?,
    )
    case acceptedApp(scope: AppScope.Single)
  }

  struct Decision: PairNestable {
    let requestIds: [UnlockRequest.Id]
    let action: Action
  }

  struct Input: PairInput {
    let personId: Child.Id
    let decisions: [Decision]
    let responseComment: String?
  }

  struct Result: PairOutput {
    let handledCount: Int
    let skippedCount: Int
    let remainingCount: Int
  }

  typealias Output = Result
}

extension DecideUnlockRequests: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    let computerUsers = try await person.computerUsers(in: context.db)
    let computerUserIds = computerUsers.map(\.id)
    let allIds = input.decisions.flatMap(\.requestIds)

    guard Set(allIds).count == allIds.count else {
      throw context.error(
        id: "21a5e282",
        type: .badRequest,
        debugMessage: "unlock request decision contains duplicate ids",
        userMessage: "Some unlock requests were included more than once. Refresh and try again.",
      )
    }

    let requests = allIds.isEmpty
      ? []
      : try await UnlockRequest.query()
      .where(.id |=| allIds)
      .where(.computerUserId |=| computerUserIds)
      .all(in: context.db)
    guard requests.count == allIds.count else {
      throw context.error(
        id: "3b573ef0",
        type: .notFound,
        debugMessage: "unlock request does not belong to account person",
        userMessage: "Some unlock requests could not be found. Refresh and try again.",
      )
    }

    let requestsById = Dictionary(uniqueKeysWithValues: requests.map { ($0.id, $0) })
    for decision in input.decisions {
      guard case .acceptedApp(let scope) = decision.action else { continue }
      let requestedBundleIds = try decision.requestIds.map { requestId in
        guard let bundleId = requestsById[requestId]?.appBundleId else {
          throw context.error(
            id: "8428bd8d",
            type: .badRequest,
            debugMessage: "unrestricted app decision included a request without a bundle id",
            userMessage: "The requested app could not be verified. Refresh and try again.",
          )
        }
        return normalizedUnlockBundleId(bundleId)
      }
      let allowedBundleIds: Set<String>
      switch scope {
      case .bundleId(let bundleId):
        allowedBundleIds = [normalizedUnlockBundleId(bundleId)]
      case .identifiedAppSlug(let slug):
        guard let app = try? await IdentifiedApp.query()
          .where(.slug == slug)
          .first(in: context.db)
        else {
          throw context.error(
            id: "d82b2f82",
            type: .badRequest,
            debugMessage: "unrestricted app decision used an unknown app slug",
            userMessage: "The requested app could not be verified. Refresh and try again.",
          )
        }
        allowedBundleIds = try await Set(app.bundleIds(in: context.db).map {
          normalizedUnlockBundleId($0.bundleId)
        })
      }
      guard requestedBundleIds.allSatisfy(allowedBundleIds.contains) else {
        throw context.error(
          id: "f36f97e0",
          type: .badRequest,
          debugMessage: "unrestricted app scope did not match every represented request",
          userMessage: "The app did not match every request. Refresh and try again.",
        )
      }
    }

    let needsDefaultKeychain = input.decisions.contains { decision in
      if case .acceptedKey(let keychainId, _, _, _) = decision.action {
        return keychainId == nil && decision.requestIds.contains {
          requestsById[$0]?.status == .pending
        }
      }
      return false
    }

    struct TransactionResult: Sendable {
      let handled: [UnlockRequest]
      let skippedCount: Int
      let updatedKeychainIds: Set<Keychain.Id>
      let grantedApp: Bool
    }

    let result = try await context.db.withTransaction { tx in
      var eligibleKeychains = try await person.keychains(in: tx)
        .filter { $0.parentId == context.accountOwner.id }
      if needsDefaultKeychain, eligibleKeychains.isEmpty {
        let keychain = try await createAccountDefaultKeychain(for: person, in: tx)
        eligibleKeychains.append(keychain)
      }
      let keychainsById = Dictionary(
        uniqueKeysWithValues: eligibleKeychains.map { ($0.id, $0) },
      )
      let defaultKeychain = eligibleKeychains.first
      var existingKeysByKeychainId: [Keychain.Id: [Key]] = [:]
      var existingAppScopes = try await Set(
        person.unrestrictedMacApps(in: tx)
          .map { unrestrictedMacAppScopeKey($0.scope) },
      )
      var handled: [UnlockRequest] = []
      var skippedCount = 0
      var updatedKeychainIds = Set<Keychain.Id>()
      var grantedApp = false

      for decision in input.decisions {
        let decisionRequests = decision.requestIds.compactMap { requestsById[$0] }
        let pending = decisionRequests.filter { $0.status == .pending }
        skippedCount += decisionRequests.count - pending.count
        guard !pending.isEmpty else { continue }

        switch decision.action {
        case .rejected:
          for var request in pending {
            request.status = .rejected
            request.responseComment = input.responseComment
            try await tx.update(request)
            handled.append(request)
          }

        case .acceptedKey(let requestedKeychainId, let key, let comment, let expiration):
          switch key {
          case .path, .skeleton:
            throw context.error(
              id: "150df973",
              type: .badRequest,
              debugMessage: "unlock request attempted unsupported key type",
              userMessage: "That key cannot be created from an unlock request.",
            )
          case .anySubdomain, .domain, .domainRegex, .ipAddress:
            break
          }

          if key.targetsCloudflareEch {
            throw context.error(
              id: "6e9567a8",
              type: .badRequest,
              debugMessage: "unlock request attempted key targeting cloudflare-ech.com",
              userMessage: "Gertrude blocks cloudflare-ech.com automatically — no key needed.",
              showContactSupport: false,
            )
          }
          if let regexError = key.domainRegexValidationError {
            throw context.error(
              id: "6d683786",
              type: .badRequest,
              debugMessage: "unlock request domainRegex validation failed: \(regexError)",
              userMessage: regexError,
              showContactSupport: false,
            )
          }

          let keychain = requestedKeychainId.flatMap { keychainsById[$0] } ?? defaultKeychain
          guard let keychain,
                requestedKeychainId == nil || keychain.id == requestedKeychainId else {
            throw context.error(
              id: "1d19cd2a",
              type: .notFound,
              debugMessage: "unlock request keychain is not assigned to account person",
              userMessage: "That keychain is no longer available for this person. Refresh and try again.",
            )
          }

          var existingKeys = existingKeysByKeychainId[keychain.id]
          if existingKeys == nil {
            existingKeys = try await keychain.keys(in: tx)
          }
          if existingKeys?.contains(where: { $0.key == key }) != true {
            let created = try await tx.create(Key(
              keychainId: keychain.id,
              key: key,
              comment: comment,
              deletedAt: expiration,
            ))
            existingKeys?.append(created)
            updatedKeychainIds.insert(keychain.id)
          }
          existingKeysByKeychainId[keychain.id] = existingKeys

          for var request in pending {
            request.status = .accepted
            request.responseComment = nil
            try await tx.update(request)
            handled.append(request)
          }

        case .acceptedApp(let scope):
          if existingAppScopes.insert(unrestrictedMacAppScopeKey(scope)).inserted {
            try await tx.create(UnrestrictedMacApp(scope: scope, childId: person.id))
            grantedApp = true
          }
          for var request in pending {
            request.status = .accepted
            request.responseComment = nil
            try await tx.update(request)
            handled.append(request)
          }
        }
      }

      return TransactionResult(
        handled: handled,
        skippedCount: skippedCount,
        updatedKeychainIds: updatedKeychainIds,
        grantedApp: grantedApp,
      )
    }

    let websockets = get(dependency: \.websockets)
    for keychainId in result.updatedKeychainIds {
      try await websockets.send(.userUpdated, to: .usersWith(keychain: keychainId))
    }
    if result.grantedApp {
      try await websockets.send(.userUpdated, to: .user(person.id))
    }

    let computerUsersById = Dictionary(
      uniqueKeysWithValues: computerUsers.map { ($0.id, $0) },
    )
    for (computerUserId, handled) in Dictionary(grouping: result.handled, by: \.computerUserId) {
      guard let computerUser = computerUsersById[computerUserId] else { continue }
      if computerUser.appSemver >= Semver("2.9.0") {
        try await websockets.send(
          .unlockRequestsHandled(
            ids: handled.map(\.id.rawValue),
            accepted: handled.count { $0.status == .accepted },
            rejected: handled.count { $0.status == .rejected },
            targets: handled.compactMap(\.target).sorted(),
          ),
          to: .userDevice(computerUser.id),
        )
      } else {
        for request in handled {
          try await websockets.send(
            .unlockRequestUpdated_v2(
              id: request.id.rawValue,
              status: request.status,
              target: request.target ?? "",
              comment: request.responseComment,
            ),
            to: .userDevice(computerUser.id),
          )
        }
      }
    }

    let remainingCount = computerUserIds.isEmpty
      ? 0
      : try await UnlockRequest.query()
      .where(.computerUserId |=| computerUserIds)
      .where(.status == RequestStatus.pending)
      .count(in: context.db)

    return .init(
      handledCount: result.handled.count,
      skippedCount: result.skippedCount,
      remainingCount: remainingCount,
    )
  }
}

private func normalizedUnlockBundleId(_ bundleId: String) -> String {
  var id = bundleId
  if id.first == "." {
    id.removeFirst()
  }
  let parts = id.split(separator: ".", maxSplits: 1)
  if parts.count == 2,
     parts[0].count == 10,
     parts[0].allSatisfy({ $0.isNumber || ($0.isLetter && $0.isUppercase) }) {
    id = String(parts[1])
  }
  return id.lowercased()
}

private func unrestrictedMacAppScopeKey(_ scope: AppScope.Single) -> String {
  switch scope.normalized {
  case .bundleId(let id): "bundle:\(id)"
  case .identifiedAppSlug(let slug): "slug:\(slug)"
  }
}

private func createAccountDefaultKeychain(
  for person: Child,
  in db: any DuetSQL.Client,
) async throws -> Keychain {
  let keychain = try await db.create(Keychain(
    parentId: person.parentId,
    name: "\(person.name)'s Keychain",
    isPublic: false,
    description: "Keys created while responding to \(person.name)'s unlock requests.",
  ))
  try await db.create(ChildKeychain(childId: person.id, keychainId: keychain.id))
  return keychain
}
