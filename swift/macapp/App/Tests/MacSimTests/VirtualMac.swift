import Combine
import ComposableArchitecture
import Core
import Dependencies
import Foundation
import Gertie
import TestSupport

/// In-process simulation of one Mac: durable per-process state, a pinned clock,
/// system-extension state, XPC transport, app processes, and the filter process.
/// OS-facing behavior is modeled explicitly because these tests verify the app
/// against this world model, not against macOS itself.
///
/// NB: this file is import-neutral between the `App` and `Filter` modules
/// (which collide on names like `Persistent` and `DependencyValues.storage`);
/// process types and dependency wiring live in `AppSide.swift` and
/// `FilterSide.swift`, each importing only its own module.
@MainActor final class VirtualMac {
  let scheduler = DispatchQueue.test

  /// Fixed epoch keeps explorer seeds and time-of-day downtime windows stable.
  /// sync:086c6b0b clocked suspension decisions
  nonisolated static let epoch = Date(timeIntervalSince1970: 1_735_689_600)
  let currentDate = LockIsolated(VirtualMac.epoch)
  let trace = LockIsolated<[TraceEvent]>([])

  /// One defaults domain per app user, plus one for the root filter extension.
  /// There is no shared app/filter container; state converges through XPC.
  private var userDisksByUid: [uid_t: LockIsolated<[String: DefaultsValue]>] = [:]
  let filterDisk = LockIsolated<[String: DefaultsValue]>([:])

  func userDisk(_ uid: uid_t) -> LockIsolated<[String: DefaultsValue]> {
    if let existing = self.userDisksByUid[uid] { return existing }
    let disk = LockIsolated<[String: DefaultsValue]>([:])
    self.userDisksByUid[uid] = disk
    return disk
  }

  /// OS RULE M1: the OS owns network-extension activation and provider
  /// relaunch. The sim models the enabled/running path; app-driven stop/replace
  /// state strings are intentionally outside the current model.
  let extensionState = LockIsolated<FilterExtensionState>(.notInstalled)
  let extensionStateChanges = PassthroughSubject<FilterExtensionState, Never>()

  /// OS RULE M5: app/filter XPC is per user. Missing listener, process, or
  /// user connection means no delivery. Routing policy (replace-on-reconnect,
  /// most-recent-wins for logs) is the same `UserConnectionMap` the production
  /// filter uses; only delivery and invalidation are simulated.
  /// sync:31af50b5 per-user xpc routing
  let listenerUp = LockIsolated(false)
  let xpcConnections = LockIsolated(UserConnectionMap<Void>())
  let appXpcSubjects = LockIsolated<[uid_t: PassthroughSubject<XPCEvent.App, Never>]>([:])
  let websocketSubjects =
    LockIsolated<[uid_t: PassthroughSubject<WebSocketMessage.FromApiToApp, Never>]>([:])

  /// OS RULE M4: an already-allowed connection remains usable until reboot;
  /// later filter state changes apply only to new flows.
  let openConnections = LockIsolated<[SimConnection]>([])
  private let connectionIds = LockIsolated(0)

  /// App-to-filter messages that reached the filter, replayed by the oracle.
  let deliveredXpc = LockIsolated<[DeliveredXPCMessage]>([])

  var filterProcess: FilterExtensionProcess?
  var apps: [uid_t: MacAppProcess] = [:]

  init() {
    precondition(
      getuid() >= 500,
      "MacSim must run as a non-system macOS user because DEBUG filter drops allow under uid < 500",
    )
  }

  func nextConnectionId() -> Int {
    self.connectionIds.withValue { $0 += 1
      return $0
    }
  }

  /// OS RULE M1/M4: a full device reboot kills every process AND drops every
  /// existing connection (unlike a provider crash, which preserves leaked
  /// connections; see `crashAndRecoverFilterProvider`).
  func rebootDevice() async {
    self.filterProcess = nil
    for (uid, _) in self.apps {
      await self.apps[uid]?.osShutdown()
    }
    self.apps = [:]
    self.xpcConnections.withValue { $0.clear() }
    self.listenerUp.setValue(false)
    self.openConnections.setValue([])
    await self.bootFilterExtension()
  }

  func advanceTime(seconds: Int) async {
    self.currentDate.withValue { $0 += TimeInterval(seconds) }
    await self.scheduler.advance(by: .seconds(seconds))
    await self.settle()
  }

  /// Lets unstructured tasks, scheduler work, and TestStore received actions
  /// land without advancing simulated time.
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

struct DeliveredXPCMessage: Sendable {
  let uid: uid_t
  let request: SimXPCRequest
  let at: Date
}

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
    case .xpcAppMessage(let uid, let msg): "app(\(uid)) -> filter: \(msg)"
    case .xpcAppMessageFailed(let uid, let msg): "app(\(uid)) -> filter FAILED: \(msg)"
    case .xpcFilterMessageDelivered(let msg): "filter -> app: \(msg)"
    case .xpcFilterMessageDropped(let msg): "filter -> app DROPPED: \(msg)"
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
  var connectedXpcUids: Set<uid_t> {
    self.xpcConnections.value.connectedUids
  }

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
  /// the filter's exported object.
  /// sync:bc4068f6 app-to-filter xpc request surface
  func xpcSend(from uid: uid_t, _ request: SimXPCRequest) async throws -> SimXPCReply {
    guard self.filterProcess != nil,
          self.listenerUp.value,
          self.xpcConnections.value.has(uid)
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

  /// Models the app opening a user-scoped connection to the filter listener.
  /// sync:31af50b5 per-user xpc routing
  func xpcEstablishConnection(from uid: uid_t) -> Result<Void, XPCErr> {
    guard self.filterProcess != nil, self.listenerUp.value else {
      self.log(.xpcConnectionFailed(uid))
      return .failure(.noConnection)
    }
    self.xpcConnections.withValue { $0.connect(uid) }
    self.log(.xpcConnectionEstablished(uid))
    return .success(())
  }

  /// Models the filter invoking an app connection's remote proxy.
  /// sync:31af50b5 per-user xpc routing
  func xpcDeliverToApp(
    _ event: XPCEvent.App.MessageFromExtension,
    to requestedUid: uid_t?,
  ) throws {
    let description = switch event {
    case .blockedRequest: "blockedRequest"
    case .userFilterSuspensionEnded(let uid): "userFilterSuspensionEnded(\(uid))"
    case .logs: "logs"
    }
    guard let uid = requestedUid ?? self.xpcConnections.value.mostRecentUid,
          self.xpcConnections.value.has(uid),
          let _ = self.apps[uid]
    else {
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
