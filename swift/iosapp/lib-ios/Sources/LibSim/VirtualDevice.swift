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
  public let api: ScriptedApi
  public let clock = TestClock<Duration>()
  public let currentDate: LockIsolated<Date>
  public let deviceId: UUID
  public let filterInstalled: LockIsolated<Bool>
  public let trace = LockIsolated<[TraceEvent]>([])

  public private(set) var filter: FilterProcess?
  public private(set) var controller: ControllerProcess?
  public private(set) var app: AppProcess?

  private let pendingRulesChanged = LockIsolated<[RulesChangedTrigger]>([])

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
  /// OS RULE R1 (extension launch): the system launches the data provider process
  /// and immediately calls `startFilter` after init; the two calls are not
  /// separated by other provider callbacks. Evidence: `[G•] FILTER init` /
  /// `[G•] FILTER start` always adjacent in on-device os_log capture.
  @discardableResult
  func launchFilter() -> FilterProcess {
    let process = FilterProcess(dependencies: self.dependencies(for: .filter))
    self.filter = process
    self.trace.withValue { $0.append(.launched(.filter)) }
    process.osStartFilter()
    return process
  }

  /// OS RULE R2 (extension launch): same shape as the filter — init, then
  /// `startFilter`. CONDUCTOR SIMPLIFICATION: the proxy's init-time migration
  /// task is awaited before `startFilter` runs; on a real device the two
  /// interleave nondeterministically. Revisit when exploring migration
  /// interleavings specifically.
  @discardableResult
  func launchController() async -> ControllerProcess {
    let pending = self.pendingRulesChanged
    let process = ControllerProcess(
      dependencies: self.dependencies(for: .controller),
      notifyRulesChanged: {
        pending.withValue { $0.append(.notifyRulesChanged) }
      },
    )
    self.controller = process
    self.trace.withValue { $0.append(.launched(.controller)) }
    await process.awaitMigration()
    process.osStartFilter()
    return process
  }

  /// The host app only ever launches when a user opens it; the OS never
  /// launches it on boot or on filter activity.
  @discardableResult
  func launchApp() async -> AppProcess {
    let process = AppProcess(dependencies: self.dependencies(for: .app))
    self.app = process
    self.trace.withValue { $0.append(.launched(.app)) }
    await process.store.send(.programmatic(.appDidLaunch))
    return process
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
    }
  }

  /// OS RULE R6 (reboot): after a device restart the system relaunches both
  /// providers of an enabled filter configuration on its own schedule, in an
  /// order we cannot rely on; the host app never relaunches automatically.
  /// Scenarios should be run with both orders.
  func reboot(order: [SimTarget] = [.filter, .controller]) async {
    for target in [SimTarget.app, .controller, .filter] where self.isRunning(target) {
      await self.kill(target)
    }
    self.trace.withValue { $0.append(.rebooted) }
    for target in order {
      switch target {
      case .filter: self.launchFilter()
      case .controller: await self.launchController()
      case .app: await self.launchApp()
      }
    }
  }

  func isRunning(_ target: SimTarget) -> Bool {
    switch target {
    case .filter: self.filter != nil
    case .controller: self.controller != nil
    case .app: self.app != nil
    }
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
  /// to a magic hostname from the app process; it reaches the filter as an
  /// ordinary socket flow, subject to the same delivery rules as any flow.
  func deliverSentinel(_ notification: FilterClient.Notification) async {
    self.trace.withValue { $0.append(.sentinelSent(notification)) }
    let hostname = switch notification {
    case .rulesChanged: MagicStrings.readRulesSentinalHostname
    case .refreshRules: MagicStrings.refreshRulesSentinalHostname
    case .dumpLogs: MagicStrings.dumpLogsSentinalHostname
    }
    await self.flow(FilterFlow(
      hostname: hostname,
      bundleId: .gertrudeBundleIdShort,
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
  /// without further user interaction.
  private func osStartsProviders() async {
    if self.filter == nil {
      self.launchFilter()
    }
    if self.controller == nil {
      await self.launchController()
    }
  }

  /// Drains all pending async work deterministically: unstructured tasks,
  /// queued OS deliveries, and every sleep scheduled on the shared test clock.
  func quiesce() async {
    for _ in 0 ..< 10 {
      await Task.megaYield()
      self.drainRulesChanged()
      await self.clock.run()
    }
    if let task = self.controller?.startupTask {
      await task.value
    }
    if let app = self.app {
      await app.store.finish()
      await app.store.skipReceivedActions(strict: false)
    }
    await Task.megaYield()
    self.drainRulesChanged()
  }

  /// Advances wall-clock time and the shared test clock together, keeping
  /// `Date`-based logic (debounce intervals) and `Clock`-based logic (sleeps)
  /// on one timeline.
  func advanceTime(minutes: Int) async {
    self.currentDate.withValue { $0 += TimeInterval(minutes * 60) }
    await self.clock.advance(by: .minutes(minutes))
  }
}

// dependency wiring

extension VirtualDevice {
  private func dependencies(for target: SimTarget) -> @Sendable (inout DependencyValues)
    -> Void {
    let clock = self.clock
    let currentDate = self.currentDate
    let disk = self.disk
    let trace = self.trace
    let deviceId = self.deviceId
    let filterInstalled = self.filterInstalled
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
        deps.device.deviceId = { deviceId }

      case .app:
        deps.sharedStorage = .liveValue
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
