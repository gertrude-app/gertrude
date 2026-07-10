import DuetSQL
import Gertie
import PairQL

struct GetBatchUnlockRequestData: Pair {
  static let auth: ClientAuth = .parent
  typealias Input = Child.Id

  struct UnlockRequestData: PairOutput {
    let id: Api.UnlockRequest.Id
    let userId: Api.Child.Id
    let userName: String
    let status: RequestStatus
    let url: String?
    let domain: String?
    let ipAddress: String?
    let requestComment: String?
    let appName: String?
    let appSlug: String?
    let appBundleId: String?
    let appCategories: [String]
    let createdAt: Date
  }

  struct Output: PairOutput {
    var requests: [UnlockRequestData]
    var keychains: [KeychainSummary]
  }
}

// resolver

extension GetBatchUnlockRequestData: Resolver {
  static func resolve(with childId: Input, in context: ParentContext) async throws -> Output {
    let child = try await context.verifiedChild(from: childId)
    let computerUsers = try await child.computerUsers(in: context.db)
    let allRequests = try await UnlockRequest.query()
      .where(.computerUserId |=| computerUsers.map { .id($0) })
      .where(.status == RequestStatus.pending)
      .all(in: context.db)

    var keychains = try await child.keychains(in: context.db)
      .filter { $0.parentId == context.parent.id }

    if keychains.isEmpty {
      try await createDefaultKeychainIfNeeded(for: child, in: context.db)
      keychains = try await child.keychains(in: context.db)
        .filter { $0.parentId == context.parent.id }
    }

    var latestKeyDates: [Keychain.Id: Date] = [:]
    for keychain in keychains {
      let latestKey = try? await Key.query()
        .where(.keychainId == keychain.id)
        .orderBy(.createdAt, .desc)
        .first(in: context.db)
      latestKeyDates[keychain.id] = latestKey?.createdAt ?? keychain.createdAt
    }

    let sortedKeychains = keychains.sorted { a, b in
      let dateA = latestKeyDates[a.id] ?? a.createdAt
      let dateB = latestKeyDates[b.id] ?? b.createdAt
      return dateA > dateB
    }

    return try await Output(
      requests: allRequests.concurrentMap { try await .init(from: $0, in: context) },
      keychains: sortedKeychains.concurrentMap { try await .init(from: $0) },
    )
  }
}

extension GetBatchUnlockRequestData.UnlockRequestData {
  init(from request: UnlockRequest, in context: ParentContext) async throws {
    let userDevice = try await request.computerUser(in: context.db)
    let user = try await context.verifiedChild(from: userDevice.childId)

    let idManifest = try await getCachedAppIdManifest()
    let factory = AppDescriptorFactory(appIdManifest: idManifest)
    let app = factory.appDescriptor(for: request.appBundleId)

    self.init(
      id: request.id,
      userId: user.id,
      userName: user.name,
      status: request.status,
      url: request.url,
      domain: request.hostname,
      ipAddress: request.ipAddress,
      requestComment: request.requestComment,
      appName: app.displayName,
      appSlug: app.slug,
      appBundleId: request.appBundleId,
      appCategories: Array(app.categories),
      createdAt: request.createdAt,
    )
  }
}
