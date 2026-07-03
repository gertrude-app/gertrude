import ComposableArchitecture
import Dependencies
import Foundation
import LibApp
import LibClients
import LibController
import LibCore
import LibFilter
import LibRecorder

public enum SimTarget: String, Sendable, Equatable {
  case app
  case controller
  case filter
  case recorder
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
  case broadcastStarted
  case broadcastFinished
  case broadcastErrored(String)
  case recorderEventDelivered(RecorderEvent)
  case recorderEventDropped(RecorderEvent)
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
    case .broadcastStarted: "user started broadcast"
    case .broadcastFinished: "user stopped broadcast"
    case .broadcastErrored(let error): "broadcast finished with error: \(error)"
    case .recorderEventDelivered(let event): "darwin event .\(event) delivered to app"
    case .recorderEventDropped(let event): "darwin event .\(event) dropped, no app running"
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

  public var suspension: RecordingSuspension? {
    self.proxy.suspension
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
public final class RecorderProcess {
  final class Finisher: FinishableBroadcast, Sendable {
    let errors = LockIsolated<[String]>([])
    func finishWithError(_ error: any Error) {
      self.errors.withValue { $0.append(error.localizedDescription) }
    }
  }

  private let dependencies: @Sendable (inout DependencyValues) -> Void
  private var proxy: SampleHandlerProxy
  let finisher = Finisher()
  private var frameCount = 0
  public private(set) var isBroadcasting = false

  /// Mirrors `recorder/SampleHandler.swift`: the extension constructs its
  /// `SampleHandlerProxy` at process init, wired to itself as finisher.
  init(dependencies: @escaping @Sendable (inout DependencyValues) -> Void) {
    self.dependencies = dependencies
    let finisher = self.finisher
    self.proxy = withDependencies(dependencies) {
      SampleHandlerProxy(finisher: finisher)
    }
  }

  var broadcastErrors: [String] {
    self.finisher.errors.value
  }

  func osBroadcastStarted() {
    self.isBroadcasting = true
    withDependencies(self.dependencies) {
      self.proxy.broadcastStarted()
    }
  }

  func osDeliverSample(changed: Bool) {
    self.frameCount += 1
    let frame = Frame(
      jpeg: Data("frame-\(self.frameCount)".utf8),
      width: 585,
      height: 1266,
      unchanged: !changed,
    )
    withDependencies(self.dependencies) {
      if self.proxy.shouldProcessBuffer() {
        self.proxy.processFrame(frame)
      }
    }
  }

  func osBroadcastFinished() {
    self.isBroadcasting = false
    withDependencies(self.dependencies) {
      self.proxy.broadcastFinished()
    }
  }

  func osKill() {
    self.isBroadcasting = false
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
