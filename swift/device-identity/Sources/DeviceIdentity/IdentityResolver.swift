import Dependencies
import Foundation
import GertieApp
import IOSAppsRoute
import Security

@MainActor
public final class IdentityResolver {
  @Dependency(\.uuid) private var uuid

  public private(set) var deviceId: UUID?
  private let storage: IdentityStorage
  private let hooks: Hooks
  private var inFlight: Task<Outcome, Never>?
  private var unknownReads: [IdentitySlot: (status: Int32, count: Int)] = [:]

  public init(storage: IdentityStorage, hooks: Hooks) {
    self.storage = storage
    self.hooks = hooks
  }

  public func resolveOnForeground() -> Outcome {
    if self.inFlight != nil {
      return self.deviceId.map(Outcome.adopted) ?? .retry
    }
    let outcome = self.resolve()
    self.record(outcome)
    return outcome
  }

  public func reportPendingTransition() async -> Outcome {
    if let inFlight = self.inFlight { return await inFlight.value }
    let localIdentity = self.deviceId
    let task = Task<Outcome, Never> {
      switch self.readPending() {
      case .value(let pending):
        await self.report(pending)
      case .absent:
        self.deviceId.map(Outcome.steady) ?? .deferred
      case .unknown:
        .deferred
      }
    }
    self.inFlight = task
    let outcome = await task.value
    self.inFlight = nil
    if localIdentity.map(Outcome.adopted) != outcome {
      self.record(outcome)
    }
    return outcome
  }

  private func record(_ outcome: Outcome) {
    if case .steady = outcome {} else {
      self.hooks.telemetry(.resolution(outcome, matchesLiveVendorId: self.deviceId.map {
        $0 == self.hooks.metadata().liveVendorId
      }))
    }
  }

  private func readPending() -> IdentityRead<PendingIdentityTransition> {
    switch self.storage.read(.pendingTransition) {
    case .unknown(errSecDecode):
      return self.discardCorruptPending()
    case .unknown(let status):
      return .unknown(status)
    case .value(let data):
      guard let pending = try? JSONDecoder().decode(PendingIdentityTransition.self, from: data)
      else {
        return self.discardCorruptPending()
      }
      return .value(pending)
    case .absent: return .absent
    }
  }

  private func discardCorruptPending() -> IdentityRead<PendingIdentityTransition> {
    self.hooks.telemetry(.invalidPendingTransition)
    guard let identity = self.storage.readId(.identity).value,
          self.storage.readId(.canary).value == identity,
          self.writeId(.appMemory, identity),
          self.check(self.storage.delete(.pendingTransition), slot: .pendingTransition) else {
      return .unknown(errSecDecode)
    }
    return .absent
  }

  private func resolve() -> Outcome {
    switch self.readPending() {
    case .unknown:
      self.deviceId = nil
      return .deferred
    case .value(let pending):
      return self.prepare(pending)
    case .absent: break
    }

    let a = self.storage.readId(.identity)
    let b = self.storage.readId(.canary)
    let c = self.storage.readId(.appMemory)
    var unknown = false
    for (slot, read) in [(IdentitySlot.identity, a), (.canary, b), (.appMemory, c)] {
      if case .unknown(let status) = read {
        unknown = true
        if a.value != nil,
           ![errSecInteractionNotAllowed, errSecMissingEntitlement, errSecNotAvailable]
           .contains(status) {
          let prior = self.unknownReads[slot]
          let count = prior?.status == status ? (prior?.count ?? 0) + 1 : 1
          self.unknownReads[slot] = (status, count)
          if count == 5 { self.hooks.telemetry(.persistentUnknownRead(slot, status)) }
        } else {
          self.unknownReads[slot] = nil
        }
      } else {
        self.unknownReads[slot] = nil
      }
    }
    guard !unknown else {
      self.deviceId = nil
      return .deferred
    }
    self.deviceId = nil

    guard let identity = a.value else {
      let id = c.value ?? self.hooks.metadata().liveVendorId ?? self.uuid()
      guard self.writeId(.canary, id) else { return .deferred }
      switch self.storage.add(.identity, Data(id.uuidString.utf8)) {
      case .success:
        return self.settle(id)
      case .duplicate:
        guard let winner = self.storage.readId(.identity).value,
              self.writeId(.canary, winner),
              self.writeId(.appMemory, c.value ?? winner) else { return .deferred }
        return self.resolve()
      case .failure(let status):
        self.hooks.telemetry(.writeFailed(.identity, status))
        return .deferred
      }
    }

    if b.value != identity {
      if let canary = b.value { self.hooks.telemetry(.canaryMismatch(identity, canary)) }
      let proof = self.hooks.proofToken()
      do {
        self.hooks.publishIdentity(nil)
        try self.hooks.clearDeviceBoundState()
      } catch {
        self.hooks.telemetry(.consumerFailure)
        return .deferred
      }
      let newId = self.uuid()
      let pending = PendingIdentityTransition(
        oldDeviceId: identity, newDeviceId: newId, kind: .migrated, proofToken: proof,
      )
      let recorded = self.savePending(pending)
      let written = self.writeId(.canary, newId) && self.writeId(.identity, newId)
      guard written else { return recorded ? .retry : .deferred }
      if recorded { return self.prepare(pending, alreadyCleared: true) }
      do {
        try self.hooks.markMigration()
      } catch {
        self.hooks.telemetry(.consumerFailure)
        return .deferred
      }
      return self.settle(newId, outcome: .migratedUnreported(newId))
    }

    guard let memory = c.value else { return self.settle(identity) }
    if memory == identity { return self.publish(identity, outcome: .steady(identity)) }
    let pending = PendingIdentityTransition(
      oldDeviceId: memory, newDeviceId: identity, kind: .sameDevice,
      proofToken: self.hooks.proofToken(),
    )
    guard self.savePending(pending) else { return .deferred }
    return self.prepare(pending)
  }

  private func prepare(
    _ pending: PendingIdentityTransition,
    alreadyCleared: Bool = false,
  ) -> Outcome {
    self.deviceId = nil
    if pending.kind == .sameDevice, !self.hooks.migrationPending() {
      let identity = self.hooks.credentialDeviceId() ?? pending.oldDeviceId
      return self.publish(identity, outcome: .adopted(identity))
    }
    do {
      self.hooks.publishIdentity(nil)
      if !alreadyCleared { try self.hooks.clearDeviceBoundState() }
      try self.hooks.markMigration()
    } catch {
      self.hooks.telemetry(.consumerFailure)
      return .deferred
    }
    return .retry
  }

  private func report(_ pending: PendingIdentityTransition) async -> Outcome {
    guard self.prepare(pending) != .deferred else { return .retry }
    var resolvedAsMigration = false
    defer {
      if pending.kind == .sameDevice, !resolvedAsMigration, !self.hooks.migrationPending(),
         case .value = self.readPending() {
        _ = self.prepare(pending)
      }
    }
    let metadata = self.hooks.metadata()
    let response: ReportIdentityTransition.Output
    do {
      response = try await self.hooks.report(.init(
        app: metadata.app,
        oldDeviceId: pending.oldDeviceId,
        newDeviceId: pending.newDeviceId,
        kind: pending.kind,
        proofToken: pending.proofToken,
        modelIdentifier: metadata.modelIdentifier,
        iosVersion: metadata.iosVersion,
        appVersion: metadata.appVersion,
        liveVendorId: metadata.liveVendorId,
      ))
    } catch {
      self.hooks.telemetry(.reportFailed)
      return .retry
    }
    do {
      if response.reason == .resolvedAsMigration {
        resolvedAsMigration = true
        self.deviceId = nil
        self.hooks.publishIdentity(nil)
        try self.hooks.clearDeviceBoundState()
        try self.hooks.markMigration()
      }
      if response.reason != .childConflictPin {
        guard self.writeId(.canary, response.deviceId),
              self.writeId(.identity, response.deviceId) else { return .retry }
      } else {
        self.hooks.telemetry(.childConflictPin)
      }
      guard self.writeId(.appMemory, response.deviceId) else { return .retry }
      try self.hooks.applyCredentials(response)
      guard self.check(self.storage.delete(.pendingTransition), slot: .pendingTransition) else {
        return .retry
      }
    } catch {
      self.hooks.telemetry(.consumerFailure)
      return .retry
    }
    let outcome: Outcome = if response.reason == .childConflictPin {
      .pinned(response.deviceId)
    } else if pending.kind == .migrated || response.reason == .resolvedAsMigration {
      .migrated(response.deviceId)
    } else {
      .adopted(response.deviceId)
    }
    return self.publish(response.deviceId, outcome: outcome)
  }

  private func savePending(_ pending: PendingIdentityTransition) -> Bool {
    guard let data = try? JSONEncoder().encode(pending) else { return false }
    return self.check(self.storage.write(.pendingTransition, data), slot: .pendingTransition)
  }

  private func writeId(_ slot: IdentitySlot, _ id: UUID) -> Bool {
    self.check(self.storage.write(slot, Data(id.uuidString.utf8)), slot: slot)
  }

  private func check(_ result: IdentityWrite, slot: IdentitySlot) -> Bool {
    switch result {
    case .success: return true
    case .duplicate:
      self.hooks.telemetry(.writeFailed(slot, errSecDuplicateItem))
    case .failure(let status):
      self.hooks.telemetry(.writeFailed(slot, status))
    }
    return false
  }

  private func settle(_ id: UUID, outcome: Outcome? = nil) -> Outcome {
    guard self.writeId(.appMemory, id) else { return .deferred }
    return self.publish(id, outcome: outcome ?? .steady(id))
  }

  private func publish(_ id: UUID, outcome: Outcome) -> Outcome {
    self.deviceId = id
    self.hooks.publishIdentity(id)
    return outcome
  }
}

public extension IdentityResolver {
  enum Outcome: Equatable, Sendable {
    case steady(UUID)
    case adopted(UUID)
    case migrated(UUID)
    case migratedUnreported(UUID)
    case pinned(UUID)
    case retry
    case deferred
  }

  enum Event: Equatable, Sendable {
    case resolution(Outcome, matchesLiveVendorId: Bool?)
    case canaryMismatch(UUID, UUID)
    case persistentUnknownRead(IdentitySlot, Int32)
    case writeFailed(IdentitySlot, Int32)
    case invalidPendingTransition
    case reportFailed
    case consumerFailure
    case childConflictPin
  }

  struct Metadata: Sendable {
    public var app: GertrudeIOSApp
    public var modelIdentifier: String
    public var iosVersion: String
    public var appVersion: String
    public var liveVendorId: UUID?

    public init(
      app: GertrudeIOSApp,
      modelIdentifier: String,
      iosVersion: String,
      appVersion: String,
      liveVendorId: UUID?,
    ) {
      self.app = app
      self.modelIdentifier = modelIdentifier
      self.iosVersion = iosVersion
      self.appVersion = appVersion
      self.liveVendorId = liveVendorId
    }
  }

  struct Hooks {
    public var metadata: () -> Metadata
    public var proofToken: () -> UUID?
    public var credentialDeviceId: () -> UUID?
    public var clearDeviceBoundState: () throws -> Void
    public var markMigration: () throws -> Void
    public var migrationPending: () -> Bool
    public var applyCredentials: (ReportIdentityTransition.Output) throws -> Void
    public var publishIdentity: (UUID?) -> Void
    public var report: @MainActor (ReportIdentityTransition.Input) async throws
      -> ReportIdentityTransition.Output
    public var telemetry: (Event) -> Void

    public init(
      metadata: @escaping () -> Metadata,
      proofToken: @escaping () -> UUID?,
      credentialDeviceId: @escaping () -> UUID?,
      clearDeviceBoundState: @escaping () throws -> Void,
      markMigration: @escaping () throws -> Void,
      migrationPending: @escaping () -> Bool,
      applyCredentials: @escaping (ReportIdentityTransition.Output) throws -> Void,
      publishIdentity: @escaping (UUID?) -> Void,
      report: @escaping @MainActor (ReportIdentityTransition.Input) async throws
        -> ReportIdentityTransition.Output,
      telemetry: @escaping (Event) -> Void,
    ) {
      self.metadata = metadata
      self.proofToken = proofToken
      self.credentialDeviceId = credentialDeviceId
      self.clearDeviceBoundState = clearDeviceBoundState
      self.markMigration = markMigration
      self.migrationPending = migrationPending
      self.applyCredentials = applyCredentials
      self.publishIdentity = publishIdentity
      self.report = report
      self.telemetry = telemetry
    }
  }
}
