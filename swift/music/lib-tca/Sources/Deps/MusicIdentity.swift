import Dependencies
import DependenciesMacros
import DeviceIdentity
import Foundation
import GertieApp
import IOSAppsRoute
import PairQLClient

@DependencyClient
struct MusicIdentityClient: Sendable {
  var resolve: @MainActor @Sendable () -> Resolution = { .init() }
  var report: @MainActor @Sendable () async -> Resolution = { .init() }
  var connection: @Sendable () async throws -> MusicAppConnection?
  var completeMigration: @Sendable () async throws -> Void

  struct Resolution: Equatable, Sendable {
    var available = true
    var migrationPending = false
    var needsReport = false
    var deviceId: UUID?
    var connection: MusicAppConnection?
  }
}

extension MusicIdentityClient: DependencyKey {
  static var liveValue: Self {
    .init(
      resolve: { MusicIdentity.shared.resolve() },
      report: { await MusicIdentity.shared.report() },
      connection: { try await MusicIdentity.shared.connection() },
      completeMigration: { try await MusicIdentity.shared.completeMigration() },
    )
  }

  static var testValue: Self {
    .init(
      resolve: { .init() },
      report: { .init() },
      connection: {
        @Dependency(\.keychain) var keychain
        return try keychain.readConnection()
      },
      completeMigration: {},
    )
  }

  func validate(_ connection: MusicAppConnection) async throws {
    try Task.checkCancellation()
    guard try await self.connection() == connection else { throw CancellationError() }
  }
}

extension DependencyValues {
  var musicIdentity: MusicIdentityClient {
    get { self[MusicIdentityClient.self] }
    set { self[MusicIdentityClient.self] = newValue }
  }
}

@MainActor
final class MusicIdentity {
  static let shared = MusicIdentity()
  private let keychain: KeychainClient
  private let storage: IdentityStorage
  private let resolver: IdentityResolver
  private var storageAvailable = false
  private let telemetry: @MainActor (IdentityResolver.Event) -> Void

  var deviceId: UUID? { self.storageAvailable ? self.resolver.deviceId : nil }
  var migrationPending: Bool {
    get throws { try self.keychain.migrationPending }
  }

  init(
    keychain: KeychainClient = .liveValue,
    storage: IdentityStorage? = nil,
    metadata: (() -> IdentityResolver.Metadata)? = nil,
    clearCaches: @escaping @MainActor (UUID) throws -> Void = MusicIdentity.clearCaches,
    report: (@MainActor (ReportIdentityTransition.Input) async throws
      -> ReportIdentityTransition.Output)? = nil,
    telemetry: @escaping @MainActor (IdentityResolver.Event) -> Void = MusicIdentity.log,
  ) {
    self.keychain = keychain
    self.telemetry = telemetry
    let storage = storage ?? IdentityKeychain(configuration: .init(
      privateAccessGroup: Bundle.main.object(forInfoDictionaryKey: "IdentityPrivateAccessGroup")
        as? String ?? "WFN83LM943.com.netrivet.gertrude.music",
      appMemoryAccount: KeychainClient.Key.deviceId.secAttrAccount,
      sharedAccessGroup: Bundle.main.object(forInfoDictionaryKey: "IdentitySharedAccessGroup")
        as? String ?? "WFN83LM943.com.netrivet.gertrude.identity",
    )).storage
    self.storage = storage
    let transport = PairQLClient<IOSAppsRoute>(endpoint: { GertrudeIOSApp.apiBaseURL() })
    self.resolver = IdentityResolver(storage: storage, hooks: .init(
      metadata: metadata ?? {
        @Dependency(\.device) var device
        return .live(
          app: .music,
          modelIdentifier: device.modelIdentifier(),
          appVersion: device.appVersion(),
        )
      },
      proofToken: { keychain.loadConnection()?.token },
      credentialDeviceId: { keychain.loadConnection()?.deviceId },
      clearDeviceBoundState: {
        var migration = try keychain._load(.migration).map {
          try JSONDecoder().decode(Migration.self, from: $0)
        } ?? Migration()
        if let childId = try keychain.readConnection()?.childId {
          migration.childId = childId
        }
        try keychain._save(.migration, JSONEncoder().encode(migration))
        if let childId = migration.childId { try clearCaches(childId) }
        try keychain.delete(.connection)
      },
      markMigration: {
        if try keychain._load(.migration) == nil {
          try keychain._save(.migration, JSONEncoder().encode(Migration()))
        }
      },
      migrationPending: { try keychain.migrationPending },
      applyCredentials: { output in
        let previous = try keychain.readConnection()
        guard let token = output.token, let childId = output.childId else {
          if previous?.deviceId != output.deviceId { try keychain.delete(.connection) }
          return
        }
        try keychain.writeConnection(.init(
          token: token,
          childId: childId,
          childName: previous?.childId == childId ? previous?.childName ?? "" : "",
          deviceId: output.deviceId,
        ))
      },
      publishIdentity: { _ in },
      report: report ?? {
        try await transport.call(
          ReportIdentityTransition.self,
          .unauthed(.reportIdentityTransition($0)),
        )
      },
      telemetry: telemetry,
    ))
  }

  func resolve() -> MusicIdentityClient.Resolution {
    do {
      _ = try self.keychain._load(.migration)
      if var connection = try self.keychain.readConnection(), connection.deviceId == nil {
        switch self.storage.read(.appMemory) {
        case .value(let data):
          guard let string = String(data: data, encoding: .utf8),
                let id = UUID(uuidString: string) else {
            throw CancellationError()
          }
          connection.deviceId = id
          try self.keychain.writeConnection(connection)
        case .absent:
          try self.keychain.delete(.connection)
        case .unknown:
          self.storageAvailable = false
          return .init(available: false)
        }
      }
      self.storageAvailable = true
    } catch {
      self.storageAvailable = false
      self.telemetry(.consumerFailure)
      return .init(available: false)
    }
    let outcome = self.resolver.resolveOnForeground()
    return self.resolution(needsReport: outcome == .retry || self.isAdopted(outcome))
  }

  func report() async -> MusicIdentityClient.Resolution {
    _ = await self.resolver.reportPendingTransition()
    return self.resolution(needsReport: false)
  }

  func connection() throws -> MusicAppConnection? {
    guard let deviceId = self.deviceId,
          let connection = try self.keychain.readConnection(),
          connection.deviceId == deviceId else { return nil }
    return connection
  }

  func completeMigration() throws {
    guard try self.connection() != nil else { throw CancellationError() }
    try self.keychain.delete(.migration)
  }

  private func resolution(needsReport: Bool) -> MusicIdentityClient.Resolution {
    do {
      return try .init(
        available: self.deviceId != nil,
        migrationPending: self.migrationPending,
        needsReport: needsReport,
        deviceId: self.deviceId,
        connection: self.connection(),
      )
    } catch {
      self.storageAvailable = false
      self.telemetry(.consumerFailure)
      return .init(available: false)
    }
  }

  private func isAdopted(_ outcome: IdentityResolver.Outcome) -> Bool {
    if case .adopted = outcome { true } else { false }
  }

  private struct Migration: Codable {
    var childId: UUID?
  }

  private static func clearCaches(childId: UUID) throws {
    try ChildScopedDiskJSONCache<ApprovedMusicLibrary>(
      directory: ChildScopedDiskJSONCache<ApprovedMusicLibrary>
        .directory(named: "ApprovedMusicLibraryCache"),
    ).delete(childId: childId)
    try ChildScopedDiskJSONCache<PlaybackCheckpoint>(
      directory: ChildScopedDiskJSONCache<PlaybackCheckpoint>
        .directory(named: "PlaybackSessionCache"),
    ).delete(childId: childId)
  }

  private static func log(_ event: IdentityResolver.Event) {
    let id = switch event {
    case .resolution: "84407100"
    case .canaryMismatch: "805ddd69"
    case .persistentUnknownRead: "4a9a8cee"
    case .writeFailed: "58426fa7"
    case .invalidPendingTransition: "22f040dc"
    case .reportFailed: "4fea87e1"
    case .consumerFailure: "6bf203b3"
    case .childConflictPin: "f16c1152"
    }
    LibTCA.log(.info, .setup, id, detail: String(describing: event))
  }
}
