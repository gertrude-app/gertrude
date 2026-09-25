import DuetSQL
import Gertie
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
    let schedule: GetPersonMacSettings.KeychainSchedule?
    let otherPeople: [String]
  }

  struct Output: PairOutput {
    let personName: String
    let requests: [Request]
    let keychains: [KeychainOption]
    let defaultKeychainId: Keychain.Id?
  }
}

extension GetPersonUnlockRequests: Resolver {
  static func resolve(
    with input: Input,
    in context: AccountOwnerContext,
  ) async throws -> Output {
    let person = try await context.person(input.personId)
    let devices = try await person.computerUsers(in: context.db)
    let requests = try await UnlockRequest.query()
      .where(.computerUserId |=| devices.map(\.id))
      .where(.status == RequestStatus.pending)
      .all(in: context.db)
      .sorted {
        $0.createdAt == $1.createdAt ? $0.id.lowercased < $1.id.lowercased : $0.createdAt < $1
          .createdAt
      }
    let bundleIds = Set(requests.flatMap { [$0.appBundleId, $0.appBundleId.normalizedBundleId] })
    let cataloged = try await CatalogedApp.query()
      .where(.bundleId |=| Array(bundleIds))
      .all(in: context.db)
    let icons = cataloged.reduce(into: [String: CatalogedApp]()) {
      $0[$1.bundleId.normalizedBundleId] = $1
    }
    let factory = try await AppDescriptorFactory(appIdManifest: getCachedAppIdManifest())
    let keychains = try await unlockRequestKeychainOptions(for: person, in: context.db)
    return .init(
      personName: person.name,
      requests: requests.map { request in
        let app = factory.appDescriptor(for: request.appBundleId)
        let catalog = icons[request.appBundleId.normalizedBundleId]
        return .init(
          id: request.id,
          url: request.url,
          domain: request.hostname,
          ipAddress: request.ipAddress,
          requestComment: request.requestComment,
          appName: catalog?.name ?? app.displayName,
          appSlug: app.slug,
          appBundleId: request.appBundleId,
          appIconHash: catalog?.iconContentHash,
          appCategories: Array(app.categories),
          createdAt: request.createdAt,
        )
      },
      keychains: keychains,
      defaultKeychainId: unlockRequestDefaultKeychainId(keychains),
    )
  }
}

func unlockRequestKeychainOptions(
  for person: Child,
  in db: any DuetSQL.Client,
) async throws -> [GetPersonUnlockRequests.KeychainOption] {
  let assigned = try await ChildKeychain.query().where(.childId == person.id).all(in: db)
  let keychains = try await Keychain.query()
    .where(.id |=| assigned.map(\.keychainId))
    .where(.parentId == person.parentId)
    .where(.isPublic == false)
    .all(in: db)
    .sorted {
      $0.createdAt == $1.createdAt ? $0.id.lowercased < $1.id.lowercased : $0.createdAt < $1
        .createdAt
    }
  let assignments = try await ChildKeychain.query()
    .where(.keychainId |=| keychains.map(\.id)).all(in: db)
  let people = try await Child.query().where(.parentId == person.parentId).all(in: db)
  return keychains.map { keychain in
    let otherIds = Set(assignments
      .filter { $0.keychainId == keychain.id && $0.childId != person.id }.map(\.childId))
    return .init(
      id: keychain.id,
      name: keychain.name,
      schedule: assigned.first { $0.keychainId == keychain.id }?.schedule
        .map(GetPersonMacSettings.KeychainSchedule.init),
      otherPeople: people.filter { otherIds.contains($0.id) }.map(\.name).sorted(),
    )
  }
}

func unlockRequestDefaultKeychainId(
  _ options: [GetPersonUnlockRequests.KeychainOption],
) -> Keychain.Id? {
  options.first { $0.schedule == nil && $0.otherPeople.isEmpty }?.id
}
