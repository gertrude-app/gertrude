import ComposableArchitecture
import Core
import Filter
import Foundation
import Gertie
import MacAppRoute
import TestSupport
import XCore

@testable import App

/// Seeded interleaving explorer for the app/filter protocol. It drives real
/// reducers in a simulated Mac and compares flow verdicts to an independent
/// oracle replayed from delivered app-to-filter messages.
enum MacExplorer {}

/// Reproducible, high-quality, stable RNG for deterministic testing
struct MacSeededRNG: RandomNumberGenerator, Sendable {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed
  }

  mutating func next() -> UInt64 {
    self.state &+= 0x9E3779B97F4A7C15
    var z = self.state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}

/// Two users exercise independent per-user app connections.
enum SimUser: String, Equatable, Sendable, Codable, CaseIterable {
  case child
  case buddy

  var uid: uid_t {
    switch self {
    case .child: 502
    case .buddy: 503
    }
  }
}

enum SimHost: String, Equatable, Sendable, Codable, CaseIterable {
  case github
  case gitlab
  case youtube

  var hostname: String {
    switch self {
    case .github: "github.com"
    case .gitlab: "gitlab.com"
    case .youtube: "youtube.com"
    }
  }
}

enum RulesVariant: String, Equatable, Sendable, Codable {
  case githubOnly
  case gitlabOnly
  case githubAndGitlab
  case noKeys

  var keychains: [RuleKeychain] {
    switch self {
    case .githubOnly: [.gitHubOnly]
    case .gitlabOnly: [.gitLabOnly]
    case .githubAndGitlab: [.gitHubOnly, .gitLabOnly]
    case .noKeys: []
    }
  }
}

enum MacExplorerAction: Equatable, Sendable, Codable, CustomStringConvertible {
  case browse(SimUser, SimHost)
  case openConnection(SimUser, SimHost)
  case useConnections
  case advanceTime(seconds: Int)
  case grantSuspension(SimUser, seconds: Int)
  case resumeFilterEarly(SimUser)
  case refreshRules(SimUser)
  case setRules(SimUser, RulesVariant)
  case setDowntime(SimUser, on: Bool)
  case pauseDowntime(SimUser)
  case resumeDowntime(SimUser)
  case launchApp(SimUser)
  case quitApp(SimUser)
  case killFilter
  case respawnFilter
  case crashRecoverFilter
  case rebootDevice
  case settle

  var description: String {
    switch self {
    case .browse(let user, let host): "browse(\(user.rawValue), \(host.rawValue))"
    case .openConnection(let user, let host): "openConnection(\(user.rawValue), \(host.rawValue))"
    case .useConnections: "useConnections"
    case .advanceTime(let s): "advanceTime(\(s)s)"
    case .grantSuspension(let user, let s): "grantSuspension(\(user.rawValue), \(s)s)"
    case .resumeFilterEarly(let user): "resumeFilterEarly(\(user.rawValue))"
    case .refreshRules(let user): "refreshRules(\(user.rawValue))"
    case .setRules(let user, let variant): "setRules(\(user.rawValue), \(variant.rawValue))"
    case .setDowntime(let user, let on): "setDowntime(\(user.rawValue), \(on ? "on" : "off"))"
    case .pauseDowntime(let user): "pauseDowntime(\(user.rawValue))"
    case .resumeDowntime(let user): "resumeDowntime(\(user.rawValue))"
    case .launchApp(let user): "launchApp(\(user.rawValue))"
    case .quitApp(let user): "quitApp(\(user.rawValue))"
    case .killFilter: "killFilter"
    case .respawnFilter: "respawnFilter"
    case .crashRecoverFilter: "crashRecoverFilter"
    case .rebootDevice: "rebootDevice"
    case .settle: "settle"
    }
  }
}

// oracle

/// Independent filter model replayed from delivered app-to-filter messages.
/// sync:29acb988 filter state replay
struct MacOracle: Sendable {
  /// production constants: window/interval are shared, replay logic is not
  static let aliveWindow = TimeInterval(Filter.appAlivenessSeconds)
  static let heartbeatInterval = TimeInterval(Filter.heartbeatIntervalSeconds)

  struct UserMemory: Sendable {
    /// nil means the filter has no rules for this user.
    var allowedHosts: Set<String>?
    var downtime: Downtime?
    var suspensionExpiresAt: Date?
    var aliveUntil: Date?
  }

  struct UserPersisted: Sendable {
    var allowedHosts: Set<String>?
    var downtimeWindow: PlainTimeWindow?
  }

  enum AliveEntry {
    case present
    case absent
    /// Lapsed recently enough that heartbeat cleanup may or may not have run.
    case boundary
  }

  enum Verdict: Equatable {
    case allow
    case drop
    case indeterminate
  }

  private(set) var filterUp = false
  private(set) var memory: [uid_t: UserMemory] = [:]
  private(set) var persisted: [uid_t: UserPersisted] = [:]

  /// OS RULE M1: relaunch reloads durable state and loses memory state.
  mutating func filterBooted() {
    self.filterUp = true
    self.memory = self.persisted.mapValues { saved in
      UserMemory(
        allowedHosts: saved.allowedHosts,
        downtime: saved.downtimeWindow.map { Downtime(window: $0) },
        suspensionExpiresAt: nil,
        aliveUntil: nil,
      )
    }
  }

  mutating func filterDied() {
    self.filterUp = false
    self.memory = [:]
  }

  /// sync:29acb988 filter state replay
  mutating func consume(_ message: DeliveredXPCMessage) {
    var m = self.memory[message.uid] ?? UserMemory()
    switch message.request {
    case .alive, .ackRequest:
      m.aliveUntil = message.at + Self.aliveWindow

    case .userRules(_, _, let filterData):
      guard let data = try? XPC.decode(UserFilterData.self, from: filterData) else { break }
      if !data.keychains.isEmpty || data.filteringDisabled == false {
        m.allowedHosts = Self.allowedHosts(of: data.keychains)
      }
      m.downtime = data.downtime
      m.aliveUntil = message.at + Self.aliveWindow
      self.persisted[message.uid] = UserPersisted(
        allowedHosts: m.allowedHosts,
        downtimeWindow: data.downtime?.window,
      )

    case .suspendFilter(_, let seconds):
      m.suspensionExpiresAt = message.at + TimeInterval(seconds)
      m.aliveUntil = message.at + Self.aliveWindow

    case .endSuspension:
      m.suspensionExpiresAt = nil
      m.aliveUntil = message.at + Self.aliveWindow

    case .pauseDowntime(_, let untilSecondsSinceReference):
      if m.downtime != nil {
        m.downtime?.pausedUntil = Date(timeIntervalSinceReferenceDate: untilSecondsSinceReference)
      }
      m.aliveUntil = message.at + Self.aliveWindow

    case .endDowntimePause:
      m.downtime?.pausedUntil = nil
      m.aliveUntil = message.at + Self.aliveWindow

    case .setBlockStreaming:
      m.aliveUntil = message.at + Self.aliveWindow

    case .disconnectUser:
      m = UserMemory()
      self.persisted[message.uid] = nil

    case .deleteAllStoredState:
      self.memory = [:]
      self.persisted = [:]
      return

    case .listUserTypes, .setUserExemption:
      break
    }
    self.memory[message.uid] = m
  }

  /// sync:d8356a06 liveness heartbeat cleanup
  func aliveEntry(for uid: uid_t, now: Date) -> AliveEntry {
    guard let until = self.memory[uid]?.aliveUntil else { return .absent }
    if until >= now { return .present }
    if until < now - Self.heartbeatInterval { return .absent }
    return .boundary
  }

  func expectedVerdict(uid: uid_t, host: String, now: Date, calendar: Calendar) -> Verdict {
    // OS RULE M3: no provider process means all traffic flows unfiltered
    guard self.filterUp else { return .allow }
    let m = self.memory[uid] ?? UserMemory()

    func allows(aliveEntry: Bool) -> Bool {
      // Decision+Early: downtime outranks everything (incl. suspensions)
      if let downtime = m.downtime, downtime.shouldBlock(at: now, in: calendar) {
        return false
      }
      let suspended = m.suspensionExpiresAt.map { $0 > now } == true
      if suspended, aliveEntry { return true } // early-stage suspension allow
      // Decision+Flow: protected user with no alive macapp fails CLOSED
      let protected = m.allowedHosts != nil
      if !aliveEntry, protected { return false }
      if suspended { return true } // flow-stage activeSuspension
      guard let hosts = m.allowedHosts, !hosts.isEmpty else { return false }
      return hosts.contains(host)
    }

    switch self.aliveEntry(for: uid, now: now) {
    case .present: return allows(aliveEntry: true) ? .allow : .drop
    case .absent: return allows(aliveEntry: false) ? .allow : .drop
    case .boundary:
      let ifPresent = allows(aliveEntry: true)
      let ifAbsent = allows(aliveEntry: false)
      guard ifPresent == ifAbsent else { return .indeterminate }
      return ifPresent ? .allow : .drop
    }
  }

  func describe(uid: uid_t, now: Date) -> String {
    guard self.filterUp else { return "filter ABSENT (fail-open)" }
    guard let m = self.memory[uid] else { return "filter up, user unknown to filter" }
    var parts: [String] = []
    parts.append("allowedHosts: \(m.allowedHosts.map { "\($0.sorted())" } ?? "nil")")
    if let alive = m.aliveUntil {
      parts.append("aliveUntil: \(alive.timeIntervalSince(now))s from now")
    } else {
      parts.append("alive: never/lost")
    }
    if let expiry = m.suspensionExpiresAt {
      parts.append("suspensionExpires: \(expiry.timeIntervalSince(now))s from now")
    }
    if let downtime = m.downtime {
      parts
        .append("downtime: \(downtime.window), paused: \(String(describing: downtime.pausedUntil))")
    }
    return parts.joined(separator: ", ")
  }

  /// Deliberately not `KeychainIndex`, so matcher bugs do not hide in both places.
  static func allowedHosts(of keychains: [RuleKeychain]) -> Set<String> {
    var hosts: Set<String> = []
    for keychain in keychains {
      for ruleKey in keychain.keys {
        if case .domain(let domain, .unrestricted) = ruleKey.key {
          hosts.insert(domain.string)
        }
      }
    }
    return hosts
  }
}

// run results

extension MacExplorer {
  struct Violation: Equatable, Sendable, Codable, CustomStringConvertible {
    var kind: String
    var step: Int
    var action: String
    var detail: String

    var description: String {
      "\(self.kind) at step \(self.step) [\(self.action)]: \(self.detail)"
    }
  }

  struct Stats: Equatable, Sendable, Codable {
    init() {}

    var blockedDropped = 0
    var expectedAllows = 0
    var failOpenAllows = 0
    var awolDrops = 0
    var downtimeDrops = 0
    var suspensionAllows = 0
    var indeterminateSkips = 0
    var connectionsOpened = 0
    var leakedConnectionUses = 0
    var xpcSendFailures = 0
    var xpcReconnects = 0
    var suspensionGrantsDelivered = 0
    var suspensionGrantsLost = 0
    var rulesDeliveries = 0
    var messagesDelivered = 0
  }

  struct RunResult: Sendable, Codable {
    var seed: UInt64?
    var actions: [MacExplorerAction]
    var violation: Violation?
    var stats: Stats
    var traceTail: [String]

    var report: String {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = (try? encoder.encode(self)) ?? Data()
      return String(decoding: data, as: UTF8.self)
    }
  }

  @MainActor
  static func run(seed: UInt64, steps: Int = 30) async -> RunResult {
    var rng = MacSeededRNG(seed: seed)
    let run = MacExplorerRun()
    await run.bootstrap()
    var actions: [MacExplorerAction] = []
    var violation: Violation?
    for step in 0 ..< steps {
      let action = run.chooseAction(&rng)
      actions.append(action)
      if let found = await run.perform(action, step: step) {
        violation = found
        break
      }
    }
    if violation == nil {
      violation = await run.converge(step: steps)
    }
    let result = RunResult(
      seed: seed,
      actions: actions,
      violation: violation,
      stats: run.finalStats(),
      traceTail: violation == nil ? [] : run.traceTail(),
    )
    await run.world.shutdown()
    return result
  }

  @MainActor
  static func replay(_ script: [MacExplorerAction], converge: Bool = true) async -> RunResult {
    let run = MacExplorerRun()
    await run.bootstrap()
    var actions: [MacExplorerAction] = []
    var violation: Violation?
    for (step, action) in script.enumerated() {
      guard run.isEnabled(action) else { continue }
      actions.append(action)
      if let found = await run.perform(action, step: step) {
        violation = found
        break
      }
    }
    if violation == nil, converge {
      violation = await run.converge(step: script.count)
    }
    let result = RunResult(
      seed: nil,
      actions: actions,
      violation: violation,
      stats: run.finalStats(),
      traceTail: violation == nil ? [] : run.traceTail(),
    )
    await run.world.shutdown()
    return result
  }

  @MainActor
  static func shrink(
    _ script: [MacExplorerAction],
    expecting kind: String,
    budget: Int = 200,
  ) async -> [MacExplorerAction] {
    var current = script
    var remaining = budget
    var changed = true
    while changed, remaining > 0 {
      changed = false
      var index = current.count - 1
      while index >= 0, remaining > 0 {
        var candidate = current
        candidate.remove(at: index)
        remaining -= 1
        let result = await self.replay(candidate)
        if result.violation?.kind == kind {
          current = candidate
          changed = true
        }
        index -= 1
      }
    }
    return current
  }
}

// run

@MainActor
final class MacExplorerRun {
  let world = VirtualMac()
  var oracle = MacOracle()
  var stats = MacExplorer.Stats()
  var checkInOutputs: [uid_t: LockIsolated<CheckIn_v2.Output>] = [:]
  var deliveredCursor = 0
  let calendar: Calendar

  init() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    self.calendar = calendar
  }

  var now: Date { self.world.currentDate.value }

  func bootstrap() async {
    for user in SimUser.allCases {
      let output: CheckIn_v2.Output = {
        var output = CheckIn_v2.Output.sim(
          keychains: user == .child ? RulesVariant.githubOnly.keychains
            : RulesVariant.gitlabOnly.keychains,
        )
        // modern app semantics: explicit false (nil means legacy-app rule
        // preservation in the filter's userRules handler)
        output.userData.filteringDisabled = false
        return output
      }()
      self.checkInOutputs[user.uid] = LockIsolated(output)
      try? self.world.seedAppDisk(uid: user.uid, user: .mock)
    }
    await self.world.bootFilterExtension()
    self.oracle.filterBooted()
    _ = await self.world.launchApp(
      uid: SimUser.child.uid,
      checkInOutput: self.checkInOutputs[SimUser.child.uid]!,
    )
    self.drainDeliveries()
  }

  /// feeds every app-to-filter message that reached the filter since the last
  /// drain into the oracle, in delivery order
  func drainDeliveries() {
    let delivered = self.world.deliveredXpc.value
    while self.deliveredCursor < delivered.count {
      let message = delivered[self.deliveredCursor]
      self.oracle.consume(message)
      self.stats.messagesDelivered += 1
      if case .userRules = message.request { self.stats.rulesDeliveries += 1 }
      self.deliveredCursor += 1
    }
  }

  func appRunning(_ user: SimUser) -> Bool {
    self.world.apps[user.uid] != nil
  }

  func isEnabled(_ action: MacExplorerAction) -> Bool {
    switch action {
    case .resumeFilterEarly(let user), .refreshRules(let user), .pauseDowntime(let user),
         .resumeDowntime(let user), .quitApp(let user):
      self.appRunning(user)
    case .launchApp(let user):
      !self.appRunning(user)
    case .killFilter, .crashRecoverFilter:
      self.world.filterProcess != nil
    case .respawnFilter:
      self.world.filterProcess == nil
    case .useConnections:
      !self.world.openConnections.value.isEmpty
    default:
      true
    }
  }

  func chooseAction(_ rng: inout MacSeededRNG) -> MacExplorerAction {
    var menu: [(Int, MacExplorerAction)] = [
      (12, .browse(.child, .youtube)),
      (9, .browse(.child, .github)),
      (3, .browse(.child, .gitlab)),
      (3, .browse(.buddy, .gitlab)),
      (2, .browse(.buddy, .youtube)),
      (4, .openConnection(.child, .youtube)),
      (10, .advanceTime(seconds: pick(&rng, from: [5, 15, 30, 60, 90, 150, 300, 600, 1500]))),
      (6, .grantSuspension(.child, seconds: pick(&rng, from: [60, 300, 900]))),
      (1, .grantSuspension(.buddy, seconds: 300)),
      (3, .setRules(.child, pick(&rng, from: [.githubOnly, .githubAndGitlab, .noKeys]))),
      (1, .setRules(.buddy, pick(&rng, from: [.gitlabOnly, .noKeys]))),
      (3, .setDowntime(.child, on: true)),
      (1, .setDowntime(.child, on: false)),
      (2, .rebootDevice),
      (2, .settle),
    ]
    if self.world.filterProcess != nil {
      menu.append((3, .killFilter))
      menu.append((3, .crashRecoverFilter))
    } else {
      menu.append((6, .respawnFilter))
    }
    if self.appRunning(.child) {
      menu.append((3, .resumeFilterEarly(.child)))
      menu.append((4, .refreshRules(.child)))
      menu.append((2, .pauseDowntime(.child)))
      menu.append((1, .resumeDowntime(.child)))
      menu.append((3, .quitApp(.child)))
    } else {
      menu.append((5, .launchApp(.child)))
    }
    if self.appRunning(.buddy) {
      menu.append((2, .refreshRules(.buddy)))
      menu.append((2, .quitApp(.buddy)))
    } else {
      menu.append((3, .launchApp(.buddy)))
    }
    if !self.world.openConnections.value.isEmpty {
      menu.append((4, .useConnections))
    }
    return weightedPick(menu, &rng)
  }

  func perform(_ action: MacExplorerAction, step: Int) async -> MacExplorer.Violation? {
    self.drainDeliveries()
    let violation = await self.execute(action, step: step)
    self.drainDeliveries()
    return violation
  }

  private func execute(
    _ action: MacExplorerAction,
    step: Int,
  ) async -> MacExplorer.Violation? {
    switch action {
    case .browse(let user, let host):
      return await self.checkedBrowse(user, host, step: step, action: action)

    case .openConnection(let user, let host):
      let expected = self.expect(user, host)
      let opened = await self.world.openConnection(
        to: host.hostname,
        from: "com.apple.Safari",
        as: user.uid,
      )
      if opened != nil { self.stats.connectionsOpened += 1 }
      switch expected {
      case .allow where opened == nil:
        return self.violation(
          "L-mac-blocking-stuck", step, action,
          "oracle expects ALLOW but connection was refused; \(self.oracleDetail(user))",
        )
      case .drop where opened != nil:
        return self.violation(
          "S-mac-unexpected-allow", step, action,
          "oracle expects DROP but connection was opened; \(self.oracleDetail(user))",
        )
      case .indeterminate:
        self.stats.indeterminateSkips += 1
      default:
        break
      }

    case .useConnections:
      // OS RULE M4: an already-verdicted connection carries data for the
      // socket's lifetime; count the ones the filter would drop fresh today
      for connection in self.world.openConnections.value {
        guard self.world.connectionCarriesData(connection.id) else { continue }
        let verdict = self.oracle.expectedVerdict(
          uid: connection.uid,
          host: connection.hostname,
          now: self.now,
          calendar: self.calendar,
        )
        if verdict == .drop { self.stats.leakedConnectionUses += 1 }
      }

    case .advanceTime(let seconds):
      await self.world.advanceTime(seconds: seconds)

    case .grantSuspension(let user, let seconds):
      let deliveredBefore = self.world.deliveredXpc.value.count
      await self.world.websocketPush(to: user.uid, .filterSuspensionRequestDecided_v2(
        id: .deadbeef,
        decision: .accepted(duration: .init(seconds), extraMonitoring: nil),
        comment: nil,
      ))
      let delivered = self.world.deliveredXpc.value[deliveredBefore...].contains {
        if case .suspendFilter = $0.request { return true }
        return false
      }
      if delivered { self.stats.suspensionGrantsDelivered += 1 }
      else { self.stats.suspensionGrantsLost += 1 }

    case .resumeFilterEarly(let user):
      await self.send(user, .menuBar(.resumeFilterClicked))

    case .refreshRules(let user):
      await self.send(user, .menuBar(.refreshRulesClicked))

    case .setRules(let user, let variant):
      self.checkInOutputs[user.uid]?.withValue { $0.keychains = variant.keychains }

    case .setDowntime(let user, let on):
      let window: PlainTimeWindow? = on ? self.relativeDowntimeWindow() : nil
      self.checkInOutputs[user.uid]?.withValue { $0.userData.downtime = window }

    case .pauseDowntime(let user):
      await self.send(user, .adminAuthed(.menuBar(.pauseDowntimeClicked(duration: .tenMinutes))))

    case .resumeDowntime(let user):
      await self.send(user, .menuBar(.resumeDowntimeClicked))

    case .launchApp(let user):
      guard let output = self.checkInOutputs[user.uid] else { break }
      _ = await self.world.launchApp(uid: user.uid, checkInOutput: output)

    case .quitApp(let user):
      await self.world.quitApp(uid: user.uid)

    case .killFilter:
      self.world.killFilterProviderProcess()
      self.oracle.filterDied()
      await self.world.settle()

    case .respawnFilter:
      await self.world.bootFilterExtension()
      self.oracle.filterDied()
      self.oracle.filterBooted()

    case .crashRecoverFilter:
      self.oracle.filterDied()
      await self.world.crashAndRecoverFilterProvider()
      self.oracle.filterBooted()

    case .rebootDevice:
      self.oracle.filterDied()
      await self.world.rebootDevice()
      self.oracle.filterBooted()

    case .settle:
      await self.world.settle()
    }
    return nil
  }

  /// a 30-minute downtime window opening two sim-minutes from now, relative
  /// to the pinned epoch so seeds reproduce forever, minute-granular because
  /// `PlainTime` stores only hour/minute
  private func relativeDowntimeWindow() -> PlainTimeWindow {
    let start = PlainTime.from(self.now + 120, in: self.calendar)
    let end = PlainTime.from(self.now + 120 + 1800, in: self.calendar)
    return PlainTimeWindow(start: start, end: end)
  }

  private func send(_ user: SimUser, _ action: AppReducer.Action) async {
    guard let app = self.world.apps[user.uid] else { return }
    await app.store.send(action)
    await self.world.settle()
  }

  private func expect(_ user: SimUser, _ host: SimHost) -> MacOracle.Verdict {
    let verdict = self.oracle.expectedVerdict(
      uid: user.uid,
      host: host.hostname,
      now: self.now,
      calendar: self.calendar,
    )
    self.tallyExpectation(verdict, user: user, host: host)
    return verdict
  }

  private func tallyExpectation(_ verdict: MacOracle.Verdict, user: SimUser, host: SimHost) {
    switch verdict {
    case .allow:
      if !self.oracle.filterUp {
        self.stats.failOpenAllows += 1
      } else if self.oracle.memory[user.uid]?.suspensionExpiresAt.map({ $0 > self.now }) == true {
        self.stats.suspensionAllows += 1
      } else {
        self.stats.expectedAllows += 1
      }
    case .drop:
      let m = self.oracle.memory[user.uid]
      if let downtime = m?.downtime, downtime.shouldBlock(at: self.now, in: self.calendar) {
        self.stats.downtimeDrops += 1
      } else if m?.allowedHosts != nil,
                self.oracle.aliveEntry(for: user.uid, now: self.now) == .absent {
        self.stats.awolDrops += 1
      } else {
        self.stats.blockedDropped += 1
      }
    case .indeterminate:
      break
    }
  }

  private func checkedBrowse(
    _ user: SimUser,
    _ host: SimHost,
    step: Int,
    action: MacExplorerAction,
  ) async -> MacExplorer.Violation? {
    let expected = self.expect(user, host)
    let verdict = await self.world.browse(
      "https://\(host.hostname)",
      from: "com.apple.Safari",
      as: user.uid,
    )
    switch expected {
    case .allow where verdict != .allow:
      return self.violation(
        "L-mac-blocking-stuck", step, action,
        "oracle expects ALLOW but flow got \(verdict); \(self.oracleDetail(user))",
      )
    case .drop where verdict != .drop:
      return self.violation(
        "S-mac-unexpected-allow", step, action,
        "oracle expects DROP but flow got \(verdict); \(self.oracleDetail(user))",
      )
    case .indeterminate:
      self.stats.indeterminateSkips += 1
    default:
      break
    }
    return nil
  }

  /// With no more user events, the world must settle to the oracle after reboot.
  func converge(step: Int) async -> MacExplorer.Violation? {
    let action = MacExplorerAction.settle
    let preRebootConnections = self.world.openConnections.value.map(\.id)
    await self.world.advanceTime(seconds: 7200)
    self.drainDeliveries()

    self.oracle.filterDied()
    await self.world.rebootDevice()
    self.oracle.filterBooted()
    for user in SimUser.allCases {
      guard let output = self.checkInOutputs[user.uid] else { continue }
      _ = await self.world.launchApp(uid: user.uid, checkInOutput: output)
    }
    await self.world.advanceTime(seconds: 90)
    self.drainDeliveries()

    for id in preRebootConnections where self.world.connectionCarriesData(id) {
      return self.violation(
        "M4-connection-survived-reboot", step, action,
        "connection \(id) still carries data after device reboot",
      )
    }
    let expectedConnections = Set(SimUser.allCases.map(\.uid))
    if self.world.connectedXpcUids != expectedConnections {
      return self.violation(
        "C-mac-xpc-not-reestablished", step, action,
        "expected XPC connections \(expectedConnections.sorted()) after relaunch, got \(self.world.connectedXpcUids.sorted())",
      )
    }
    if let suspensions = self.world.filterProcess?.state.suspensions, !suspensions.isEmpty {
      return self.violation(
        "C-mac-suspension-survived", step, action,
        "filter still holds suspensions \(suspensions.keys.sorted()) after convergence",
      )
    }
    for user in SimUser.allCases {
      if let app = self.world.apps[user.uid],
         app.state.filter.currentSuspensionExpiration != nil {
        return self.violation(
          "C-mac-app-projection-stuck", step, action,
          "\(user.rawValue) app still projects a live suspension after convergence",
        )
      }
    }
    for user in SimUser.allCases {
      for host in SimHost.allCases {
        let expected = self.expect(user, host)
        let verdict = await self.world.browse(
          "https://\(host.hostname)",
          from: "com.apple.Safari",
          as: user.uid,
        )
        switch expected {
        case .allow where verdict != .allow:
          return self.violation(
            "C-mac-blocking-stuck", step, action,
            "converged: oracle expects ALLOW for \(user.rawValue)/\(host.rawValue) but flow got \(verdict); \(self.oracleDetail(user))",
          )
        case .drop where verdict != .drop:
          return self.violation(
            "C-mac-unexpected-allow", step, action,
            "converged: oracle expects DROP for \(user.rawValue)/\(host.rawValue) but flow got \(verdict); \(self.oracleDetail(user))",
          )
        case .indeterminate:
          self.stats.indeterminateSkips += 1
        default:
          break
        }
      }
    }
    return nil
  }

  func finalStats() -> MacExplorer.Stats {
    var stats = self.stats
    for event in self.world.trace.value {
      switch event {
      case .xpcAppMessageFailed: stats.xpcSendFailures += 1
      case .xpcConnectionEstablished: stats.xpcReconnects += 1
      default: break
      }
    }
    return stats
  }

  func traceTail(_ count: Int = 80) -> [String] {
    self.world.trace.value.suffix(count).map(\.description)
  }

  private func oracleDetail(_ user: SimUser) -> String {
    "oracle[\(user.rawValue)]: \(self.oracle.describe(uid: user.uid, now: self.now)), now: \(self.now)"
  }

  private func violation(
    _ kind: String,
    _ step: Int,
    _ action: MacExplorerAction,
    _ detail: String,
  ) -> MacExplorer.Violation {
    MacExplorer.Violation(
      kind: kind,
      step: step,
      action: action.description,
      detail: detail,
    )
  }
}

// fixtures

extension RuleKeychain {
  static let gitLabOnly = RuleKeychain(
    id: 3,
    keys: [.init(
      id: 4,
      key: .domain(domain: .init(string: "gitlab.com"), scope: .unrestricted),
    )],
  )
}

private func pick<T>(_ rng: inout MacSeededRNG, from options: [T]) -> T {
  options[Int(rng.next() % UInt64(options.count))]
}

private func weightedPick(
  _ menu: [(Int, MacExplorerAction)],
  _ rng: inout MacSeededRNG,
) -> MacExplorerAction {
  let total = menu.reduce(0) { $0 + $1.0 }
  var roll = Int(rng.next() % UInt64(total))
  for (weight, action) in menu {
    roll -= weight
    if roll < 0 { return action }
  }
  return menu[menu.count - 1].1
}
