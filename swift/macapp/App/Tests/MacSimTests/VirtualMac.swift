import Combine
import ComposableArchitecture
import Core
import Dependencies
import Foundation
import Gertie
import TestSupport

/// An in-process simulation of one physical Mac running Gertrude: the durable
/// world (per-context user defaults, shared wall clock/scheduler, system
/// extension state, mach-service XPC bus) plus live "processes" (macapp
/// instances per macOS user, the filter system extension) built from the real
/// production types, each wired to the world through its own dependency scope.
/// Conductor methods model the OS behaviors connecting them; every modeled OS
/// behavior carries an `OS RULE` comment (or `PROVISIONAL RULE` until VM
/// evidence lands), because the harness tests our code against this model of
/// macOS, not macOS itself.
///
/// NB: this file is import-neutral between the `App` and `Filter` modules
/// (which collide on names like `Persistent` and `DependencyValues.storage`);
/// process types and dependency wiring live in `AppSide.swift` and
/// `FilterSide.swift`, each importing only its own module.
@MainActor final class VirtualMac {
  let scheduler = DispatchQueue.test

  /// The sim owns the timeline completely: a fixed epoch (2025-01-01T00:00:00Z)
  /// makes every run — including explorer seeds and time-of-day-dependent
  /// downtime windows — reproducible forever. This required mediating the one
  /// raw-`Date()` seam the spike found (`Gertie.FilterSuspension.isActive`,
  /// consulted by the filter's flow decision path) with `isActive(at: self.now)`.
  nonisolated static let epoch = Date(timeIntervalSince1970: 1_735_689_600)
  let currentDate = LockIsolated(VirtualMac.epoch)
  let trace = LockIsolated<[TraceEvent]>([])

  /// one defaults "disk" per macOS user (the macapp runs per-user), plus one
  /// for the filter extension, which runs as root with its own defaults domain.
  /// There is NO shared container between app and filter on macOS — state
  /// converges only through XPC messages.
  private var userDisksByUid: [uid_t: LockIsolated<[String: DefaultsValue]>] = [:]
  let filterDisk = LockIsolated<[String: DefaultsValue]>([:])

  func userDisk(_ uid: uid_t) -> LockIsolated<[String: DefaultsValue]> {
    if let existing = self.userDisksByUid[uid] { return existing }
    let disk = LockIsolated<[String: DefaultsValue]>([:])
    self.userDisksByUid[uid] = disk
    return disk
  }

  /// OS RULE M1 (extension activation state): the OS holds the activation state
  /// of the network extension; `[activated enabled]` means the provider process
  /// runs, relaunched on boot and on crash by the system (not by us). Activation
  /// itself is GUI-gated (approval in System Settings) and requires a properly
  /// signed extension — an adhoc build silently fails to activate. Device-
  /// verified 2026-07-06: `systemextensionsctl list` shows the signed
  /// (teamID WFN83LM943) provider `[activated enabled]`, surviving reboot and
  /// `kill -9`. NOT YET WITNESSED: app-driven stop/replace state strings and the
  /// "orange" degraded state — the crash/reboot path is what the sim models.
  let extensionState = LockIsolated<FilterExtensionState>(.notInstalled)
  let extensionStateChanges = PassthroughSubject<FilterExtensionState, Never>()

  /// OS RULE M5 (mach-service XPC): the filter's NSXPCListener owns a single
  /// retained connection (last accepted wins — see XPCManager
  /// `listener(_:shouldAcceptNewConnection:)`); an app's messages fail with
  /// no-connection when the listener is down or the filter process is dead;
  /// filter→app messages reach only the retained connection's app.
  /// PARTIALLY witnessed 2026-07-06: killing the app → it relaunches
  /// (GertrudeHelper crash-watch) and re-establishes its connection; killing the
  /// provider → every in-flight flow owner logs `Got an error on the Filter XPC
  /// connection to unit 1` and the app reconnects to the respawned provider.
  /// DEFERRED: the multi-user "second connect steals the slot" case needs a 2nd
  /// onboarded macOS user; the last-wins model is coded but not device-grounded.
  let listenerUp = LockIsolated(false)
  let retainedConnectionUid = LockIsolated<uid_t?>(nil)
  let appXpcSubjects = LockIsolated<[uid_t: PassthroughSubject<XPCEvent.App, Never>]>([:])
  let websocketSubjects =
    LockIsolated<[uid_t: PassthroughSubject<WebSocketMessage.FromApiToApp, Never>]>([:])

  /// OS RULE M4 (flow-verdict finality): a connection whose flow was allowed
  /// stays usable for the socket's lifetime — the filter is never re-consulted
  /// for data on an already-verdicted flow. So a connection opened while the
  /// provider was absent (fail-open, OS RULE M3) keeps carrying data after the
  /// provider returns; only NEW flows are re-evaluated. Device-verified
  /// 2026-07-06: hosts contacted during a provider `kill -9` gap kept returning
  /// 200 after the ~2.5s respawn while six fresh hosts were all blocked (000);
  /// a reboot cleared the leak. Mac analogue of iOS OS RULE R13.
  let openConnections = LockIsolated<[SimConnection]>([])
  private let connectionIds = LockIsolated(0)

  /// every app→filter XPC message that actually REACHED the filter's exported
  /// object, with the sim time it landed — the observable message log the
  /// explorer's oracle replays its spec state machine over (intent that never
  /// arrived must not update the spec's model of the filter)
  let deliveredXpc = LockIsolated<[DeliveredXPCMessage]>([])

  var filterProcess: FilterExtensionProcess?
  var apps: [uid_t: MacAppProcess] = [:]

  init() {}

  func nextConnectionId() -> Int {
    self.connectionIds.withValue { $0 += 1
      return $0
    }
  }

  /// OS RULE M1/M4: a full device reboot kills every process AND drops every
  /// existing connection (unlike a provider crash, which preserves leaked
  /// connections — see `crashAndRecoverFilterProvider`).
  func rebootDevice() async {
    self.filterProcess = nil
    for (uid, _) in self.apps {
      await self.apps[uid]?.osShutdown()
    }
    self.apps = [:]
    self.retainedConnectionUid.setValue(nil)
    self.listenerUp.setValue(false)
    self.openConnections.setValue([])
    await self.bootFilterExtension()
  }

  func advanceTime(seconds: Int) async {
    self.currentDate.withValue { $0 += TimeInterval(seconds) }
    await self.scheduler.advance(by: .seconds(seconds))
    await self.settle()
  }

  /// lets in-flight async work land deterministically: unstructured tasks plus
  /// anything scheduled "now" on the shared scheduler (publisher deliveries
  /// hopping through `.receive(on:)`), without advancing the timeline. Also
  /// advances each app `TestStore`'s assertion cursor past received actions —
  /// its `state` property lags the live store until they are consumed.
  func settle() async {
    for _ in 0 ..< 10 {
      await Task.repeatYield()
      await self.scheduler.advance(by: .zero)
    }
    for (_, app) in self.apps {
      await app.skipReceivedActions()
    }
    await Task.repeatYield()
    await self.scheduler.advance(by: .zero)
  }

  func shutdown() async {
    for (_, app) in self.apps {
      await app.osShutdown()
    }
    self.apps = [:]
    self.filterProcess = nil
  }
}

/// mirrors what a `UserDefaults` domain can hold, for our two clients' usage
enum DefaultsValue: Equatable, Sendable {
  case string(String)
  case int(Int)
}

/// one successfully delivered app→filter XPC message (see `deliveredXpc`)
struct DeliveredXPCMessage: Sendable {
  let uid: uid_t
  let request: SimXPCRequest
  let at: Date
}

/// an established (already-verdicted) network connection; per OS RULE M4 the
/// filter is never re-consulted for it once opened
struct SimConnection: Equatable, Sendable {
  let id: Int
  let hostname: String
  let bundleId: String
  let uid: uid_t
}

enum TraceEvent: Equatable, Sendable, CustomStringConvertible {
  case filterExtensionLaunched
  case filterExtensionStopped
  case appLaunched(uid_t)
  case appQuit(uid_t)
  case xpcConnectionEstablished(uid_t)
  case xpcConnectionFailed(uid_t)
  case xpcAppMessage(uid_t, String)
  case xpcAppMessageFailed(uid_t, String)
  case xpcFilterMessageDelivered(String)
  case xpcFilterMessageDropped(String)
  case flowDecided(bundleId: String, hostname: String, verdict: String)
  case notification(uid_t, title: String)
  case websocketSent(uid_t, String)
  case securityEvent(uid_t, String)
  case browsersQuit(uid_t)
  case urlMessageFlow(String)

  var description: String {
    switch self {
    case .filterExtensionLaunched: "os launched filter extension"
    case .filterExtensionStopped: "os stopped filter extension"
    case .appLaunched(let uid): "os launched macapp for user \(uid)"
    case .appQuit(let uid): "macapp quit for user \(uid)"
    case .xpcConnectionEstablished(let uid): "xpc connection established by user \(uid)"
    case .xpcConnectionFailed(let uid): "xpc connection FAILED for user \(uid)"
    case .xpcAppMessage(let uid, let msg): "app(\(uid)) → filter: \(msg)"
    case .xpcAppMessageFailed(let uid, let msg): "app(\(uid)) → filter FAILED: \(msg)"
    case .xpcFilterMessageDelivered(let msg): "filter → app: \(msg)"
    case .xpcFilterMessageDropped(let msg): "filter → app DROPPED: \(msg)"
    case .flowDecided(let bundleId, let hostname, let verdict):
      "filter: \(verdict) `\(hostname)` from \(bundleId)"
    case .notification(let uid, let title): "notification(\(uid)): \(title)"
    case .websocketSent(let uid, let msg): "websocket(\(uid)) sent: \(msg)"
    case .securityEvent(let uid, let event): "security event(\(uid)): \(event)"
    case .browsersQuit(let uid): "browsers quit for user \(uid)"
    case .urlMessageFlow(let hostname): "url message flow: \(hostname)"
    }
  }
}

extension VirtualMac {
  func log(_ event: TraceEvent) {
    self.trace.withValue { $0.append(event) }
  }

  var traceDescription: String {
    self.trace.value.map(\.description).joined(separator: "\n")
  }

  func simUserDefaults(
    _ disk: LockIsolated<[String: DefaultsValue]>,
  ) -> UserDefaultsClient {
    UserDefaultsClient(
      setInt: { key, value in disk.withValue { $0[key] = .int(value) } },
      getInt: { key in
        guard case .int(let value) = disk.value[key] else { return 0 }
        return value
      },
      setString: { key, value in disk.withValue { $0[key] = .string(value) } },
      getString: { key in
        guard case .string(let value) = disk.value[key] else { return nil }
        return value
      },
      remove: { key in disk.withValue { $0[key] = nil } },
      removeAll: { disk.setValue([:]) },
    )
  }
}

// XPC bus: neutral, Data-level message surface (mirrors `AppMessageReceiving`)

enum SimXPCRequest: Sendable, Equatable {
  case ackRequest(randomInt: Int, userId: uid_t)
  case alive(userId: uid_t)
  case listUserTypes
  case userRules(userId: uid_t, manifestData: Data, filterData: Data)
  case pauseDowntime(userId: uid_t, untilSecondsSinceReference: Double)
  case endDowntimePause(userId: uid_t)
  case setBlockStreaming(Bool, userId: uid_t)
  case disconnectUser(userId: uid_t)
  case setUserExemption(userId: uid_t, enabled: Bool)
  case suspendFilter(userId: uid_t, durationInSeconds: Int)
  case endSuspension(userId: uid_t)
  case deleteAllStoredState

  var shortDescription: String {
    switch self {
    case .ackRequest: "ackRequest"
    case .alive: "alive"
    case .listUserTypes: "listUserTypes"
    case .userRules: "userRules"
    case .pauseDowntime: "pauseDowntime"
    case .endDowntimePause: "endDowntimePause"
    case .setBlockStreaming(let enabled, _): "setBlockStreaming(\(enabled))"
    case .disconnectUser: "disconnectUser"
    case .setUserExemption: "setUserExemption"
    case .suspendFilter(_, let seconds): "suspendFilter(\(seconds)s)"
    case .endSuspension: "endSuspension"
    case .deleteAllStoredState: "deleteAllStoredState"
    }
  }
}

/// reply values a filter-side handler can produce, mirroring the reply
/// closures in `AppMessageReceiving` (Data for acks/user-types, Bool for alive)
struct SimXPCReply: Sendable {
  var data: Data?
  var bool: Bool?
}

extension VirtualMac {
  /// app-side transport: models one NSXPC remote-proxy call from the macapp to
  /// the filter's exported object. PROVISIONAL RULE P2: fails when the app has
  /// not established (or has lost) the retained connection, when the listener
  /// is down, or when the filter process is dead.
  func xpcSend(from uid: uid_t, _ request: SimXPCRequest) async throws -> SimXPCReply {
    guard self.filterProcess != nil,
          self.listenerUp.value,
          self.retainedConnectionUid.value == uid
    else {
      self.log(.xpcAppMessageFailed(uid, request.shortDescription))
      throw XPCErr.noConnection
    }
    self.log(.xpcAppMessage(uid, request.shortDescription))
    let reply = try self.filterReceives(request)
    self.deliveredXpc.withValue {
      $0.append(.init(uid: uid, request: request, at: self.currentDate.value))
    }
    await self.settle()
    return reply
  }

  /// models the app process opening an `NSXPCConnection` to the filter's mach
  /// service. PROVISIONAL RULE P2: succeeds only while the filter process is
  /// alive with its listener resumed; on acceptance the filter RETAINS this
  /// connection, dropping any previously retained one (last-connect wins).
  func xpcEstablishConnection(from uid: uid_t) -> Result<Void, XPCErr> {
    guard self.filterProcess != nil, self.listenerUp.value else {
      self.log(.xpcConnectionFailed(uid))
      return .failure(.noConnection)
    }
    self.retainedConnectionUid.setValue(uid)
    self.log(.xpcConnectionEstablished(uid))
    return .success(())
  }

  /// filter-side transport: models the filter invoking its retained
  /// connection's remote proxy (`FilterMessageReceiving`). Delivery lands in
  /// the retained app's event subject exactly as the live app-side exported
  /// object would publish it.
  func xpcDeliverToApp(_ event: XPCEvent.App.MessageFromExtension) throws {
    let description = switch event {
    case .blockedRequest: "blockedRequest"
    case .userFilterSuspensionEnded(let uid): "userFilterSuspensionEnded(\(uid))"
    case .logs: "logs"
    }
    guard let uid = self.retainedConnectionUid.value, let _ = self.apps[uid] else {
      self.log(.xpcFilterMessageDropped(description))
      throw XPCErr.noConnection
    }
    self.log(.xpcFilterMessageDelivered(description))
    self.appXpcSubjects.value[uid]?.send(.receivedExtensionMessage(event))
  }

  func appXpcSubject(for uid: uid_t) -> PassthroughSubject<XPCEvent.App, Never> {
    if let existing = self.appXpcSubjects.value[uid] { return existing }
    let subject = PassthroughSubject<XPCEvent.App, Never>()
    self.appXpcSubjects.withValue { $0[uid] = subject }
    return subject
  }

  func websocketSubject(for uid: uid_t) -> PassthroughSubject<
    WebSocketMessage.FromApiToApp, Never,
  > {
    if let existing = self.websocketSubjects.value[uid] { return existing }
    let subject = PassthroughSubject<WebSocketMessage.FromApiToApp, Never>()
    self.websocketSubjects.withValue { $0[uid] = subject }
    return subject
  }

  /// parent's decision arrives by websocket push
  func websocketPush(to uid: uid_t, _ message: WebSocketMessage.FromApiToApp) async {
    self.websocketSubject(for: uid).send(message)
    await self.settle()
  }
}
