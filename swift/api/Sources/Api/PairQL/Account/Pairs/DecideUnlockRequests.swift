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
    let skippedCount: Int
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
        return bundleId.normalizedBundleId.lowercased()
      }
      let allowedBundleIds: Set<String>
      switch scope {
      case .bundleId(let bundleId):
        allowedBundleIds = [bundleId.normalizedBundleId.lowercased()]
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
          $0.bundleId.normalizedBundleId.lowercased()
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

    struct CreatedKey: Sendable {
      let key: Key
      let keychainName: String
    }

    struct TransactionResult: Sendable {
      let handled: [UnlockRequest]
      let skippedCount: Int
      let updatedKeychainIds: Set<Keychain.Id>
      let grantedApp: Bool
      let createdKeys: [CreatedKey]
    }

    let result = try await context.db.withTransaction { tx in
      try await tx
        .execute(
          raw: "SELECT id FROM parent.children WHERE id = \(bind: person.id.rawValue) FOR UPDATE",
        )
      let currentRequests = try await UnlockRequest.query().where(.id |=| allIds).all(in: tx)
      let requestsById = Dictionary(uniqueKeysWithValues: currentRequests.map { ($0.id, $0) })
      let needsDefaultKeychain = input.decisions.contains { decision in
        if case .acceptedKey(let keychainId, _, _, _) = decision.action {
          return keychainId == nil && decision.requestIds
            .contains { requestsById[$0]?.status == .pending }
        }
        return false
      }
      var eligibleKeychains = try await person.keychains(in: tx)
        .filter { $0.parentId == context.accountOwner.id && !$0.isPublic }
      let options = try await unlockRequestKeychainOptions(for: person, in: tx)
      var defaultKeychainId = unlockRequestDefaultKeychainId(options)
      if needsDefaultKeychain, defaultKeychainId == nil {
        let keychain = try await createAccountDefaultKeychain(for: person, in: tx)
        eligibleKeychains.append(keychain)
        defaultKeychainId = keychain.id
      }
      let keychainsById = Dictionary(
        uniqueKeysWithValues: eligibleKeychains.map { ($0.id, $0) },
      )
      let defaultKeychain = defaultKeychainId.flatMap { keychainsById[$0] }
      var existingKeysByKeychainId: [Keychain.Id: [Key]] = [:]
      var existingApps = try await person.unrestrictedMacApps(in: tx)
      var handled: [UnlockRequest] = []
      var skippedCount = 0
      var updatedKeychainIds = Set<Keychain.Id>()
      var grantedApp = false
      var createdKeys: [CreatedKey] = []

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
          if let expiration, expiration <= get(dependency: \.date.now) {
            throw context.error(
              id: "5b05b0eb",
              type: .badRequest,
              debugMessage: "expired unlock permission",
              userMessage: "Choose a future expiration for this permission.",
            )
          }
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
          if existingKeys?
            .contains(where: { $0.key == key && $0.deletedAt == expiration && $0.comment == comment
            }) != true {
            let created = try await tx.create(Key(
              keychainId: keychain.id,
              key: key,
              comment: comment,
              deletedAt: expiration,
            ))
            existingKeys?.append(created)
            createdKeys.append(.init(key: created, keychainName: keychain.name))
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
          if let index = existingApps
            .firstIndex(where: { $0.scope.normalized == scope.normalized }) {
            if existingApps[index].schedule != nil {
              existingApps[index].schedule = nil
              try await tx.update(existingApps[index])
              grantedApp = true
            }
          } else {
            try await existingApps.append(tx.create(UnrestrictedMacApp(
              scope: scope,
              childId: person.id,
            )))
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
        createdKeys: createdKeys,
      )
    }

    for keychainId in result.updatedKeychainIds {
      await sendUnlockEvent(.userUpdated, to: .usersWith(keychain: keychainId))
    }
    if result.grantedApp {
      await sendUnlockEvent(.userUpdated, to: .user(person.id))
      await recordDashSecurityEvent(
        .unrestrictedAppsChanged,
        "child: \(person.name)",
        in: context,
      )
    }
    for created in result.createdKeys {
      await recordDashSecurityEvent(
        .keyCreated,
        "key opening \(created.key.key.simpleDescription) added to keychain '\(created.keychainName)'",
        in: context,
      )
    }

    let computerUsersById = Dictionary(
      uniqueKeysWithValues: computerUsers.map { ($0.id, $0) },
    )
    for (computerUserId, handled) in Dictionary(grouping: result.handled, by: \.computerUserId) {
      guard let computerUser = computerUsersById[computerUserId] else { continue }
      let commented = handled
        .filter {
          $0.responseComment?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }
      let aggregate = handled.filter { !commented.map(\.id).contains($0.id) }
      if computerUser.appSemver >= Semver("2.9.0"), !aggregate.isEmpty {
        await sendUnlockEvent(
          .unlockRequestsHandled(
            ids: aggregate.map(\.id.rawValue),
            accepted: aggregate.count { $0.status == .accepted },
            rejected: aggregate.count { $0.status == .rejected },
            targets: aggregate.compactMap(\.target).sorted(),
          ),
          to: .userDevice(computerUser.id),
        )
      }
      for request in computerUser.appSemver >= Semver("2.9.0") ? commented : handled {
        await sendUnlockEvent(
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

    return .init(skippedCount: result.skippedCount)
  }
}

private func sendUnlockEvent(
  _ message: WebSocketMessage.FromApiToApp,
  to matcher: AppEvent.Matcher,
) async {
  do {
    try await with(dependency: \.websockets).send(message, to: matcher)
  } catch {
    get(dependency: \.logger).error("Failed to deliver unlock decision: \(error)")
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
