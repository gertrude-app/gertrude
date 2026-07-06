import Combine
import ComposableArchitecture
import Core
import Dependencies
import Foundation
import Gertie
import NetworkExtension
import XCore

@testable import Filter

/// The filter system extension as a live sim "process": the real
/// `FilterProxy` (and through it the real `Filter` reducer + `FilterStore`)
/// constructed under a world-scoped dependency context, driven by the
/// conductor exactly where `FilterDataProvider` would drive it.
@MainActor final class FilterExtensionProcess {
  let version: String
  let xpcSubject: PassthroughSubject<XPCEvent.Filter, Never>
  private let dependencies: @Sendable (inout DependencyValues) -> Void
  private let proxy: FilterProxy

  var state: Filter.State { self.proxy.store.state }

  /// mirrors `FilterDataProvider.init`: proxy constructed (and
  /// `sendExtensionStarted` fired) at process init; the OS then calls
  /// `startFilter`, which applies settings and wires block-decision streaming.
  init(
    version: String,
    xpcSubject: PassthroughSubject<XPCEvent.Filter, Never>,
    dependencies: @escaping @Sendable (inout DependencyValues) -> Void,
  ) {
    self.version = version
    self.xpcSubject = xpcSubject
    self.dependencies = dependencies
    self.proxy = withDependencies(dependencies) { FilterProxy() }
  }

  func osStart() {
    withDependencies(self.dependencies) {
      self.proxy.sendExtensionStarted()
      self.proxy.startFilter()
    }
  }

  func osStop() {
    withDependencies(self.dependencies) {
      self.proxy.sendExtensionStopping()
    }
  }

  func handleNewFlow(_ dto: NEFilterFlow.DTO) -> NEFilterNewFlowVerdict {
    withDependencies(self.dependencies) {
      self.proxy.handleNewFlow(dto)
    }
  }

  func handleOutboundData(
    from dto: NEFilterFlow.DTO,
    offset: Int,
    bytes: Data,
  ) -> NEFilterDataVerdict {
    withDependencies(self.dependencies) {
      self.proxy.handleOutboundData(from: dto, readBytesStartOffset: offset, readBytes: bytes)
    }
  }
}

// conductor: filter extension lifecycle

extension VirtualMac {
  nonisolated static let filterVersion = "2.5.0"

  /// OS RULE M1 (provider process lifecycle): an enabled network extension's
  /// data-provider process is launched by the system — on boot, on activation,
  /// and on crash-recovery — never by the app directly. On start it constructs
  /// a fresh `FilterProxy` (losing all in-memory state) and reloads its durable
  /// state from disk. Device-verified 2026-07-06 (VM `gertrude-tahoe`, macOS
  /// 26.3): after a full reboot `nesessionmanager` submits the launchd job for
  /// `com.netrivet.gertrude.filter-extension` on its own and the provider is
  /// back `[activated enabled]` with no app action; a `kill -9` of the provider
  /// is followed ~2.5s later by `nesessionmanager` `Restarting → Starting with
  /// control unit N → Plugin started with pid M → running` (a NEW control unit).
  /// The respawn's own os_log shows `extensionStarted → startFilter →
  /// loadedPersistentState(userKeychains[…]) → receiveAlive` — i.e. the fresh
  /// process reloads persisted rules from disk on start, exactly as the sim
  /// models by constructing a new `FilterExtensionProcess`.
  @discardableResult
  func bootFilterExtension() async -> FilterExtensionProcess {
    let subject = PassthroughSubject<XPCEvent.Filter, Never>()
    let process = FilterExtensionProcess(
      version: Self.filterVersion,
      xpcSubject: subject,
      dependencies: self.filterDependencies(xpcSubject: subject),
    )
    self.filterProcess = process
    self.extensionState.setValue(.installedAndRunning)
    self.extensionStateChanges.send(.installedAndRunning)
    self.log(.filterExtensionLaunched)
    process.osStart()
    await self.settle()
    return process
  }

  /// OS RULE M1/M3: models the provider process dying WITHOUT (yet) respawning —
  /// the ~2.5s device gap during which there is no provider and traffic fails
  /// open. `openConnections` (leaked sockets) are preserved. Call
  /// `bootFilterExtension()` to model the OS respawn.
  func killFilterProviderProcess() {
    self.filterProcess = nil
    self.retainedConnectionUid.setValue(nil)
    self.log(.filterExtensionStopped)
  }

  /// OS RULE M5 / app-liveness: models the macapp telling the filter it is alive
  /// (the real `sendAlive`/`receiveAlive` path). The filter records
  /// `macappsAliveUntil = now+150s`; a protected user with rules whose liveness
  /// has NOT been recorded is failed CLOSED (`Decision+Flow` `macappAWOL`), so
  /// even allowlisted hosts are dropped. A crash+respawn loses the in-memory
  /// liveness record, so the app must re-send — device-verified 2026-07-06: the
  /// respawn log showed `receiveAlive(for: 502)` right after `loadedPersistentState`.
  func deliverAppAlive(_ uid: uid_t) async {
    self.filterProcess?.xpcSubject.send(.receivedAppMessage(.macappAlive(userId: uid)))
    await self.settle()
  }

  /// OS RULE M1 (crash-recovery): models a provider crash — the process dies
  /// (in-memory state lost), the OS respawns it, and the fresh process reloads
  /// durable state. In the sim the respawn is immediate; on device it was
  /// ~2.5s. The `leaked` connections opened during the gap are preserved (see
  /// OS RULE M4). Use this rather than `stopFilterExtension` when a scenario
  /// wants the "provider died and came back" shape.
  func crashAndRecoverFilterProvider() async {
    self.killFilterProviderProcess()
    await self.bootFilterExtension()
  }

  func stopFilterExtension() async {
    self.filterProcess?.osStop()
    self.filterProcess = nil
    self.retainedConnectionUid.setValue(nil)
    self.extensionState.setValue(.installedButNotRunning)
    self.extensionStateChanges.send(.installedButNotRunning)
    self.log(.filterExtensionStopped)
    await self.settle()
  }

  func seedFilterDisk(_ state: Persistent.State) throws {
    let json = try JSON.encode(state)
    self.filterDisk.withValue { $0[Persistent.State.storageKey] = .string(json) }
  }

  /// neutral-type overload so scenario files (which import both `App` and
  /// `Filter` and can't name either module's `Persistent` unambiguously) can
  /// seed the filter's durable state
  func seedFilterDisk(userKeychains: [uid_t: [RuleKeychain]]) throws {
    try self.seedFilterDisk(Persistent.State(userKeychains: userKeychains))
  }

  var filterPersistedState: Persistent.State? {
    guard case .string(let json) = self.filterDisk.value[Persistent.State.storageKey]
    else { return nil }
    return try? JSON.decode(json, as: Persistent.State.self)
  }

  /// neutral-type accessor for scenario files (see `seedFilterDisk(userKeychains:)`)
  func filterPersistedState(numKeysFor uid: uid_t) -> Int? {
    self.filterPersistedState?.userKeychains[uid]?.numKeys
  }
}

// conductor: XPC bus, filter side (mirrors `ReceiveAppMessage`)

extension VirtualMac {
  /// the filter's exported object receiving one app message: posts the same
  /// event `ReceiveAppMessage` would post into the store's event stream, and
  /// produces the same reply.
  func filterReceives(_ request: SimXPCRequest) throws -> SimXPCReply {
    guard let process = self.filterProcess else { throw XPCErr.noConnection }
    func post(_ message: XPCEvent.Filter.MessageFromApp) {
      process.xpcSubject.send(.receivedAppMessage(message))
    }

    switch request {
    case .ackRequest(let randomInt, let userId):
      let saved = self.filterPersistedState
      let ack = XPC.FilterAck(
        randomInt: randomInt,
        version: process.version,
        userId: userId,
        numUserKeys: saved?.userKeychains[userId]?.numKeys ?? 0,
        filteringDisabled: saved?.filteringDisabledUsers?.contains(userId) == true ? true : nil,
      )
      let data = try XPC.encode(ack)
      post(.macappAlive(userId: userId))
      return .init(data: data)

    case .alive(let userId):
      post(.macappAlive(userId: userId))
      return .init(bool: true)

    case .listUserTypes:
      let saved = self.filterPersistedState
      let exemptUsers = Array(saved?.exemptUsers ?? [])
      let protectedUsers = saved.map {
        Array(Set($0.userKeychains.keys).union($0.filteringDisabledUsers ?? []))
      } ?? []
      let data = try XPC.encode(FilterUserTypes(exempt: exemptUsers, protected: protectedUsers))
      return .init(data: data)

    case .userRules(let userId, let manifestData, let filterData):
      let manifest = try XPC.decode(AppIdManifest.self, from: manifestData)
      let userData = try XPC.decode(UserFilterData.self, from: filterData)
      post(.userRules(
        userId: userId,
        keychains: userData.keychains,
        downtime: userData.downtime,
        manifest: manifest,
        filteringDisabled: userData.filteringDisabled,
        alwaysBlocked: userData.alwaysBlocked,
      ))
      return .init()

    case .pauseDowntime(let userId, let secondsSinceReference):
      post(.pauseDowntime(
        userId: userId,
        until: Date(timeIntervalSinceReferenceDate: secondsSinceReference),
      ))
      return .init()

    case .endDowntimePause(let userId):
      post(.endDowntimePause(userId: userId))
      return .init()

    case .setBlockStreaming(let enabled, let userId):
      post(.setBlockStreaming(enabled: enabled, userId: userId))
      return .init()

    case .disconnectUser(let userId):
      post(.disconnectUser(userId: userId))
      return .init()

    case .setUserExemption(let userId, let enabled):
      post(.setUserExemption(userId: userId, enabled: enabled))
      return .init()

    case .suspendFilter(let userId, let durationInSeconds):
      post(.suspendFilter(userId: userId, duration: .init(durationInSeconds)))
      return .init()

    case .endSuspension(let userId):
      post(.endFilterSuspension(userId: userId))
      return .init()

    case .deleteAllStoredState:
      post(.deleteAllStoredState)
      return .init()
    }
  }
}

// conductor: flow delivery

enum SimFlowVerdict: Equatable, Sendable {
  case allow
  case drop
}

extension VirtualMac {
  /// OS RULE (flow delivery, evidence: production behavior + FilterProxyTests):
  /// every outbound flow reaches `handleNewFlow`; WebKit-originated flows carry
  /// a url (and parseable hostname) immediately, everything else defers to an
  /// outbound-data peek for SNI. When the new-flow verdict asks to examine
  /// bytes, the OS follows up with `handleOutboundData` — modeled here as one
  /// immediate follow-up with whatever bytes the sim flow carries (spike: none,
  /// so deferred flows resolve on already-known hostname or default-block).
  @discardableResult
  func browse(
    _ urlString: String,
    from bundleId: String = "com.apple.Safari",
    as uid: uid_t,
  ) async -> SimFlowVerdict {
    guard let process = self.filterProcess else {
      // OS RULE M3 (fail-open when provider absent): with no running data
      // provider, `NEFilterSettings.defaultAction = .allow` and there is nobody
      // to consult, so all traffic flows unfiltered. Device-verified 2026-07-06:
      // during a provider `kill -9` gap, example.com (blocked at baseline)
      // returned HTTP 200 continuously until the OS respawned the provider.
      self.log(.flowDecided(bundleId: bundleId, hostname: urlString, verdict: "UNFILTERED"))
      return .allow
    }
    let hostname = URL(string: urlString)?.host ?? urlString
    let dto = NEFilterFlow.DTO(
      identifier: UUID(),
      sourceAppAuditToken: SimAuditToken.data(uid: uid, bundleId: bundleId),
      description: """
      sourceAppIdentifier = \(bundleId)
      hostname = \(hostname)
      """,
      url: URL(string: urlString),
      flowType: .browser,
    )
    let newFlowVerdict = process.handleNewFlow(dto)
    var verdict: SimFlowVerdict
    if newFlowVerdict.isDrop {
      verdict = .drop
    } else if newFlowVerdict.isExamineBytes {
      let dataVerdict = process.handleOutboundData(from: dto, offset: 0, bytes: Data())
      verdict = dataVerdict.isDrop ? .drop : .allow
    } else {
      verdict = .allow
    }
    self.log(.flowDecided(
      bundleId: bundleId,
      hostname: hostname,
      verdict: verdict == .allow ? "ALLOW" : "DROP",
    ))
    await self.settle()
    return verdict
  }

  /// Opens a connection (a new flow that, if allowed, becomes a long-lived
  /// socket). Returns the connection id iff the flow was allowed — INCLUDING
  /// the fail-open case where the provider is absent (OS RULE M3). Per OS RULE
  /// M4 the connection then survives regardless of later provider state, until
  /// a device reboot.
  @discardableResult
  func openConnection(
    to hostname: String,
    from bundleId: String = "com.apple.Safari",
    as uid: uid_t,
  ) async -> Int? {
    let verdict = await self.browse("https://\(hostname)", from: bundleId, as: uid)
    guard verdict == .allow else { return nil }
    let id = self.nextConnectionId()
    self.openConnections.withValue {
      $0.append(SimConnection(id: id, hostname: hostname, bundleId: bundleId, uid: uid))
    }
    return id
  }

  /// OS RULE M4: data on an already-verdicted connection succeeds iff the socket
  /// is still open — the filter is NOT re-consulted. A connection opened during
  /// a fail-open window keeps carrying data after the provider returns; a reboot
  /// (`rebootDevice`) drops it.
  func connectionCarriesData(_ id: Int) -> Bool {
    self.openConnections.value.contains { $0.id == id }
  }

  /// models the app-side XPC fallback channel: `sendURLMessage` fires a real
  /// HTTPS request to a magic hostname, which reaches the filter as an
  /// ordinary flow from the gertrude app's process (see
  /// `LiveFilterXPCClient.send(urlMessage:)` and `Decision+Flow` urlMessage
  /// handling).
  func deliverUrlMessage(_ message: XPC.URLMessage, from uid: uid_t) async {
    self.log(.urlMessageFlow(message.hostname))
    guard let process = self.filterProcess else { return }
    let dto = NEFilterFlow.DTO(
      identifier: UUID(),
      sourceAppAuditToken: SimAuditToken.data(
        uid: uid,
        bundleId: ".com.netrivet.gertrude.app",
      ),
      description: """
      sourceAppIdentifier = .com.netrivet.gertrude.app
      hostname = \(message.hostname)
      """,
      url: URL(string: "https://\(message.hostname)"),
      flowType: .browser,
    )
    _ = process.handleNewFlow(dto)
    await self.settle()
  }
}

// dependency wiring: filter process context

extension VirtualMac {
  private func filterDependencies(
    xpcSubject: PassthroughSubject<XPCEvent.Filter, Never>,
  ) -> @Sendable (inout DependencyValues) -> Void {
    let scheduler = self.scheduler
    let currentDate = self.currentDate
    let listenerUp = self.listenerUp
    let retainedConnectionUid = self.retainedConnectionUid
    let simDefaults = self.simUserDefaults(self.filterDisk)
    let version = Self.filterVersion
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let fixedCalendar = calendar

    let world = self
    let deliverToApp: @Sendable (XPCEvent.App.MessageFromExtension) async throws -> Void =
      { message in
        try await MainActor.run {
          try world.xpcDeliverToApp(message)
        }
      }

    return { deps in
      deps.date = DateGenerator { currentDate.value }
      deps.calendar = fixedCalendar
      deps.mainQueue = scheduler.eraseToAnyScheduler()
      deps.uuid = .incrementing
      deps.userDefaults = simDefaults
      deps.storage = .liveValue
      deps.filterExtension = ExtensionClient(version: { version })
      deps.security = SecurityClient(
        userIdFromAuditToken: { SimAuditToken.uid(from: $0) },
        rootAppFromAuditToken: { (SimAuditToken.bundleId(from: $0), nil) },
      )
      deps.xpc = XPCClient(
        notifyFilterSuspensionEnded: { userId in
          try await deliverToApp(.userFilterSuspensionEnded(userId))
        },
        startListener: {
          listenerUp.setValue(true)
        },
        stopListener: {
          listenerUp.setValue(false)
          retainedConnectionUid.setValue(nil)
        },
        sendBlockedRequest: { _, request in
          // fidelity: round-trip through the real XPC codec, as XPCManager
          // and the app-side exported object would
          let data = try XPC.encode(request)
          let decoded = try XPC.decode(BlockedRequest.self, from: data)
          try await deliverToApp(.blockedRequest(decoded))
        },
        sendLogs: { logs in
          let data = try XPC.encode(logs)
          let decoded = try XPC.decode(FilterLogs.self, from: data)
          try await deliverToApp(.logs(decoded))
        },
        events: { xpcSubject.eraseToAnyPublisher() },
      )
    }
  }
}

// sim audit tokens

enum SimAuditToken {
  static func data(uid: uid_t, bundleId: String) -> Data {
    Data("sim-token|\(uid)|\(bundleId)".utf8)
  }

  static func uid(from data: Data?) -> uid_t? {
    guard let data, let string = String(data: data, encoding: .utf8) else { return nil }
    let parts = string.split(separator: "|")
    guard parts.count == 3, parts[0] == "sim-token" else { return nil }
    return uid_t(parts[1])
  }

  static func bundleId(from data: Data?) -> String? {
    guard let data, let string = String(data: data, encoding: .utf8) else { return nil }
    let parts = string.split(separator: "|")
    guard parts.count == 3, parts[0] == "sim-token" else { return nil }
    return String(parts[2])
  }
}

// verdict introspection (NE verdict types expose state only via description)

extension NEFilterNewFlowVerdict {
  var isDrop: Bool {
    self.description.contains("drop = YES")
  }

  var isExamineBytes: Bool {
    !self.isDrop && self.description.contains("filterOutbound = YES")
  }
}

extension NEFilterDataVerdict {
  var isDrop: Bool {
    self.description.contains("drop = YES")
  }
}
