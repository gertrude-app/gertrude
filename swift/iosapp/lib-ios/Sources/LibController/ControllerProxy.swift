import ConcurrencyExtras
import Dependencies
import GertieBlocker
import IOSRoute
import LibClients
import LibCore
import ManagedSettings
import NetworkExtension

public final class ControllerProxy: Sendable {
  #if DEBUG
    static let API_DEBOUNCE_INTERVAL_NORMAL: TimeInterval = .minutes(3)
    static let API_DEBOUNCE_INTERVAL_CONNECTED: TimeInterval = .minutes(2)
  #else
    static let API_DEBOUNCE_INTERVAL_NORMAL: TimeInterval = .minutes(120)
    static let API_DEBOUNCE_INTERVAL_CONNECTED: TimeInterval = .minutes(20)
  #endif

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.osLog) var logger
    @Dependency(\.suspendingClock) var clock
    @Dependency(\.device) var device
    @Dependency(\.sharedStorage) var storage
    @Dependency(\.screenshotRepo) var screenshotRepo
    @Dependency(\.date.now) var now
    @Dependency(\.calendar) var calendar
  }

  enum RefreshReason {
    case startup
    case fauxHeartbeat
    case infoSheetPresented
  }

  let deps = Deps()
  let lastRefresh = LockIsolated<Date>(.distantPast)
  let managedSettings = LockIsolated<ManagedSettingsStore?>(nil)
  public let notifyRulesChanged = LockIsolated<() -> Void>(unimplemented("notifyRulesChanged"))

  #if DEBUG
    package let migrateTask = LockIsolated<Task<Void, Never>?>(nil)
  #endif

  public init() {
    self.deps.logger.setPrefix("CONTROLLER PROXY")
    #if DEBUG
      self.deps.logger.setObserver { msg, isDebug in
        if isDebug { return }
        self.deps.storage.saveDebugLog("\(Date()) [G•] CONTROLLER PROXY \(msg.prefix(100))")
      }
    #endif
    self.deps.logger.log("Initialized ControllerProxy")
    Witness.controllerProxyInit.emit()

    // proxy init handles migration, b/c app target might never launch after update
    // app target .appDidLaunch also attempts migration, but it's idempotent
    let task = Task {
      if await self.deps.storage.migrateLegacyData() {
        self.deps.logger.log("migration performed by controller")
        Witness.controllerMigrated.emit()
        await self.deps.api.logEvent(id: "99bacaaa", detail: "migration performed by controller")
        self.fireNotifyRulesChanged()
      }
    }

    #if DEBUG
      self.migrateTask.withValue { $0 = task }
    #endif
  }

  func fireNotifyRulesChanged() {
    Witness.controllerNotifiedRulesChanged.emit()
    self.notifyRulesChanged.withValue { $0() }
  }

  public func startFilter() -> Task<Void, Never> {
    self.deps.logger.log("starting filter")
    Witness.controllerStart.emit()
    return Task {
      await self.deps.api.logEvent(id: "00ec3909", detail: "controller proxy: filter started")
      self.deps.logger.log("start filter refresh rules 1")
      await self.refreshRules(reason: .startup)
      self.deps.logger.log("start filter refresh rules 2")
      try? await self.deps.clock.sleep(for: .seconds(15))
      await self.refreshRules(reason: .startup)
      self.deps.logger.log("start filter refresh rules 3")
      try? await self.deps.clock.sleep(for: .seconds(15))
      await self.refreshRules(reason: .startup)
    }
  }

  @discardableResult
  func refreshRules(reason: RefreshReason) async -> Bool {
    let conn = self.deps.storage.loadAccountConnection()

    if reason == .fauxHeartbeat {
      let interval = conn != nil
        ? Self.API_DEBOUNCE_INTERVAL_CONNECTED
        : Self.API_DEBOUNCE_INTERVAL_NORMAL
      if self.lastRefresh.withValue({ $0 }).advanced(by: interval) > self.deps.now {
        self.deps.logger.debug("skipping rule refresh, debounce")
        return false
      }
      self.lastRefresh.withValue { $0 = self.deps.now }
    }

    await self.drainLeftoverScreenshots()

    if let conn {
      return await self.refreshConnectedRules(conn)
    } else if let deviceId = await self.deps.device.deviceId() {
      return await self.refreshNormalRules(deviceId)
    } else {
      self.deps.logger.log("no vendor id, skipping rule update")
      return false
    }
  }

  func drainLeftoverScreenshots() async {
    let pending = self.deps.screenshotRepo.pendingCount()
    guard pending > 0 else { return }
    guard !RecordingSuspension.recordingIsLive(
      lastScreenshot: self.deps.storage.loadScreenshotLastSaved(),
      now: self.deps.now,
    ) else { return }
    self.deps.logger.log("draining \(pending) leftover screenshots")
    Witness.screenshotsDrained.emit("count=\(pending)")
    await uploadPendingScreenshots()
  }

  func refreshNormalRules(_ vendorId: UUID) async -> Bool {
    self.managedSettings.setValue(nil)
    guard let disabled = self.deps.storage.loadDisabledBlockGroupIds() else {
      self.deps.logger.log("no stored block groups, skipping rule update")
      return false
    }

    do {
      self.deps.logger.log("fetching rules from API")
      let apiRules = try await deps.api.fetchBlockRules(vendorId, disabled)

      guard apiRules.count > 0 else {
        self.deps.logger.log("unexpected empty rules from api")
        return false
      }

      let savedRules = self.deps.storage.loadProtectionMode()?.normalRules
      if apiRules != savedRules {
        self.deps.logger.log("saving changed rules")
        self.deps.storage.saveProtectionMode(.normal(apiRules))
        self.fireNotifyRulesChanged()
        return true
      } else {
        self.deps.logger.log("rules unchanged")
        return false
      }
    } catch {
      self.deps.logger.log("failed to fetch block rules: \(error)")
      return false
    }
  }

  func refreshConnectedRules(_ connection: ChildIOSDeviceData_v2) async -> Bool {
    do {
      self.deps.logger.log("fetching rules from API")
      // NB: always set the token, controller doesn't know when connection is made
      await self.deps.api.setAccountConnection(connection)
      let config = try await self.deps.api.connectedRules()
      guard config.blockRules.count > 0 else {
        self.deps.logger.log("unexpected empty rules from api (connected)")
        return false
      }
      let storedMode = self.deps.storage.loadProtectionMode() ?? .emergencyLockdown
      if storedMode == config.protectionMode {
        self.deps.logger.log("rules unchanged (connected)")
        return false
      }
      self.deps.logger.log("saving changed rules (connected)")
      self.deps.storage.saveProtectionMode(config.protectionMode)
      self.fireNotifyRulesChanged()
      self.deps.logger.log("web policy: \(String(describing: config.webPolicy))")
      self.managedSettings.withValue {
        if config.webPolicy == nil {
          $0 = nil
        } else {
          if let current = $0 {
            current.gertiePolicy = config.webPolicy
            self.deps.logger.log("updating existing managed settings store")
            $0 = current
          } else {
            self.deps.logger.log("creating new managed settings store")
            let store = ManagedSettingsStore(named: .init(.gertrudeGroupId))
            store.gertiePolicy = config.webPolicy
            $0 = store
          }
        }
      }
      return true
    } catch {
      self.deps.logger.log("failed to fetch connected rules: \(error)")
      return false
    }
  }

  @discardableResult
  public func stopFilter(reason: NEProviderStopReason) -> Task<Void, Never> {
    self.deps.logger.log("stopping filter")
    Witness.controllerStop.emit(String(describing: reason))
    return Task { [api = self.deps.api] in
      await api.logEvent(id: "8e23bea2", detail: "filter stopped, reason: \(reason)")
    }
  }

  public func handleNewFlow(_ systemFlow: NEFilterFlow) async -> NEFilterControlVerdict {
    // CONVENTION: we get here when the filter sends a `.needsRules` verdict, indicating
    // that according to it's incremental "timer", it thinks it's time to update the rules
    // unless the flow is the refresh rules sentinel, which means the info sheet was shown
    let flow = self.toFilterFlow(systemFlow)
    return await self.handleFilterFlow(flow)
  }

  package func handleFilterFlow(_ flow: FilterFlow) async -> NEFilterControlVerdict {
    Witness.controllerReceivedFlow.emit("target=\(flow.target ?? "(nil)")")
    if flow.hostname == MagicStrings.refreshRulesSentinalHostname {
      self.deps.logger.log("refresh rules requested from app, info sheet presented")
      let rulesChanged = await self.refreshRules(reason: .infoSheetPresented)
      Witness.controllerVerdict.emit("DROP update=\(rulesChanged)")
      return .drop(withUpdateRules: rulesChanged)
    }
    let rulesChanged = await self.refreshRules(reason: .fauxHeartbeat)
    let verdict = self.decideNewFlow(flow)
    Witness.controllerVerdict.emit("\(verdict.description) update=\(rulesChanged)")
    return switch verdict {
    case .allow:
      .allow(withUpdateRules: rulesChanged)
    case .drop:
      .drop(withUpdateRules: rulesChanged)
    case .needRules:
      .drop(withUpdateRules: true) // should be unreachable
    }
  }
}

extension ControllerProxy: FlowDecider {
  public var calendar: Calendar { self.deps.calendar }
  public var now: Date { self.deps.now }
  public var protectionMode: LibCore.ProtectionMode {
    self.deps.storage.loadProtectionMode() ?? .emergencyLockdown
  }

  public func debugLog(_ message: String) {
    self.deps.logger.debug(message)
  }

  public func log(_ message: String) {
    self.deps.logger.log(message)
  }
}

extension ConnectedRules.Output {
  var protectionMode: ProtectionMode {
    .connected(self.blockRules, self.webPolicy)
  }
}

#if os(iOS)
  extension ManagedSettingsStore {
    var gertiePolicy: WebContentFilterPolicy? {
      get { self.webContent.blockedByFilter?.gertiePolicy }
      set { self.webContent.blockedByFilter = newValue.map(\.managedSettingsPolicy) }
    }
  }
#else
  class ManagedSettingsStore {
    struct Name {
      init(_ value: String) {}
    }

    private var _policy: WebContentFilterPolicy?
    init(named: Name) {}
    var gertiePolicy: WebContentFilterPolicy? {
      get { self._policy }
      set { self._policy = newValue }
    }
  }

  public class NEFilterControlVerdict: Equatable {
    private enum Repr: Equatable {
      case allow(withUpdateRules: Bool)
      case drop(withUpdateRules: Bool)
      case updateRules
    }

    private let repr: Repr
    private init(_ repr: Repr) { self.repr = repr }
    public class func allow(withUpdateRules: Bool)
      -> NEFilterControlVerdict { .init(.allow(withUpdateRules: withUpdateRules)) }
    public class func drop(withUpdateRules: Bool)
      -> NEFilterControlVerdict { .init(.drop(withUpdateRules: withUpdateRules)) }
    public class func updateRules() -> NEFilterControlVerdict { .init(.updateRules) }

    public static func == (lhs: NEFilterControlVerdict, rhs: NEFilterControlVerdict) -> Bool {
      lhs.repr == rhs.repr
    }
  }
#endif
