import Combine
import ComposableArchitecture
import Core
import Dependencies
import Foundation
import Gertie
import NetworkExtension
import XCore

@testable import Filter

/// Filter process backed by the real `FilterProxy` under sim dependencies.
@MainActor final class FilterExtensionProcess {
  let version: String
  let xpcSubject: PassthroughSubject<XPCEvent.Filter, Never>
  private let dependencies: @Sendable (inout DependencyValues) -> Void
  private let proxy: FilterProxy

  var state: Filter.State { self.proxy.store.state }

  /// Mirrors provider startup: extension-started action, then `startFilter`.
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

  /// OS RULE M1: provider launch creates a fresh filter process that reloads
  /// durable state; in-memory state starts empty.
  /// sync:56acb165 filter boot durable reload
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

  /// OS RULE M1/M3: provider absent; existing open connections are preserved.
  /// Call `bootFilterExtension()` to model relaunch.
  func killFilterProviderProcess() {
    self.filterProcess = nil
    self.xpcConnections.withValue { $0.clear() }
    self.log(.filterExtensionStopped)
  }

  /// App liveness is in-memory filter state and must be re-sent after relaunch.
  /// sync:ded93bed app liveness window
  func deliverAppAlive(_ uid: uid_t) async {
    self.filterProcess?.xpcSubject.send(.receivedAppMessage(.macappAlive(userId: uid)))
    await self.settle()
  }

  /// OS RULE M1: provider relaunch loses memory and reloads durable state.
  func crashAndRecoverFilterProvider() async {
    self.killFilterProviderProcess()
    await self.bootFilterExtension()
  }

  func stopFilterExtension() async {
    self.filterProcess?.osStop()
    self.filterProcess = nil
    self.xpcConnections.withValue { $0.clear() }
    self.extensionState.setValue(.installedButNotRunning)
    self.extensionStateChanges.send(.installedButNotRunning)
    self.log(.filterExtensionStopped)
    await self.settle()
  }

  func seedFilterDisk(_ state: Persistent.State) throws {
    let json = try JSON.encode(state)
    self.filterDisk.withValue { $0[Persistent.State.storageKey] = .string(json) }
  }

  /// Lets scenario files seed filter state without naming `Filter.Persistent`.
  func seedFilterDisk(userKeychains: [uid_t: [RuleKeychain]]) throws {
    try self.seedFilterDisk(Persistent.State(userKeychains: userKeychains))
  }

  var filterPersistedState: Persistent.State? {
    guard case .string(let json) = self.filterDisk.value[Persistent.State.storageKey]
    else { return nil }
    return try? JSON.decode(json, as: Persistent.State.self)
  }

  /// Lets scenario files inspect filter state without naming `Filter.Persistent`.
  func filterPersistedState(numKeysFor uid: uid_t) -> Int? {
    self.filterPersistedState?.userKeychains[uid]?.numKeys
  }
}

// conductor: XPC bus, filter side (mirrors `ReceiveAppMessage`)

extension VirtualMac {
  /// Posts the same filter event as `ReceiveAppMessage` and returns the same reply.
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
  /// Models the NetworkExtension new-flow/data-flow sequence.
  /// sync:9d971fd4 flow delivery verdict path
  @discardableResult
  func browse(
    _ urlString: String,
    from bundleId: String = "com.apple.Safari",
    as uid: uid_t,
  ) async -> SimFlowVerdict {
    guard let process = self.filterProcess else {
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

  /// Opens a long-lived connection if the initial flow is allowed.
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

  /// OS RULE M4: already-verdicted connections are not re-checked.
  func connectionCarriesData(_ id: Int) -> Bool {
    self.openConnections.value.contains { $0.id == id }
  }

  /// Models the app-side URL-message fallback channel.
  /// sync:bc81c515 url-message fallback
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
    let xpcConnections = self.xpcConnections
    let simDefaults = self.simUserDefaults(self.filterDisk)
    let version = Self.filterVersion
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let fixedCalendar = calendar

    let world = self
    let deliverToApp: @Sendable (XPCEvent.App.MessageFromExtension) async throws -> Void =
      { message in
        try await MainActor.run {
          try world.xpcDeliverToApp(message, to: nil)
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
          try await MainActor.run {
            try world.xpcDeliverToApp(.userFilterSuspensionEnded(userId), to: userId)
          }
        },
        startListener: {
          listenerUp.setValue(true)
        },
        stopListener: {
          listenerUp.setValue(false)
          xpcConnections.withValue { $0.clear() }
        },
        sendBlockedRequest: { userId, request in
          // sync:1e9446b4 blocked-request payload encoding
          let data = try XPC.encode(request)
          let decoded = try XPC.decode(BlockedRequest.self, from: data)
          try await MainActor.run {
            try world.xpcDeliverToApp(.blockedRequest(decoded), to: userId)
          }
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
