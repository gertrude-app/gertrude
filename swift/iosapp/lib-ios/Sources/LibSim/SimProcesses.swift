import ComposableArchitecture
import Dependencies
import Foundation
import LibApp
import LibClients
import LibController
import LibCore
import LibFilter

public enum SimTarget: String, Sendable, Equatable {
  case app
  case controller
  case filter
}

public enum RulesChangedTrigger: String, Sendable, Equatable {
  case notifyRulesChanged
  case withUpdateRules
}

public enum TraceEvent: Sendable, Equatable, CustomStringConvertible {
  case launched(SimTarget)
  case launchedOnDemand(SimTarget)
  case killed(SimTarget)
  case rebooted
  case unfilteredFlow(target: String?)
  case flowDecided(target: String?, verdict: String)
  case controlVerdict(target: String?, verdict: String)
  case sentinelSent(FilterClient.Notification)
  case rulesChangedDelivered(RulesChangedTrigger)
  case rulesChangedDropped(RulesChangedTrigger)
  case log(SimTarget, String)

  public var description: String {
    switch self {
    case .launched(let target): "os launched \(target.rawValue)"
    case .launchedOnDemand(let target): "os launched \(target.rawValue) on demand"
    case .killed(let target): "os killed \(target.rawValue)"
    case .rebooted: "device rebooted"
    case .unfilteredFlow(let target): "unfiltered flow: \(target ?? "(nil)")"
    case .flowDecided(let target, let verdict): "filter: \(verdict) `\(target ?? "(nil)")`"
    case .controlVerdict(let target, let verdict): "controller: \(verdict) `\(target ?? "(nil)")`"
    case .sentinelSent(let notification): "app sent sentinel .\(notification)"
    case .rulesChangedDelivered(let trigger): "os delivered handleRulesChanged (\(trigger.rawValue))"
    case .rulesChangedDropped(let trigger): "os dropped handleRulesChanged (\(trigger.rawValue))"
    case .log(let target, let message): "[\(target.rawValue)] \(message)"
    }
  }
}

@MainActor
public final class FilterProcess {
  private let dependencies: @Sendable (inout DependencyValues) -> Void
  private var proxy: FilterProxy

  /// Mirrors `filter/FilterDataProvider.swift`: the extension constructs its
  /// `FilterProxy` in `.emergencyLockdown` at process init.
  init(dependencies: @escaping @Sendable (inout DependencyValues) -> Void) {
    self.dependencies = dependencies
    self.proxy = withDependencies(dependencies) {
      FilterProxy(protectionMode: .emergencyLockdown)
    }
  }

  public var protectionMode: ProtectionMode {
    self.proxy.protectionMode
  }

  func osStartFilter() {
    withDependencies(self.dependencies) {
      self.proxy.startFilter()
    }
  }

  func decide(_ flow: FilterFlow) -> FlowVerdict {
    withDependencies(self.dependencies) {
      self.proxy.decideFilterFlow(flow)
    }
  }

  func osHandleRulesChanged() {
    withDependencies(self.dependencies) {
      self.proxy.handleRulesChanged()
    }
  }
}

@MainActor
public final class ControllerProcess {
  private let dependencies: @Sendable (inout DependencyValues) -> Void
  public let proxy: ControllerProxy
  public private(set) var startupTask: Task<Void, Never>?

  /// Mirrors `controller/FilterControlProvider.swift`: the extension constructs
  /// its `ControllerProxy` and wires `notifyRulesChanged` at process init.
  init(
    dependencies: @escaping @Sendable (inout DependencyValues) -> Void,
    notifyRulesChanged: @escaping @Sendable () -> Void,
  ) {
    self.dependencies = dependencies
    self.proxy = withDependencies(dependencies) {
      ControllerProxy()
    }
    self.proxy.notifyRulesChanged.setValue(notifyRulesChanged)
  }

  func osStartFilter() {
    self.startupTask = withDependencies(self.dependencies) {
      self.proxy.startFilter()
    }
  }

  func handleNewFlow(_ flow: FilterFlow) async -> NEFilterControlVerdict {
    await withDependencies(self.dependencies) {
      await self.proxy.handleFilterFlow(flow)
    }
  }

  func awaitMigration() async {
    #if DEBUG
      if let task = self.proxy.migrateTask.value {
        await task.value
      }
    #endif
  }

  func osKill() {
    self.startupTask?.cancel()
    #if DEBUG
      self.proxy.migrateTask.value?.cancel()
    #endif
  }
}

@MainActor
public final class AppProcess {
  public let store: TestStoreOf<IOSReducer>

  init(dependencies: @escaping @Sendable (inout DependencyValues) -> Void) {
    self.store = TestStore(
      initialState: IOSReducer.State(),
      reducer: { IOSReducer() },
      withDependencies: dependencies,
    )
    self.store.exhaustivity = .off
  }

  public var state: IOSReducer.State {
    self.store.state
  }

  public func tap(_ btn: IOSReducer.Action.Interactive.OnboardingBtn = .primary) async {
    await self.store.send(.interactive(.onboardingBtnTapped(btn, "sim")))
  }

  func osKill() async {
    await self.store.skipInFlightEffects()
  }
}
