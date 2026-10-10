import Dependencies
import DependenciesMacros
import DeviceIdentity
import Foundation
import GertieApp
import IOSAppsRoute
import PairQLClient
import PodcastRoute
import SQLiteData

@DependencyClient
struct PodcastIdentityClient: Sendable {
  var resolve: @MainActor @Sendable () -> Resolution = { .init() }
  var report: @MainActor @Sendable () async -> Resolution = { .init() }
  var current: @MainActor @Sendable () -> Resolution = { .init() }
  var saveToken: @MainActor @Sendable (UUID, UUID?) throws -> Void
  var removeToken: @MainActor @Sendable () throws -> Void
  var completeMigration: @MainActor @Sendable () throws -> Void

  struct Resolution: Equatable, Sendable {
    var available = true
    var migrationPending = false
    var needsReport = false
    var deviceId: UUID?
    var connection: PodcastConnection?
  }

  @MainActor
  func validate(_ session: Resolution) throws {
    try Task.checkCancellation()
    let current = self.current()
    guard current.available, session.available,
          current.deviceId == session.deviceId,
          current.connection == session.connection,
          current.migrationPending == session.migrationPending else {
      throw CancellationError()
    }
  }

  @MainActor
  func acceptTrialStatus(_ output: GetTrialStatus.Output, for session: Resolution) throws {
    try self.validate(session)
    switch output {
    case .trial(let expiresAt):
      _ = try CurrentSubscription.set(status: .trialing, expiringAt: expiresAt)
    case .trialExpired(let since):
      _ = try CurrentSubscription.set(status: .unpaid, expiringAt: since)
    case .legacyGrandfathered(let accessEndsAt, let showMigrationNag, _):
      _ = try CurrentSubscription.set(
        status: .legacy, expiringAt: accessEndsAt, legacyMigrationNag: showMigrationNag,
      )
    case .connected(let token, let childId, _, let subscription):
      try self.saveToken(token, childId)
      subscription.writeLocal(now: dep(\.date.now))
    }
  }

  @MainActor
  func acceptAccountStatus(_ output: GetAccountStatus.Output, for session: Resolution) throws {
    try self.validate(session)
    output.subscription.writeLocal(now: dep(\.date.now))
  }
}

extension PodcastIdentityClient: DependencyKey {
  static var liveValue: Self {
    .init(
      resolve: { PodcastIdentity.shared.resolve() },
      report: { await PodcastIdentity.shared.report() },
      current: { PodcastIdentity.shared.resolution() },
      saveToken: { try PodcastIdentity.shared.saveToken($0, childId: $1) },
      removeToken: { try PodcastIdentity.shared.removeToken() },
      completeMigration: { try PodcastIdentity.shared.completeMigration() },
    )
  }

  static var testValue: Self {
    .init(
      resolve: { .init() },
      report: { .init() },
      current: { .init() },
      saveToken: { token, _ in dep(\.keychain).save(amToken: token) },
      removeToken: { dep(\.keychain).deleteAmToken() },
      completeMigration: {},
    )
  }
}

extension DependencyValues {
  var podcastIdentity: PodcastIdentityClient {
    get { self[PodcastIdentityClient.self] }
    set { self[PodcastIdentityClient.self] = newValue }
  }
}

@MainActor
final class PodcastIdentity {
  static let shared = PodcastIdentity()
  private let keychain: KeychainClient
  private let storage: IdentityStorage
  private let resolver: IdentityResolver
  private let metadata: () -> IdentityResolver.Metadata
  private let migrateLegacy: (UUID, UUID) async throws -> Void
  private let telemetry: (IdentityResolver.Event) -> Void
  private var storageAvailable = false

  var deviceId: UUID? { self.storageAvailable ? self.resolver.deviceId : nil }

  init(
    keychain: KeychainClient = .liveValue,
    storage: IdentityStorage? = nil,
    metadata: (() -> IdentityResolver.Metadata)? = nil,
    clearState: @escaping @MainActor () throws -> Void = PodcastIdentity.clearState,
    report: (@MainActor (ReportIdentityTransition.Input) async throws
      -> ReportIdentityTransition.Output)? = nil,
    migrateLegacy: ((UUID, UUID) async throws -> Void)? = nil,
    telemetry: @escaping @MainActor (IdentityResolver.Event) -> Void = PodcastIdentity.log,
  ) {
    self.keychain = keychain
    self.telemetry = telemetry
    self.migrateLegacy = migrateLegacy ?? { try await ApiClient.liveValue.migrateDeviceId($0, $1) }
    let storage = storage ?? IdentityKeychain(configuration: .init(
      privateAccessGroup: Bundle.main.object(forInfoDictionaryKey: "IdentityPrivateAccessGroup")
        as? String ?? "WFN83LM943.com.netrivet.gertrude.am",
      appMemoryAccount: KeychainClient.Key.deviceId.secAttrAccount,
      sharedAccessGroup: Bundle.main.object(forInfoDictionaryKey: "IdentitySharedAccessGroup")
        as? String ?? "WFN83LM943.com.netrivet.gertrude.identity",
    )).storage
    self.storage = storage
    let transport = PairQLClient<IOSAppsRoute>(endpoint: { GertrudeIOSApp.apiBaseURL() })
    let metadata = metadata ?? {
      IdentityResolver.Metadata.live(
        app: .podcasts,
        modelIdentifier: dep(\.device).modelIdentifier(),
        appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0",
      )
    }
    self.metadata = metadata
    self.resolver = IdentityResolver(storage: storage, hooks: .init(
      metadata: metadata,
      proofToken: { try? keychain.readConnection()?.token },
      credentialDeviceId: { try? keychain.readConnection()?.deviceId },
      clearDeviceBoundState: {
        try keychain._save(.migration, Data([1]))
        try clearState()
        try keychain.removeConnection()
      },
      markMigration: { try keychain._save(.migration, Data([1])) },
      migrationPending: { try keychain.migrationPending },
      applyCredentials: { output in
        guard let token = output.token else {
          if try keychain.readConnection()?.deviceId != output.deviceId {
            try keychain.removeConnection()
          }
          return
        }
        try keychain.writeConnection(.init(
          token: token, deviceId: output.deviceId, childId: output.childId,
        ))
      },
      publishIdentity: { _ in },
      report: report ?? {
        try await transport.call(
          ReportIdentityTransition.self, .unauthed(.reportIdentityTransition($0)),
        )
      },
      telemetry: telemetry,
    ))
  }

  func resolve() -> PodcastIdentityClient.Resolution {
    do {
      _ = try self.keychain.migrationPending
      if try self.keychain.readConnection() == nil,
         let data = try self.keychain._load(.amToken) {
        guard let string = String(data: data, encoding: .utf8),
              let token = UUID(uuidString: string) else { throw CancellationError() }
        switch self.storage.read(.appMemory) {
        case .value(let data):
          guard let string = String(data: data, encoding: .utf8),
                let deviceId = UUID(uuidString: string) else { throw CancellationError() }
          try self.keychain.writeConnection(.init(token: token, deviceId: deviceId))
        case .absent:
          try self.keychain._save(.orphanedAmToken, data)
          try self.keychain.delete(.amToken)
        case .unknown:
          throw CancellationError()
        }
      }
      try self.prepareLegacyMigration()
      self.storageAvailable = true
    } catch {
      self.storageAvailable = false
      self.telemetry(.consumerFailure)
      return .init(available: false)
    }
    let outcome = self.resolver.resolveOnForeground()
    var needsReport = outcome == .retry
    if case .adopted = outcome { needsReport = true }
    if (try? self.keychain._load(.legacyMigration)) != nil { needsReport = true }
    return self.resolution(needsReport: needsReport)
  }

  func report() async -> PodcastIdentityClient.Resolution {
    if let data = try? self.keychain._load(.legacyMigration),
       let legacy = try? JSONDecoder().decode(LegacyMigration.self, from: data) {
      do {
        try await self.migrateLegacy(legacy.old, legacy.new)
        try self.keychain.delete(.legacyMigration)
      } catch {
        self.telemetry(.reportFailed)
      }
    }
    _ = await self.resolver.reportPendingTransition()
    return self.resolution()
  }

  func resolution(needsReport: Bool = false) -> PodcastIdentityClient.Resolution {
    do {
      let connection = try self.keychain.readConnection()
      return try .init(
        available: self.deviceId != nil,
        migrationPending: self.keychain.migrationPending,
        needsReport: needsReport,
        deviceId: self.deviceId,
        connection: connection?.deviceId == self.deviceId ? connection : nil,
      )
    } catch {
      self.storageAvailable = false
      self.telemetry(.consumerFailure)
      return .init(available: false)
    }
  }

  func saveToken(_ token: UUID, childId: UUID?) throws {
    guard let deviceId = self.deviceId else { throw CancellationError() }
    try self.keychain.writeConnection(.init(token: token, deviceId: deviceId, childId: childId))
  }

  func removeToken() throws {
    try self.keychain.removeConnection()
  }

  func completeMigration() throws {
    guard self.deviceId != nil else { throw CancellationError() }
    try self.keychain.delete(.migration)
  }

  private struct LegacyMigration: Codable {
    var old: UUID
    var new: UUID
  }

  // we record the ios vendor id as our device id, same as
  // in the ios app, to correlate installs between apps
  // prior to 1.4.0 we used a random uuid as identifier
  private func prepareLegacyMigration() throws {
    let pending = try self.keychain._load(.legacyMigration).map {
      try JSONDecoder().decode(LegacyMigration.self, from: $0)
    }
    switch self.storage.read(.appMemory) {
    case .unknown:
      throw CancellationError()
    case .value:
      return
    case .absent:
      let legacy: LegacyMigration
      if let pending {
        legacy = pending
      } else {
        guard let data = try self.keychain._load(.installId),
              let string = String(data: data, encoding: .utf8),
              let old = UUID(uuidString: string) else { return }
        guard let new = self.metadata().liveVendorId else { throw CancellationError() }
        legacy = LegacyMigration(old: old, new: new)
        try self.keychain._save(.legacyMigration, JSONEncoder().encode(legacy))
      }
      guard self.storage.write(.appMemory, Data(legacy.new.uuidString.utf8)) == .success else {
        throw CancellationError()
      }
    }
  }

  static func clearState() throws {
    dep(\.audio).reset()
    try dep(\.db).write { db in
      try Subscription.update {
        $0.status = #bind(Subscription.Status.unpaid)
        $0.expiresAt = #bind(Date.distantPast)
        $0.legacyMigrationNag = false
      }.execute(db)
      try NowPlayingModel.delete().execute(db)
      try CrossPromoDismissal.delete().execute(db)
    }
  }

  private static func log(_ event: IdentityResolver.Event) {
    let id = switch event {
    case .resolution: "de0b2521"
    case .canaryMismatch: "beae470b"
    case .persistentUnknownRead: "442b546f"
    case .writeFailed: "07624c2e"
    case .invalidPendingTransition: "6cced663"
    case .reportFailed: "8d52f68f"
    case .consumerFailure: "f961a170"
    case .childConflictPin: "2ff8675b"
    }
    LibTCA.log(.info, .setup, id, detail: String(describing: event))
  }
}
