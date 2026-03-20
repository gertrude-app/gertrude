import ComposableArchitecture
import IOSRoute
import LibClients
import os.log

@Reducer
public struct InfoFeature {
  @ObservableState
  public struct State: Equatable, Sendable {
    public var connection: ChildIOSDeviceData_v2?
    public var deviceId: UUID?
    public var numRules: Int = 0
    public var numDisabledBlockGroups: Int = 0
    public var numTotalBlockGroups: Int = 9
    public var timesShaken: Int = 0
    public var subScreen: SubScreen = .main
    public var clearCache: ClearCacheFeature.State?

    public init(
      connection: ChildIOSDeviceData_v2? = nil,
      deviceId: UUID? = nil,
      numRules: Int = 0,
      numDisabledBlockGroups: Int = 0,
      numTotalBlockGroups: Int = 9,
      subScreen: SubScreen = .main,
    ) {
      self.connection = connection
      self.deviceId = deviceId
      self.numRules = numRules
      self.numDisabledBlockGroups = numDisabledBlockGroups
      self.numTotalBlockGroups = numTotalBlockGroups
      self.subScreen = subScreen
    }
  }

  public init() {
    self.deps.osLog.setPrefix("APP INFO FEATURE")
  }

  public enum SubScreen: Sendable, Equatable {
    case main
    case explainClearCache1
    case explainClearCache2
    case clearingCache
    case syncingProfile(URL)
    case syncProfileDownloaded
    case syncProfileNotRemovableWarning
    case syncProfileExplainInstall(regainedFocus: Bool = false)
  }

  public enum Action: Equatable {
    case sheetPresented
    case receivedShake
    case clearCacheTapped
    case explainClearCacheNextTapped
    case cancelClearCacheTapped
    case clearCache(ClearCacheFeature.Action)
    case syncProfileTapped
    case profileDownloadDismissed
    case syncProfileNextTapped
    case appEnteredForeground
  }

  struct Deps: Sendable {
    @Dependency(\.api) var api
    @Dependency(\.device) var device
    @Dependency(\.sharedStorage) var sharedStorage
    @Dependency(\.systemExtension) var systemExtension
    @Dependency(\.filter) var filter
    @Dependency(\.dismiss) var dismiss
    @Dependency(\.osLog) var osLog
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.continuousClock) var clock
  }

  enum CancelId {
    case cacheClearUpdates
  }

  @ObservationIgnored
  let deps = Deps()

  public var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .sheetPresented:
        state.subScreen = .main
        return .run { [state, deps = self.deps] _ in
          deps.osLog.log("Info appear device id: \(state.deviceId?.uuidString ?? "(nil)")")
          if let connection = state.connection {
            try await deps.refreshConnectedState(connection: connection)
          } else {
            try await deps.ensureUnconnectedRules(deviceId: state.deviceId)
            try await deps.filter.send(notification: .rulesChanged)
          }
        }

      case .syncProfileTapped:
        let deviceId = state.connection?.deviceId ?? state.deviceId ?? .init(6)
        state.subScreen = .syncingProfile(.profileDownload(deviceId: deviceId))
        return .none

      case .profileDownloadDismissed:
        state.subScreen = .syncProfileDownloaded
        return .none

      case .syncProfileNextTapped where state.subScreen == .syncProfileDownloaded:
        state.subScreen = .syncProfileNotRemovableWarning
        return .none

      case .syncProfileNextTapped where state.subScreen == .syncProfileNotRemovableWarning:
        state.subScreen = .syncProfileExplainInstall()
        return .none

      case .syncProfileNextTapped where state.subScreen.isSyncProfileExplainInstall:
        state.subScreen = .main
        return .none

      case .syncProfileNextTapped:
        state.subScreen = .main
        return .none

      case .appEnteredForeground:
        if case .syncProfileExplainInstall(false) = state.subScreen {
          state.subScreen = .syncProfileExplainInstall(regainedFocus: true)
        }
        return .none

      case .clearCacheTapped:
        state.subScreen = .explainClearCache1
        return .none

      case .cancelClearCacheTapped:
        state.clearCache = nil
        state.subScreen = .main
        return .none

      case .explainClearCacheNextTapped where state.subScreen == .explainClearCache1:
        state.subScreen = .explainClearCache2
        return .none

      case .explainClearCacheNextTapped where state.subScreen == .explainClearCache2:
        state.subScreen = .clearingCache
        state.clearCache = .init(context: .info)
        return .none

      case .explainClearCacheNextTapped:
        state.subScreen = .main
        return .run { [deps = self.deps] _ in
          await deps.api.logEvent("e81796af", "UNEXPECTED")
        }

      case .receivedShake where state.connection == nil && state.timesShaken == 5:
        self.deps.osLog.log("received 5th shake: entering unconnected recovery mode")
        state.timesShaken = 0
        return self.unconnectedRecovery()

      case .receivedShake where state.connection != nil && state.timesShaken == 5:
        self.deps.osLog.log("received 5th shake: entering connected recovery mode")
        state.timesShaken = 0
        return .run { [deps = self.deps] _ in
          await deps.sendRecoveryDirective()
          await deps.dismiss()
        }

      case .receivedShake:
        self.deps.osLog.log("received shake \(state.timesShaken + 1)")
        state.timesShaken += 1
        return .none

      case .clearCache(.completeBtnTapped),
           .clearCache(.receivedClearCacheUpdate(.errorCouldNotCreateDir)):
        state.clearCache = nil
        state.subScreen = .main
        return .none

      case .clearCache:
        return .none
      }
    }
    .ifLet(\.clearCache, action: \.clearCache) {
      ClearCacheFeature()
    }
  }

  func unconnectedRecovery() -> EffectOf<InfoFeature> {
    .run { [deps = self.deps] _ in
      await deps.api.logEvent("a8998540", "entering recovery mode")
      if deps.sharedStorage.loadDisabledBlockGroupIds() == nil {
        deps.osLog.log("unconnected recovery: no stored disabled block group ids, saving empty")
        deps.sharedStorage.saveDisabledBlockGroupIds([])
      } else {
        deps.osLog.log("unconnected recovery: disabled block groups already stored")
      }
      let rules = deps.sharedStorage.loadProtectionMode()
      deps.osLog.log("unconnected recovery: current rules: \(rules?.shortDesc ?? "(nil)")")
      if rules.missingRules {
        deps.osLog.log("unconnected recovery: rules missing, fetching defaults")
        await deps.api.logEvent("bcca235f", "rules missing in recovery mode")
        let defaultRules = try? await deps.api
          .fetchDefaultBlockRules(deps.device.deviceId())
        if let defaultRules, !defaultRules.isEmpty {
          deps.sharedStorage.saveProtectionMode(.normal(defaultRules))
          deps.osLog.log("unconnected recovery: saved fetched default rules")
        } else {
          await deps.api.logEvent("2c3a4481", "failed to fetch defaults in recovery mode")
          deps.sharedStorage
            .saveProtectionMode(.normal(BlockRule.Legacy.defaults.map(\.current)))
          deps.osLog.log("unconnected recovery: saved hardcoded default fallback rules")
        }
      }
      deps.osLog.log("unconnected recovery: sending rules changed notification")
      try await deps.filter.send(notification: .rulesChanged)
      deps.osLog.log("unconnected recovery: sending recovery directive")
      await deps.sendRecoveryDirective()
      deps.osLog.log("unconnected recovery: dismissing info screen")
      await deps.dismiss()
    }
  }
}

extension InfoFeature.SubScreen {
  var isSyncProfileExplainInstall: Bool {
    if case .syncProfileExplainInstall = self { return true }
    return false
  }
}

extension InfoFeature.Deps {
  func ensureUnconnectedRules(deviceId: UUID?) async throws {
    let disabled = self.sharedStorage.loadDisabledBlockGroupIds()
    if disabled == nil {
      await self.api.logEvent("59d3c6d1", "UNEXPECTED no stored disabled block groups ids")
      self.sharedStorage.saveDisabledBlockGroupIds([])
    }
    guard let deviceId else { return }
    let rules = try await self.api.fetchBlockRules(
      deviceId: deviceId,
      disabledGroups: disabled ?? [],
    )
    self.sharedStorage.saveProtectionMode(.normal(rules))
  }

  func refreshConnectedState(connection: ChildIOSDeviceData_v2) async throws {
    self.osLog.log("InfoFeature child id: \(connection.childId)")
    let before = self.sharedStorage.loadProtectionMode()
    self.osLog.log("InfoFeature connected rules before refresh: \(before?.shortDesc ?? "(nil)")")
    try await self.filter.send(notification: .refreshRules)
    try await self.clock.sleep(for: .seconds(2)) // time for api request, save rules
    let after = self.sharedStorage.loadProtectionMode()
    self.osLog.log("InfoFeature connected rules after refresh: \(after?.shortDesc ?? "(nil)")")
  }

  func sendRecoveryDirective() async {
    let directive = try? await self.api.recoveryDirective()
    if directive == "retry" {
      await self.systemExtension.cleanupForRetry()
      await self.api.logEvent("aeaa467d", "received retry directive")
    }
  }
}
