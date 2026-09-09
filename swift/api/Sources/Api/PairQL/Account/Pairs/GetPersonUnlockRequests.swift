import DuetSQL
import PairQL

struct GetPersonUnlockRequests: Pair {
  static let auth: ClientAuth = .parent

  struct Input: PairInput {
    let personId: Child.Id
  }

  struct Request: PairNestable {
    let id: UnlockRequest.Id
    let url: String?
    let domain: String?
    let ipAddress: String?
    let requestComment: String?
    let appName: String?
    let appSlug: String?
    let appBundleId: String?
    let appIconHash: String?
    let appCategories: [String]
    let createdAt: Date
  }

  struct KeychainOption: PairNestable {
    let id: Keychain.Id
    let name: String
    let numKeys: Int
  }

  struct Output: PairOutput {
    let personId: Child.Id
    let personName: String
    let requests: [Request]
    let keychains: [KeychainOption]
  }
}

extension GetPersonUnlockRequests: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    let legacy = try await GetBatchUnlockRequestData.resolve(
      with: person.id,
      in: context.legacyContext,
    )
    return .init(
      personId: person.id,
      personName: person.name,
      requests: legacy.requests
        .sorted { $0.createdAt < $1.createdAt }
        .map {
          .init(
            id: $0.id,
            url: $0.url,
            domain: $0.domain,
            ipAddress: $0.ipAddress,
            requestComment: $0.requestComment,
            appName: $0.appName,
            appSlug: $0.appSlug,
            appBundleId: $0.appBundleId,
            appIconHash: $0.appIconHash,
            appCategories: $0.appCategories,
            createdAt: $0.createdAt,
          )
        },
      keychains: legacy.keychains.map {
        .init(id: $0.id, name: $0.name, numKeys: $0.numKeys)
      },
    )
  }
}
