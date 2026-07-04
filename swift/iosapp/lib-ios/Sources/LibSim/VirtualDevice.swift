import Clocks
import ComposableArchitecture
import ConcurrencyExtras
import Dependencies
import Foundation
import GertieBlocker
import IOSRoute
import LibApp
import LibClients
import LibController
import LibCore
import LibFilter
import XCore

/// An in-process simulation of one physical iOS device running the blocker:
/// the durable world (app-group storage, clock, API) plus up to three live
/// "processes" (app, controller extension, filter extension) built from the
/// real production types, each wired to the world through its own dependency
/// scope. The conductor methods model the OS behaviors that connect them; every
/// modeled OS behavior is documented inline as an `OS RULE` with its evidence,
/// because the harness tests our code against this model of iOS, not iOS itself.
@MainActor
public final class VirtualDevice {
  public let disk: LockIsolated<[String: GroupDefaultsClient.Entry]>
  public let screenshotDisk = LockIsolated<[ScreenshotData]>([])
  public let api: ScriptedApi
  public let clock = TestClock<Duration>()
  public let currentDate: LockIsolated<Date>
  public let deviceId: UUID
  public let filterInstalled: LockIsolated<Bool>
  public let trace = LockIsolated<[TraceEvent]>([])

  public private(set) var filter: FilterProcess?
  public private(set) var controller: ControllerProcess?
  public private(set) var app: AppProcess?
  public private(set) var recorder: RecorderProcess?
  public private(set) var appIsSuspended = false

  private let pendingRulesChanged = LockIsolated<[RulesChangedTrigger]>([])
  private let pendingRecorderEvents = LockIsolated<[RecorderEvent]>([])

  public init(
    disk: [String: GroupDefaultsClient.Entry] = [:],
    api: ScriptedApi.Config = .init(),
    filterInstalled: Bool = false,
    deviceId: UUID = UUID(1),
    now: Date = Date(timeIntervalSinceReferenceDate: 0),
  ) {
    self.disk = LockIsolated(disk)
    self.api = ScriptedApi(api)
    self.filterInstalled = LockIsolated(filterInstalled)
    self.deviceId = deviceId
    self.currentDate = LockIsolated(now)
  }
}

// process lifecycle

public extension VirtualDevice {
  /// OS RULE R1 (extension launch): the system spawns the data provider process
  /// (proxy constructed → `filter-proxy-init` witness) and calls `startFilter`
  /// (`filter-start` witness). Device-verified 2026-07-03 (collect campaign
  /// `witnesses-20260703-120635.ndjson`): on a JOINT launch (install/reboot) both
  /// proxy-inits precede both *-start witnesses — the OS spawns both processes
  /// first, then starts both (controller-init interleaves between filter-init
  /// and filter-start). For on-demand single launches (a flow arrives with the
  /// filter dead) init and start are adjacent for that one process, so
  /// `launchFilter` bundles them; `osStartsProviders`/`reboot` use the split
  /// `initFilter` + `startFilterProcess` to model the joint sequence.
  @discardableResult
  func launchFilter() -> FilterProcess {
    let process = self.initFilter()
    self.startFilterProcess()
    return process
  }

  @discardableResult
  func initFilter() -> FilterProcess {
    let process = FilterProcess(dependencies: self.dependencies(for: .filter))
    self.filter = process
    self.trace.withValue { $0.append(.launched(.filter)) }
    return process
  }

  func startFilterProcess() {
    self.filter?.osStartFilter()
  }

  /// OS RULE R2 (extension launch): same spawn-then-start shape as the filter.
  /// The controller proxy's init kicks off legacy-data migration as a
  /// fire-and-forget Task (production code, `ControllerProxy.init`);
  /// `startFilter` is called separately and does NOT await it — migration runs
  /// concurrently with the startup refresh-rules loop. Device-verified
  /// 2026-07-03: controller-init interleaves between filter-init and
  /// filter-start on a joint launch. The sim previously serialized migration
  /// before start (`awaitMigration()`); it no longer does — `quiesce` awaits
  /// both the startup and migration tasks so assertions read a settled world
  /// while the interleaving during the run is real.
  @discardableResult
  func launchController() async -> ControllerProcess {
    let process = self.initController()
    self.startControllerProcess()
    return process
  }

  @discardableResult
  func initController() -> ControllerProcess {
    let pending = self.pendingRulesChanged
    let process = ControllerProcess(
      dependencies: self.dependencies(for: .controller),
      notifyRulesChanged: {
        pending.withValue { $0.append(.notifyRulesChanged) }
      },
    )
    self.controller = process
    self.trace.withValue { $0.append(.launched(.controller)) }
    return process
  }

  func startControllerProcess() {
    self.controller?.osStartFilter()
  }

  /// The host app only ever launches when a user opens it; the OS never
  /// launches it on boot or on filter activity.
  @discardableResult
  func launchApp() async -> AppProcess {
    let process = AppProcess(dependencies: self.dependencies(for: .app))
    self.app = process
    self.appIsSuspended = false
    self.trace.withValue { $0.append(.launched(.app)) }
    await process.store.send(.programmatic(.appDidLaunch))
    return process
  }

  /// OS RULE R12 (app suspension): seconds after the user backgrounds the app,
  /// the OS suspends it — the process stays alive with its in-memory state, but
  /// gets no CPU: timers freeze, effects stall, and darwin notifications are
  /// held for coalesced delivery on resume (see OS RULE R11). Device-verified
  /// 2026-07-04 (hinge session): the suspended app performed zero uploads and
  /// received zero darwin deliveries for a full 28-min recording; the
  /// `broadcastFinished` event arrived only on reopen. SIMPLIFICATION: effects
  /// already in flight on the shared test clock still tick in the sim; what is
  /// modeled is event delivery (queued) and the resume boundary.
  func suspendApp() {
    guard self.app != nil, !self.appIsSuspended else { return }
    self.appIsSuspended = true
    self.trace.withValue { $0.append(.appSuspended) }
  }

  /// Resuming delivers held darwin events COALESCED — one delivery per distinct
  /// notification name, since each `RecorderEvent` kind is its own darwin name
  /// (notify(3) semantics; OS RULE R11). `foreground: true` models the normal
  /// resume path (user reopens the app → scenePhase active); `false` models a
  /// brief background wake (e.g. a bg-URLSession completion).
  func resumeApp(foreground: Bool = true) async {
    guard let app = self.app, self.appIsSuspended else { return }
    self.appIsSuspended = false
    let coalesced = self.pendingRecorderEvents.withValue { queued in
      var seen = Set<RecorderEvent>()
      let unique = queued.filter { seen.insert($0).inserted }
      queued = []
      return unique
    }
    self.trace.withValue { $0.append(.appResumed(coalescedEvents: coalesced)) }
    for event in coalesced {
      self.trace.withValue { $0.append(.recorderEventDelivered(event)) }
      await app.store.send(.programmatic(.receivedRecorderEvent(event)))
    }
    if foreground {
      await app.store.send(.programmatic(.appDidEnterForeground))
    }
  }

  /// OS RULE R9 (process death): a process can be killed at any moment (memory
  /// pressure, reboot, update) losing all in-memory state; durable world state
  /// (app-group storage) survives. In-flight work dies with the process —
  /// modeled by task cancellation plus cancellation checks at the scripted API
  /// boundary, which is imperfect: a task between its last API call and a
  /// storage write can still perform that write after "death".
  func kill(_ target: SimTarget) async {
    self.trace.withValue { $0.append(.killed(target)) }
    switch target {
    case .filter:
      self.filter = nil
    case .controller:
      self.controller?.osKill()
      self.controller = nil
    case .app:
      await self.app?.osKill()
      self.app = nil
      self.appIsSuspended = false
    case .recorder:
      self.recorder?.osKill()
      self.recorder = nil
    }
  }

  /// OS RULE R6 (reboot): after a device restart the system relaunches both
  /// providers of an enabled filter configuration on its own schedule. The host
  /// app never relaunches automatically. A live broadcast dies with the reboot
  /// and the recorder extension is never relaunched by the system (see OS RULE
  /// R10). Device-verified 2026-07-03: the OS spawns both provider processes
  /// (init) before starting either; the START order is the indeterminate part
  /// the `order` parameter exercises. Scenarios should be run with both start
  /// orders. NOTE: across 6 observed launches (2 onboarding + 4 reboots) the
  /// filter (data provider) has ALWAYS initialized first (160-574ms before the
  /// controller), never controller-first — the "indeterminate" claim is
  /// unverified and may be deterministically filter-first. Both orders are
  /// still tested conservatively.
  func reboot(order: [SimTarget] = [.filter, .controller]) async {
    for target in [SimTarget.app, .recorder, .controller, .filter] where self.isRunning(target) {
      await self.kill(target)
    }
    self.trace.withValue { $0.append(.rebooted) }
    self.initFilter()
    self.initController()
    for target in order {
      switch target {
      case .filter: self.startFilterProcess()
      case .controller: self.startControllerProcess()
      case .app: await self.launchApp()
      case .recorder: break
      }
    }
  }

  func isRunning(_ target: SimTarget) -> Bool {
    switch target {
    case .filter: self.filter != nil
    case .controller: self.controller != nil
    case .app: self.app != nil
    case .recorder: self.recorder != nil
    }
  }
}

// broadcast (screen recording) lifecycle

public extension VirtualDevice {
  /// OS RULE R10 (broadcast lifecycle): when the user confirms Gertrude's
  /// recorder in the system broadcast picker, the system launches the recorder
  /// extension process and calls `broadcastStarted`, then delivers video sample
  /// buffers continuously (many per second) while the recording is live;
  /// stopping the recording calls `broadcastFinished` but the process may
  /// linger briefly afterward. The extension runs under a strict ~50MB memory
  /// limit and can be killed by the system at any moment; a reboot always kills
  /// it, and the system never relaunches it on its own. Evidence: Apple
  /// RPBroadcastSampleHandler docs + on-device observation during the 2025
  /// recording experiment (`bak-swift` branch `chris`).
  @discardableResult
  func startBroadcast(
    screenshotInterval: TimeInterval = RecordingSuspension.defaultScreenshotInterval,
  ) async -> RecorderProcess {
    let process = RecorderProcess(
      dependencies: self.dependencies(for: .recorder),
      screenshotInterval: screenshotInterval,
    )
    self.recorder = process
    self.trace.withValue { $0.append(.launched(.recorder)) }
    self.trace.withValue { $0.append(.broadcastStarted) }
    process.osBroadcastStarted()
    await self.quiesce()
    return process
  }

  /// OS RULE R11 (darwin notifications): a darwin notification is delivered
  /// promptly to running, non-suspended observer processes; nothing is queued
  /// for a process that isn't running. A *suspended* app holds its
  /// registrations and receives one COALESCED delivery per distinct
  /// notification name on resume (see `resumeApp`). Evidence: notify(3)
  /// semantics; device-verified 2026-07-04 — zero deliveries to the suspended
  /// app during a 28-min recording, `broadcastFinished` arrived on reopen.
  private func drainRecorderEvents() async {
    if self.app != nil, self.appIsSuspended { return }
    let events = self.pendingRecorderEvents.withValue { queued in
      let drained = queued
      queued = []
      return drained
    }
    for event in events {
      if let app = self.app {
        self.trace.withValue { $0.append(.recorderEventDelivered(event)) }
        await app.store.send(.programmatic(.receivedRecorderEvent(event)))
      } else {
        self.trace.withValue { $0.append(.recorderEventDropped(event)) }
      }
    }
  }

  /// OS RULE R10: one video sample buffer reaching `processSampleBuffer`;
  /// `changed: false` models a buffer whose pixels are (nearly) identical to
  /// the previous processed frame.
  func deliverSample(changed: Bool = true) async {
    guard let recorder = self.recorder, recorder.isBroadcasting else { return }
    recorder.osDeliverSample(changed: changed)
    if let error = recorder.broadcastErrors.first {
      self.trace.withValue { $0.append(.broadcastErrored(error)) }
      await self.stopBroadcast()
    }
  }

  /// Models the passage of recording time: every heartbeat interval the
  /// throttle admits one sample buffer for processing.
  func record(seconds: Int, changed: Bool = true) async {
    let step = Int(RecordingSuspension.heartbeatInterval)
    var remaining = seconds
    while remaining > 0 {
      await self.deliverSample(changed: changed)
      let advance = min(step, remaining)
      await self.advanceTime(seconds: advance)
      remaining -= advance
    }
    await self.quiesce()
  }

  /// OS RULE R10 (refinement, corrected 2026-07-04 lock/static validation):
  /// models a frame-delivery pause — the broadcast stays alive but no sample
  /// buffers arrive, so the liveness heartbeat starves (system pause / memory
  /// pressure; ReplayKit's `broadcastPaused` callback exists for some of
  /// these, modeled here as a bare gap since no pause callback was observed
  /// on device outside a lock). NOT what a device lock does — locking cleanly
  /// FINISHES the broadcast (`lockDevice()`) — and NOT what a static screen
  /// does: buffers keep arriving for static content and the recorder bumps
  /// liveness with kind=unchanged. The hinge session's 10-19s bump gaps — one
  /// of which tripped the pre-D2 suspension trapdoor — were the spike bumping
  /// liveness only on saves, starved by a static screen. Kept because L1/L2
  /// must survive delivery gaps whatever their cause.
  func pauseFrameDelivery(seconds: Int) async {
    await self.advanceTime(seconds: seconds)
    await self.quiesce()
  }

  /// OS RULE R10 (lock, device-verified 2026-07-04 lock/static validation):
  /// locking the device — side-button press or idle auto-lock alike — cleanly
  /// FINISHES a live broadcast within ~3s: `broadcastPaused` immediately
  /// followed by `broadcastFinished` (tombstone + darwin), then process exit.
  /// A lock never pauses-and-survives. The app (if running) suspends with the
  /// lock, so the finish darwin event is held for coalesced delivery on
  /// resume — observed on device arriving 9 minutes later, on reopen.
  func lockDevice() async {
    self.suspendApp()
    if let recorder = self.recorder, recorder.isBroadcasting {
      recorder.osBroadcastPaused()
      await self.stopBroadcast()
    }
  }

  /// User ends the recording gracefully: `broadcastFinished` runs (tombstoning
  /// the liveness timestamp and posting the darwin event), then the process
  /// exits.
  func stopBroadcast() async {
    guard let recorder = self.recorder else { return }
    self.trace.withValue { $0.append(.broadcastFinished) }
    recorder.osBroadcastFinished()
    await self.quiesce()
    await self.kill(.recorder)
  }
}

// os event delivery

public extension VirtualDevice {
  /// OS RULE R3 (flow delivery): every new network flow on the device goes to the
  /// filter data provider's `handleNewFlow` while the filter configuration is
  /// installed & enabled; with no configuration, traffic flows unfiltered. If
  /// the provider process is not running, the system starts it on demand.
  ///
  /// OS RULE R3/R4 (needRules): when the data provider verdicts `.needRules()`, the
  /// system delivers the same flow to the control provider's `handleNewFlow`
  /// (starting that process if needed); the control verdict decides the flow,
  /// and `withUpdateRules: true` causes the system to call the data provider's
  /// `handleRulesChanged()`. Evidence: Apple NEFilterProvider docs + the
  /// production convention documented in `ControllerProxy.handleNewFlow`.
  /// SIMPLIFICATION: the sim models this as 1:1 (every needRules gets a
  /// controller delivery). Device-verified 2026-07-03: 72/73 paired in a
  /// 40-min session; the one miss was a 35ms burst of 4 needRules verdicts
  /// where the OS coalesced them into a single controller delivery. This is
  /// an OS-level flow-batching optimization, not a correctness issue — the
  /// steady-state 1:1 model is correct and the burst edge is not modeled.
  @discardableResult
  func flow(_ flow: FilterFlow) async -> FlowVerdict {
    guard self.filterInstalled.value else {
      self.trace.withValue { $0.append(.unfilteredFlow(target: flow.target)) }
      return .allow
    }
    if self.filter == nil {
      self.trace.withValue { $0.append(.launchedOnDemand(.filter)) }
      self.launchFilter()
    }
    let verdict = self.filter!.decide(flow)
    self.trace.withValue {
      $0.append(.flowDecided(target: flow.target, verdict: verdict.description))
    }
    guard verdict == .needRules else {
      self.drainRulesChanged()
      return verdict
    }
    if self.controller == nil {
      self.trace.withValue { $0.append(.launchedOnDemand(.controller)) }
      await self.launchController()
    }
    let control = await self.controller!.handleNewFlow(flow)
    let (allowed, updateRules) = interpret(control)
    self.trace.withValue {
      $0.append(.controlVerdict(target: flow.target, verdict: allowed ? "ALLOW" : "DROP"))
    }
    if updateRules {
      self.deliverRulesChanged(.withUpdateRules)
    }
    self.drainRulesChanged()
    return allowed ? .allow : .drop
  }

  @discardableResult
  func browse(_ hostname: String, from bundleId: String = "com.apple.mobilesafari") async
    -> FlowVerdict {
    await self.flow(FilterFlow(hostname: hostname, bundleId: bundleId, flowType: .socket))
  }

  /// OS RULE R7 (sentinel channel): `FilterClient.send` fires a real HTTPS request
  /// to a magic hostname from the app (or recorder) process; it reaches the
  /// filter as an ordinary socket flow, subject to the same delivery rules as
  /// any flow, and carrying the sending process's bundle id. SIMPLIFICATION:
  /// modeled as one send → one flow. Device-verified 2026-07-03 (collect
  /// campaign `witnesses-20260703-142112.ndjson`): each single send produced
  /// 6-8 `filter-sentinel` flow deliveries (one HTTPS request fans out into
  /// multiple flows — retries/connection attempts). Harmless for rule
  /// semantics (sentinel handling is idempotent per notification kind); the
  /// fan-out is not modeled.
  func deliverSentinel(
    _ notification: FilterClient.Notification,
    from bundleId: String = .gertrudeBundleIdShort,
  ) async {
    self.trace.withValue { $0.append(.sentinelSent(notification)) }
    let hostname = switch notification {
    case .rulesChanged: MagicStrings.readRulesSentinalHostname
    case .refreshRules: MagicStrings.refreshRulesSentinalHostname
    case .dumpLogs: MagicStrings.dumpLogsSentinalHostname
    case .suspendFilter: MagicStrings.suspendFilterSentinalHostname
    case .resumeFilter: MagicStrings.resumeFilterSentinalHostname
    }
    await self.flow(FilterFlow(
      hostname: hostname,
      bundleId: bundleId,
      flowType: .socket,
    ))
  }

  /// OS RULE R5 (notifyRulesChanged): the control provider's
  /// `notifyRulesChanged()` causes the system to call the data provider's
  /// `handleRulesChanged()` asynchronously; if the data provider is not
  /// running, the notification is lost. Modeled as a queue drained by the
  /// conductor on the next flow or quiesce.
  private func drainRulesChanged() {
    let triggers = self.pendingRulesChanged.withValue { queued in
      let drained = queued
      queued = []
      return drained
    }
    for trigger in triggers {
      self.deliverRulesChanged(trigger)
    }
  }

  private func deliverRulesChanged(_ trigger: RulesChangedTrigger) {
    if let filter = self.filter {
      filter.osHandleRulesChanged()
      self.trace.withValue { $0.append(.rulesChangedDelivered(trigger)) }
    } else {
      self.trace.withValue { $0.append(.rulesChangedDropped(trigger)) }
    }
  }

  /// OS RULE R8 (install): once the app successfully saves an enabled filter
  /// configuration (`saveToPreferences`), the system starts both providers
  /// without further user interaction. Device-verified 2026-07-03: both
  /// processes are spawned (init) before either is started.
  private func osStartsProviders() async {
    let needFilter = self.filter == nil
    let needController = self.controller == nil
    if needFilter { self.initFilter() }
    if needController { self.initController() }
    if needFilter { self.startFilterProcess() }
    if needController { self.startControllerProcess() }
  }

  /// Lets in-flight async work land without running the shared clock to idle;
  /// use instead of `quiesce` while an unresolved periodic effect (like the
  /// app's suspension-decision polling) is scheduled on the shared clock, which
  /// would make `quiesce`'s run-to-idle spin forever.
  func settle() async {
    for _ in 0 ..< 10 {
      await Task.megaYield()
      self.drainRulesChanged()
      await self.drainRecorderEvents()
    }
  }

  /// Drains all pending async work deterministically: unstructured tasks,
  /// queued OS deliveries, and every sleep scheduled on the shared test clock.
  func quiesce() async {
    for _ in 0 ..< 10 {
      await Task.megaYield()
      self.drainRulesChanged()
      await self.drainRecorderEvents()
      await self.clock.run(timeout: .seconds(5))
    }
    if let task = self.controller?.startupTask {
      await task.value
    }
    await self.controller?.awaitMigration()
    if let app = self.app {
      await app.store.finish()
      await app.store.skipReceivedActions(strict: false)
    }
    await Task.megaYield()
    self.drainRulesChanged()
    await self.drainRecorderEvents()
  }

  /// Advances wall-clock time and the shared test clock together, keeping
  /// `Date`-based logic (debounce intervals) and `Clock`-based logic (sleeps)
  /// on one timeline.
  func advanceTime(minutes: Int) async {
    await self.advanceTime(seconds: minutes * 60)
  }

  func advanceTime(seconds: Int) async {
    self.currentDate.withValue { $0 += TimeInterval(seconds) }
    await self.clock.advance(by: .seconds(seconds))
  }
}

// dependency wiring

extension VirtualDevice {
  private func dependencies(for target: SimTarget) -> @Sendable (inout DependencyValues)
    -> Void {
    let clock = self.clock
    let currentDate = self.currentDate
    let disk = self.disk
    let screenshotDisk = self.screenshotDisk
    let trace = self.trace
    let deviceId = self.deviceId
    let filterInstalled = self.filterInstalled
    let pendingRecorderEvents = self.pendingRecorderEvents
    let apiClient = self.api.client(for: target)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let fixedCalendar = calendar
    let sendSentinel: @Sendable (FilterClient.Notification) async throws -> Void =
      { [weak self] notification in
        await self?.deliverSentinel(notification)
      }
    let providersStarted: @Sendable () async -> Void = { [weak self] in
      await self?.osStartsProviders()
    }

    return { deps in
      deps.date = DateGenerator { currentDate.value }
      deps.calendar = fixedCalendar
      deps.locale = Locale(identifier: "en_US")
      deps.continuousClock = clock
      deps.suspendingClock = clock
      deps.groupDefaults = .inMemory(disk)
      deps.osLog = .noop
      deps.osLog.log = { message in trace.withValue { $0.append(.log(target, message)) } }
      deps.api = apiClient

      switch target {
      case .filter:
        deps.sharedStorageReader = .liveValue

      case .controller:
        deps.sharedStorage = .liveValue
        deps.screenshotRepo = .inMemory(screenshotDisk)
        deps.device.deviceId = { deviceId }

      case .recorder:
        deps.sharedStorage = .liveValue
        deps.screenshotRepo = .inMemory(screenshotDisk)
        deps.recorderEvents.emit = { event in
          pendingRecorderEvents.withValue { $0.append(event) }
        }

      case .app:
        deps.sharedStorage = .liveValue
        deps.screenshotRepo = .inMemory(screenshotDisk)
        deps.device.deviceId = { deviceId }
        deps.device.installedVersion = { "1.9.0" }
        deps.device.deleteCacheFillDir = {}
        deps.device.data = { .init(
          type: .iPhone,
          iOSVersion: "18.0.1",
          deviceId: deviceId,
          modelIdentifier: "iPhone15,2",
        ) }
        #if DEBUG
          deps.keychain = .mock
        #endif
        deps.appStore.requestRating = {}
        deps.appStore.requestReview = {}
        deps.mainQueue = .immediate
        deps.systemExtension.requestAuthorization = { .success(()) }
        deps.systemExtension.installFilter = {
          filterInstalled.setValue(true)
          await providersStarted()
          return .success(())
        }
        deps.systemExtension.filterRunning = { filterInstalled.value }
        deps.systemExtension.cleanupForRetry = { filterInstalled.setValue(false) }
        deps.filter.send = sendSentinel
      }
    }
  }
}

private func interpret(_ verdict: NEFilterControlVerdict) -> (allowed: Bool, updateRules: Bool) {
  if verdict == .allow(withUpdateRules: true) { return (true, true) }
  if verdict == .allow(withUpdateRules: false) { return (true, false) }
  if verdict == .drop(withUpdateRules: true) { return (false, true) }
  if verdict == .drop(withUpdateRules: false) { return (false, false) }
  return (false, true)
}

// world inspection

public extension VirtualDevice {
  var diskProtectionMode: ProtectionMode? {
    guard case .data(let data) = self.disk.value[Key.protectionMode.rawValue] else {
      return nil
    }
    return try? JSONDecoder().decode(ProtectionMode.self, from: data)
  }

  var diskSuspensionExpiration: Date? {
    guard case .date(let date) = self.disk.value[Key.suspensionExpiration.rawValue] else {
      return nil
    }
    return date
  }

  /// Seeds the app-group disk with a suspension expiration, as the app would
  /// write on receiving a parent's grant.
  func seedSuspensionExpiration(secondsFromNow seconds: Int) {
    let expiration = self.currentDate.value + TimeInterval(seconds)
    self.disk.withValue { $0[Key.suspensionExpiration.rawValue] = .date(expiration) }
  }

  func logs(for target: SimTarget) -> [String] {
    self.trace.value.compactMap { event in
      if case .log(let logTarget, let message) = event, logTarget == target {
        message
      } else {
        nil
      }
    }
  }

  var traceDescription: String {
    self.trace.value.map(\.description).joined(separator: "\n")
  }
}

// disk seeding

public enum SimDisk {
  public static func current(
    protectionMode: ProtectionMode? = nil,
    connection: ChildIOSDeviceData_v2? = nil,
    disabledBlockGroupIds: [UUID]? = nil,
    allBlockGroups: [GetBlockGroups.BlockGroupInfo]? = nil,
    firstLaunch: Date? = Date(timeIntervalSinceReferenceDate: 0),
  ) -> [String: GroupDefaultsClient.Entry] {
    var disk: [String: GroupDefaultsClient.Entry] = [:]
    if let protectionMode {
      disk[Key.protectionMode.rawValue] = .data(try! JSONEncoder().encode(protectionMode))
    }
    if let connection {
      disk[Key.accountConnection_v2.rawValue] = .data(try! JSONEncoder().encode(connection))
    }
    if let disabledBlockGroupIds {
      disk[Key.disabledBlockGroupIds.rawValue] =
        .data(try! JSONEncoder().encode(disabledBlockGroupIds))
    }
    if let allBlockGroups {
      disk[Key.allBlockGroups.rawValue] = .data(try! JSONEncoder().encode(allBlockGroups))
    }
    if let firstLaunch {
      disk[Key.firstLaunchDate.rawValue] = .date(firstLaunch)
    }
    return disk
  }

  package static func v1_3_upgrader(
    legacyMode: ProtectionMode.Legacy,
    disabledGroups: [BlockGroup],
    firstLaunch: Date = Date(timeIntervalSinceReferenceDate: 0),
  ) -> [String: GroupDefaultsClient.Entry] {
    [
      Key.legacyProtectionMode.rawValue: .data(try! JSONEncoder().encode(legacyMode)),
      Key.disabledBlockGroups.rawValue: .data(try! JSONEncoder().encode(disabledGroups)),
      Key.firstLaunchDate.rawValue: .date(firstLaunch),
    ]
  }
}
