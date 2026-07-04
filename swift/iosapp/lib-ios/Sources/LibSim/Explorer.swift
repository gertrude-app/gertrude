import Foundation
import GertieBlocker
import IOSRoute
import LibClients
import LibCore

/// Deterministic seeded interleaving explorer for the recording-suspension
/// protocol (docs/ios-recording-protocol.md). Each run drives a fresh
/// `VirtualDevice` through a random-but-reproducible sequence of user, OS, and
/// adversarial events, checking after every observable flow that the real
/// processes' decisions match the spec's stateless register math, and at the
/// end of the run that the world converged (C1) and evidence was conserved
/// (S2). A violation report carries the seed, the action script (shrinkable
/// and replayable), and the trace tail.
public enum RecordingExplorer {}

/// SplitMix64: tiny, high-quality, and stable across platforms/releases —
/// unlike `SystemRandomNumberGenerator`, the same seed must reproduce the
/// same run forever, since failing seeds become regression tests.
public struct SeededRNG: RandomNumberGenerator, Sendable {
  private var state: UInt64

  public init(seed: UInt64) {
    self.state = seed
  }

  public mutating func next() -> UInt64 {
    self.state &+= 0x9E3779B97F4A7C15
    var z = self.state
    z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
    z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
    return z ^ (z >> 31)
  }
}

public enum ExplorerAction: Equatable, Sendable, Codable, CustomStringConvertible {
  case browseBlocked
  case browseSafe
  case advanceTime(seconds: Int)
  case grantSuspension(seconds: Int)
  case clearExpiration
  case sendSuspendSentinel
  case sendResumeSentinel
  case spoofSuspendSentinel
  case startBroadcast
  case beginGrantedRecording(grantSeconds: Int)
  case recordFrames(seconds: Int)
  case recordStatic(seconds: Int)
  case pauseFrameDelivery(seconds: Int)
  case stopBroadcast
  case lockDevice
  case killFilter
  case killController
  case killRecorder
  case reboot(controllerFirst: Bool)
  case quiesce

  public var description: String {
    switch self {
    case .browseBlocked: "browseBlocked"
    case .browseSafe: "browseSafe"
    case .advanceTime(let s): "advanceTime(\(s)s)"
    case .grantSuspension(let s): "grantSuspension(\(s)s)"
    case .clearExpiration: "clearExpiration"
    case .sendSuspendSentinel: "sendSuspendSentinel"
    case .sendResumeSentinel: "sendResumeSentinel"
    case .spoofSuspendSentinel: "spoofSuspendSentinel"
    case .startBroadcast: "startBroadcast"
    case .beginGrantedRecording(let s): "beginGrantedRecording(grant \(s)s)"
    case .recordFrames(let s): "recordFrames(\(s)s)"
    case .recordStatic(let s): "recordStatic(\(s)s)"
    case .pauseFrameDelivery(let s): "pauseFrameDelivery(\(s)s)"
    case .stopBroadcast: "stopBroadcast"
    case .lockDevice: "lockDevice"
    case .killFilter: "killFilter"
    case .killController: "killController"
    case .killRecorder: "killRecorder"
    case .reboot(let cf): "reboot(\(cf ? "controller" : "filter")First)"
    case .quiesce: "quiesce"
    }
  }
}

/// The spec's suspension state machine (protocol doc §State derivation rules)
/// replayed from the registers at every observation point, using the same
/// pure functions (`entered`/`rederived`/`isValid`) the spec defines. It
/// deliberately re-derives everything from durable registers + entry events —
/// exactly what a correct filter must be equivalent to across any interleaving
/// of process deaths, relaunches, and gaps. A device verdict diverging from
/// this oracle is an invariant violation: allowing what the spec blocks is
/// S1/L1 (safety / fail-safe exit); blocking what the spec lifts is L2
/// (recovery entry — the trapdoor class).
struct SpecOracle: Sendable {
  var held: RecordingSuspension?
  var sentinelEntries = 0
  var rederivedEntries = 0

  mutating func onRegularFlow(
    expiration: Date?,
    lastScreenshot: Date?,
    now: Date,
  ) -> Bool {
    if self.held == nil,
       let rederived = RecordingSuspension.rederived(
         expiration: expiration,
         lastScreenshot: lastScreenshot,
         now: now,
       ) {
      self.held = rederived
      self.rederivedEntries += 1
    }
    if let held = self.held {
      if held.isValid(expiration: expiration, lastScreenshot: lastScreenshot, now: now) {
        return true
      }
      self.held = nil
    }
    return false
  }

  mutating func onSuspendSentinel(expiration: Date?, now: Date) {
    if let entered = RecordingSuspension.entered(expiration: expiration, now: now) {
      self.held = entered
      self.sentinelEntries += 1
    }
  }

  mutating func onResumeSentinel() {
    self.held = nil
  }

  mutating func onFilterDeath() {
    self.held = nil
  }
}

public extension RecordingExplorer {
  struct Violation: Equatable, Sendable, Codable, CustomStringConvertible {
    public var kind: String
    public var step: Int
    public var action: String
    public var detail: String

    public var description: String {
      "\(self.kind) at step \(self.step) [\(self.action)]: \(self.detail)"
    }
  }

  struct Stats: Equatable, Sendable, Codable {
    public init() {}

    public var blockedAllowed = 0
    public var blockedDropped = 0
    public var sentinelEntries = 0
    public var rederivedEntries = 0
    public var broadcasts = 0
    public var screenshotsCreated = 0
    public var uploadedDistinct = 0
  }

  struct RunResult: Sendable, Codable {
    public var seed: UInt64?
    public var actions: [ExplorerAction]
    public var violation: Violation?
    public var stats: Stats
    public var traceTail: [String]

    public var report: String {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      let data = (try? encoder.encode(self)) ?? Data()
      return String(decoding: data, as: UTF8.self)
    }
  }

  @MainActor
  static func run(seed: UInt64, steps: Int = 40) async -> RunResult {
    var rng = SeededRNG(seed: seed)
    let run = ExplorerRun()
    await run.bootstrap()
    var actions: [ExplorerAction] = []
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
      violation = await run.converge(controllerFirst: seed % 2 == 0, step: steps)
    }
    return RunResult(
      seed: seed,
      actions: actions,
      violation: violation,
      stats: run.finalStats(),
      traceTail: violation == nil ? [] : run.traceTail(),
    )
  }

  @MainActor
  static func replay(_ script: [ExplorerAction], converge: Bool = true) async -> RunResult {
    let run = ExplorerRun()
    await run.bootstrap()
    var actions: [ExplorerAction] = []
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
      violation = await run.converge(controllerFirst: false, step: script.count)
    }
    return RunResult(
      seed: nil,
      actions: actions,
      violation: violation,
      stats: run.finalStats(),
      traceTail: violation == nil ? [] : run.traceTail(),
    )
  }

  /// Greedy delta-debugging: repeatedly drop actions that don't affect the
  /// violation kind, until a fixpoint (or budget). Replays are cheap and
  /// deterministic, so this reliably turns a 40-action fuzz run into a
  /// minimal scenario a human can read.
  @MainActor
  static func shrink(
    _ script: [ExplorerAction],
    expecting kind: String,
    budget: Int = 250,
  ) async -> [ExplorerAction] {
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

@MainActor
final class ExplorerRun {
  let device: VirtualDevice
  var oracle = SpecOracle()
  var stats = RecordingExplorer.Stats()

  init() {
    var api = ScriptedApi.Config()
    api.blockRules = [.targetContains(value: "blocked.com")]
    api.connected = .init(blockRules: [.targetContains(value: "blocked.com")], webPolicy: nil)
    let connection = ChildIOSDeviceData_v2(
      childId: UUID(2),
      token: UUID(3),
      deviceId: UUID(4),
      childName: "Little Jimmy",
      supervised: nil,
    )
    self.device = VirtualDevice(
      disk: SimDisk.current(
        protectionMode: .connected([.targetContains(value: "blocked.com")], nil),
        connection: connection,
        disabledBlockGroupIds: [],
      ),
      api: api,
      filterInstalled: true,
    )
  }

  func bootstrap() async {
    await self.device.reboot()
    await self.device.quiesce()
  }

  func isEnabled(_ action: ExplorerAction) -> Bool {
    switch action {
    case .startBroadcast, .beginGrantedRecording:
      self.device.recorder == nil
    case .recordFrames, .recordStatic, .pauseFrameDelivery, .stopBroadcast, .lockDevice,
         .killRecorder:
      self.device.recorder != nil
    case .killFilter:
      self.device.filter != nil
    case .killController:
      self.device.controller != nil
    default:
      true
    }
  }

  func chooseAction(_ rng: inout SeededRNG) -> ExplorerAction {
    var menu: [(Int, ExplorerAction)] = [
      (20, .browseBlocked),
      (5, .browseSafe),
      (10, .advanceTime(seconds: pick(&rng, from: [1, 2, 3, 4, 5, 6, 7, 10, 20, 60, 240]))),
      (5, .grantSuspension(seconds: pick(&rng, from: [10, 30, 120, 300]))),
      (2, .clearExpiration),
      (7, .sendSuspendSentinel),
      (3, .sendResumeSentinel),
      (2, .spoofSuspendSentinel),
      (4, .quiesce),
      (3, .reboot(controllerFirst: rng.next() % 2 == 0)),
    ]
    if self.device.recorder == nil {
      menu.append((5, .startBroadcast))
      menu.append((9, .beginGrantedRecording(grantSeconds: pick(&rng, from: [60, 300]))))
    } else {
      menu.append((13, .recordFrames(seconds: pick(&rng, from: [5, 10, 20]))))
      menu.append((4, .recordStatic(seconds: pick(&rng, from: [5, 15]))))
      menu.append((4, .pauseFrameDelivery(seconds: pick(&rng, from: [3, 7, 15]))))
      menu.append((4, .stopBroadcast))
      menu.append((4, .lockDevice))
      menu.append((3, .killRecorder))
    }
    if self.device.filter != nil { menu.append((3, .killFilter)) }
    if self.device.controller != nil { menu.append((2, .killController)) }
    return weightedPick(menu, &rng)
  }

  func perform(_ action: ExplorerAction, step: Int) async -> RecordingExplorer.Violation? {
    switch action {
    case .browseBlocked:
      let expectLifted = self.oracle.onRegularFlow(
        expiration: self.device.diskSuspensionExpiration,
        lastScreenshot: self.device.diskScreenshotLastSaved,
        now: self.device.currentDate.value,
      )
      let verdict = await self.device.browse("blocked.com")
      if verdict == .allow { self.stats.blockedAllowed += 1 }
      else { self.stats.blockedDropped += 1 }
      if expectLifted, verdict != .allow {
        return self.violation(
          "L2-blocking-stuck", step, action,
          "registers say suspension is live but blocked flow got \(verdict)",
        )
      }
      if !expectLifted, verdict != .drop {
        return self.violation(
          "S1-unexpected-allow", step, action,
          "registers say no valid suspension but blocked flow got \(verdict)",
        )
      }

    case .browseSafe:
      _ = self.oracle.onRegularFlow(
        expiration: self.device.diskSuspensionExpiration,
        lastScreenshot: self.device.diskScreenshotLastSaved,
        now: self.device.currentDate.value,
      )
      let verdict = await self.device.browse("safe.com")
      if verdict != .allow {
        return self.violation(
          "S1-safe-flow-blocked", step, action, "safe flow got \(verdict)",
        )
      }

    case .advanceTime(let seconds):
      await self.device.advanceTime(seconds: seconds)

    case .grantSuspension(let seconds):
      self.device.seedSuspensionExpiration(secondsFromNow: seconds)

    case .clearExpiration:
      self.device.disk.withValue { $0[Key.suspensionExpiration.rawValue] = nil }

    case .sendSuspendSentinel:
      self.oracle.onSuspendSentinel(
        expiration: self.device.diskSuspensionExpiration,
        now: self.device.currentDate.value,
      )
      await self.device.deliverSentinel(.suspendFilter)

    case .sendResumeSentinel:
      self.oracle.onResumeSentinel()
      await self.device.deliverSentinel(.resumeFilter)

    case .spoofSuspendSentinel:
      await self.device.deliverSentinel(.suspendFilter, from: "com.evil.imposter")

    case .startBroadcast:
      self.stats.broadcasts += 1
      await self.device.startBroadcast()

    case .beginGrantedRecording(let grantSeconds):
      self.device.seedSuspensionExpiration(secondsFromNow: grantSeconds)
      self.stats.broadcasts += 1
      await self.device.startBroadcast()
      self.oracle.onSuspendSentinel(
        expiration: self.device.diskSuspensionExpiration,
        now: self.device.currentDate.value,
      )
      await self.device.deliverSentinel(.suspendFilter)
      await self.device.record(seconds: 5)

    case .recordFrames(let seconds):
      await self.device.record(seconds: seconds)

    case .recordStatic(let seconds):
      await self.device.record(seconds: seconds, changed: false)

    case .pauseFrameDelivery(let seconds):
      await self.device.pauseFrameDelivery(seconds: seconds)

    case .stopBroadcast:
      await self.device.stopBroadcast()

    case .lockDevice:
      await self.device.lockDevice()

    case .killFilter:
      self.oracle.onFilterDeath()
      await self.device.kill(.filter)

    case .killController:
      await self.device.kill(.controller)

    case .killRecorder:
      await self.device.kill(.recorder)

    case .reboot(let controllerFirst):
      self.oracle.onFilterDeath()
      await self.device
        .reboot(order: controllerFirst ? [.controller, .filter] : [.filter, .controller])
      await self.device.quiesce()

    case .quiesce:
      await self.device.quiesce()
    }
    return self.checkEvidenceConsistency(step, action)
  }

  /// C1 (convergence) + S2 (evidence conservation), checked at the end of
  /// every run: with no further user events, any reachable state must settle
  /// to blocking-on with the evidence backlog fully drained and every saved
  /// screenshot uploaded (at-least-once, deduped by id).
  func converge(controllerFirst: Bool, step: Int) async -> RecordingExplorer.Violation? {
    let action = ExplorerAction.quiesce
    await self.device.advanceTime(seconds: 60 * 60 * 24)
    if self.device.recorder != nil {
      await self.device.kill(.recorder)
    }
    self.oracle.onFilterDeath()
    await self.device
      .reboot(order: controllerFirst ? [.controller, .filter] : [.filter, .controller])
    await self.device.quiesce()
    for _ in 0 ..< 3 {
      let expectLifted = self.oracle.onRegularFlow(
        expiration: self.device.diskSuspensionExpiration,
        lastScreenshot: self.device.diskScreenshotLastSaved,
        now: self.device.currentDate.value,
      )
      if expectLifted {
        return self.violation(
          "C1-suspension-survived-convergence", step, action,
          "registers still derive a live suspension a day after last event",
        )
      }
      let verdict = await self.device.browse("blocked.com")
      if verdict != .drop {
        return self.violation(
          "C1-blocking-not-restored", step, action,
          "blocked flow got \(verdict) after convergence",
        )
      }
      await self.device.advanceTime(seconds: 6)
    }
    await self.device.deliverSentinel(.refreshRules)
    await self.device.quiesce()
    if !self.device.screenshotDisk.value.isEmpty {
      return self.violation(
        "C1-evidence-backlog-stranded", step, action,
        "\(self.device.screenshotDisk.value.count) screenshots left on disk after convergence",
      )
    }
    let uploaded = Set(self.device.api.uploadedScreenshots.value.map(\.id))
    let everSaved = self.device.screenshotsEverSaved.value
    let lost = everSaved.subtracting(uploaded)
    if !lost.isEmpty {
      return self.violation(
        "S2-evidence-lost", step, action,
        "\(lost.count) of \(everSaved.count) saved screenshots never uploaded",
      )
    }
    return self.checkEvidenceConsistency(step, action)
  }

  func checkEvidenceConsistency(
    _ step: Int,
    _ action: ExplorerAction,
  ) -> RecordingExplorer.Violation? {
    let uploaded = Set(self.device.api.uploadedScreenshots.value.map(\.id))
    let phantom = uploaded.subtracting(self.device.screenshotsEverSaved.value)
    guard phantom.isEmpty else {
      return self.violation(
        "S2-phantom-upload", step, action,
        "\(phantom.count) uploaded screenshot ids never existed on disk",
      )
    }
    return nil
  }

  func finalStats() -> RecordingExplorer.Stats {
    var stats = self.stats
    stats.sentinelEntries = self.oracle.sentinelEntries
    stats.rederivedEntries = self.oracle.rederivedEntries
    stats.screenshotsCreated = self.device.screenshotsEverSaved.value.count
    stats.uploadedDistinct = Set(self.device.api.uploadedScreenshots.value.map(\.id)).count
    return stats
  }

  func traceTail(_ count: Int = 80) -> [String] {
    self.device.trace.value.suffix(count).map(\.description)
  }

  private func violation(
    _ kind: String,
    _ step: Int,
    _ action: ExplorerAction,
    _ detail: String,
  ) -> RecordingExplorer.Violation {
    RecordingExplorer.Violation(
      kind: kind,
      step: step,
      action: action.description,
      detail: detail,
    )
  }
}

extension VirtualDevice {
  var diskScreenshotLastSaved: Date? {
    guard case .date(let date) = self.disk.value[Key.screenshotLastSaved.rawValue] else {
      return nil
    }
    return date
  }
}

private func pick<T>(_ rng: inout SeededRNG, from options: [T]) -> T {
  options[Int(rng.next() % UInt64(options.count))]
}

private func weightedPick(
  _ menu: [(Int, ExplorerAction)],
  _ rng: inout SeededRNG,
) -> ExplorerAction {
  let total = menu.reduce(0) { $0 + $1.0 }
  var roll = Int(rng.next() % UInt64(total))
  for (weight, action) in menu {
    roll -= weight
    if roll < 0 { return action }
  }
  return menu[menu.count - 1].1
}
