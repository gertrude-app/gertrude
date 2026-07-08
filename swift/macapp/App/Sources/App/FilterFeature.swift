import ClientInterfaces
import ComposableArchitecture
import Core
import Foundation
import Gertie
import os.log
import TaggedTime

struct FilterFeature: Feature {
  struct State: Equatable {
    var currentSuspensionExpiration: Date?
    var `extension`: FilterExtensionState
    var version: String
    var xpcFailureReported = false
    var udsShadowFailureReported = false
    var channelSamples = ChannelSamples()
    var lastShadowStatusReportAt: Date?
  }

  // both channels sampled together at the five-minute heartbeat; the
  // four buckets roll up into the daily `udsShadowStatus` telemetry event
  struct ChannelSamples: Equatable {
    var bothHealthy = 0
    var xpcOnlyHealthy = 0
    var udsOnlyHealthy = 0
    var neitherHealthy = 0

    mutating func record(xpcHealthy: Bool, udsHealthy: Bool) {
      switch (xpcHealthy, udsHealthy) {
      case (true, true): self.bothHealthy += 1
      case (true, false): self.xpcOnlyHealthy += 1
      case (false, true): self.udsOnlyHealthy += 1
      case (false, false): self.neitherHealthy += 1
      }
    }

    var detail: String {
      "samples: \(self.bothHealthy) both ok, \(self.xpcOnlyHealthy) xpc-only, "
        + "\(self.udsOnlyHealthy) uds-only, \(self.neitherHealthy) both dead"
    }
  }

  enum Action: Equatable, Sendable {
    case receivedState(FilterExtensionState)
    case receivedVersion(String)
    case channelHealthSampled(xpcHealthy: Bool, udsShadow: UDS.ShadowHealth)
  }

  struct Reducer: FeatureReducer {
    @Dependency(\.api) var api
    @Dependency(\.date.now) var now
    @Dependency(\.filterXpc) var xpc

    func reduce(into state: inout State, action: Action) -> Effect<Action> {
      switch action {
      case .receivedState(let newState):
        let oldState = state.extension
        state.extension = newState
        return .exec { _ in
          if oldState != newState, oldState != .unknown {
            let detail = "from \(oldState) to \(newState)"
            await api.securityEvent(.systemExtensionStateChanged, detail)
          }
        }

      case .receivedVersion(let version):
        state.version = version
        return .none

      // uds dark-ship telemetry: edge-triggered wedge events for both
      // channels, plus a per-launch + daily status rollup, so the fleet
      // yields both wedge-rates and a "shadow works at all" denominator
      case .channelHealthSampled(let xpcHealthy, let shadow):
        state.channelSamples.record(xpcHealthy: xpcHealthy, udsHealthy: shadow.healthy)
        var effects: [Effect<Action>] = []

        if !xpcHealthy, !state.xpcFailureReported {
          state.xpcFailureReported = true
          effects.append(.exec { _ in
            await self.api.logUds(
              "xpcHealthCheckFailed",
              "uds shadow \(shadow.healthy ? "ALIVE" : "dead"): \(shadow.detail)",
            )
          })
        } else if xpcHealthy, state.xpcFailureReported {
          state.xpcFailureReported = false
          effects.append(.exec { _ in
            await self.api.logUds(
              "xpcHealthCheckRecovered",
              "uds shadow \(shadow.healthy ? "alive" : "DEAD"): \(shadow.detail)",
            )
          })
        }

        if !shadow.healthy, !state.udsShadowFailureReported {
          state.udsShadowFailureReported = true
          effects.append(.exec { _ in
            await self.api.logUds(
              "udsHealthCheckFailed",
              "xpc \(xpcHealthy ? "alive" : "DEAD"): \(shadow.detail)",
            )
          })
        } else if shadow.healthy, state.udsShadowFailureReported {
          state.udsShadowFailureReported = false
          effects.append(.exec { _ in
            await self.api.logUds(
              "udsHealthCheckRecovered",
              "xpc \(xpcHealthy ? "alive" : "DEAD"): \(shadow.detail)",
            )
          })
        }

        let dueForStatusReport = state.lastShadowStatusReportAt
          .map { self.now.timeIntervalSince($0) >= 60 * 60 * 24 } ?? true
        if dueForStatusReport {
          state.lastShadowStatusReportAt = self.now
          let samples = state.channelSamples
          state.channelSamples = .init()
          effects.append(.exec { _ in
            let report = await self.xpc.takeUdsShadowStatusReport()
            await self.api.logUds("udsShadowStatus", "\(report.detail); \(samples.detail)")
          })
        }

        return effects.isEmpty ? .none : .merge(effects)
      }
    }
  }

  enum CancelId {
    case quitBrowsers
  }

  struct RootReducer: RootReducing {
    typealias Action = AppReducer.Action
    typealias State = AppReducer.State
    @Dependency(\.api) var api
    @Dependency(\.app) var app
    @Dependency(\.date.now) var now
    @Dependency(\.device) var device
    @Dependency(\.filterExtension) var filterExtension
    @Dependency(\.filterXpc) var xpc
    @Dependency(\.mainQueue) var mainQueue
    @Dependency(\.network) var network
    @Dependency(\.storage) var storage
    @Dependency(\.websocket) var websocket
  }
}

extension FilterFeature.State {
  init(appVersion: String?) {
    self.init(
      currentSuspensionExpiration: nil,
      extension: .unknown,
      version: appVersion ?? "unknown",
    )
  }
}

extension AppReducer.State {
  var filterState: FilterState.WithRelativeTimes {
    FilterState.WithRelativeTimes(from: self)
  }

  var isFilterSuspended: Bool {
    self.filterState.isSuspended
  }
}

extension FilterFeature.RootReducer {
  func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {

    case .appUpdates(.delegate(.updateSucceeded(_, let newVersion))):
      state.filter.version = newVersion
      return .none

    case .websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      _, .accepted(let seconds, let extraMonitoring), let comment,
    ))):
      return self.suspendFilter(
        for: seconds,
        with: &state,
        comment: comment,
        extraMonitoring: extraMonitoring != nil,
      )

    case .websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      _, .rejected, let comment,
    ))):
      return .exec { _ in
        await self.device.notifyFilterSuspensionDenied(with: comment)
      }

    case .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(let seconds)))):
      state.requestSuspension.windowOpen = false
      return self.suspendFilter(for: .init(seconds), with: &state, fromAdmin: true)

    // handle filter suspension decision checkIn, when websocket fails
    case .checkIn(result: .success(let output), reason: _):
      if let resolvedSuspension = output.resolvedFilterSuspension,
         resolvedSuspension.id == state.requestSuspension.pending?.id,
         !state.isFilterSuspended {
        interestingEvent(id: "f4f564a4", "fallback poll resolved filter suspension")
        state.requestSuspension.pending = nil
        switch resolvedSuspension.decision {
        case .accepted(let duration, let extraMonitoring):
          return self.suspendFilter(
            for: duration,
            with: &state,
            comment: resolvedSuspension.comment,
            extraMonitoring: extraMonitoring != nil,
          )
        case .rejected:
          return .exec { _ in
            await self.device.notifyFilterSuspensionDenied(with: resolvedSuspension.comment)
          }
        }
      }
      return .none

    case .heartbeat(.everyMinute):
      if let expiration = state.filter.currentSuspensionExpiration, expiration <= now {
        state.filter.currentSuspensionExpiration = nil
      }
      return .exec { _ in _ = await self.xpc.sendAlive() }

    case .heartbeat(.everyFiveMinutes):
      let appVersionString = state.appUpdates.installedVersion
      return .exec { [persist = state.persistent] send in
        let filter = await self.filterExtension.state()
        guard filter.isXpcReachable else { return }
        let xpcConnected = await self.xpc.connected()
        let shadowHealth = await self.xpc.checkUdsShadowHealth()
        await send(.filter(.channelHealthSampled(
          xpcHealthy: xpcConnected,
          udsShadow: shadowHealth,
        )))
        // attempt to reconnect, if necessary
        if !xpcConnected {
          _ = await self.xpc.establishConnection()
        } else if case .success(let acc) = await self.xpc.requestAck() {
          await send(.filter(.receivedVersion(acc.version)))

          // if the filter is ahead, another user must have updated Gertrude
          // so we need to relaunch to get on the same version w/ the filter
          if let filterVersion = Semver(acc.version),
             let appVersion = Semver(appVersionString),
             filterVersion > appVersion {
            os_log(
              "[G•] APP relaunch, filter ahead: `%{public}s` > `%{public}s`",
              acc.version, appVersionString,
            )
            try await self.storage.savePersistentState(persist)
            await self.app.stopRelaunchWatcher()
            try await self.app.relaunch()
          }
        }
      }

    case .menuBar(.resumeFilterClicked):
      state.menuBar.dropdownOpen = false
      state.filter.currentSuspensionExpiration = nil
      return self.handleFilterSuspensionEnded(browsers: state.browsers, early: true)

    case .xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(let userId)))
      where userId == device.currentUserId():
      state.filter.currentSuspensionExpiration = nil
      return self.handleFilterSuspensionEnded(browsers: state.browsers, early: false)

    case .xpc(.receivedExtensionMessage(.logs(let events))):
      return .exec { _ in await self.api.logFilterEvents(events) }

    case .adminWindow(.delegate(.healthCheckFilterExtensionState(let filterState))):
      state.filter.extension = filterState
      return .none

    case .adminAuthed(.adminWindow(.webview(.confirmStopFilterClicked))):
      // big sur (at least) doesn't get a notification pushed through the publisher for this event
      // so optimistically set the extension state, and then recheck after 2 seconds
      state.filter.extension = .installedButNotRunning
      return .exec { send in
        await api.securityEvent(.systemExtensionChangeRequested, "stop")
        _ = await self.filterExtension.stop()
        try await self.mainQueue.sleep(for: .seconds(2))
        await send(.filter(.receivedState(self.filterExtension.state())))
      }

    case .menuBar(.turnOnFilterClicked):
      let extensionInstalled = state.filter.extension.installed
      return .merge(
        .exec { send in
          if !extensionInstalled {
            await self.api.securityEvent(.systemExtensionChangeRequested, "install")
            let installResult = await self.filterExtension.install()
            switch installResult {
            case .installedSuccessfully:
              try await self.mainQueue.sleep(for: .milliseconds(10))
              _ = await self.xpc.establishConnection()
            case .timedOutWaiting:
              // event `9ffabfe5` logged w/ more detail in FilterFeature.swift
              await send(.focusedNotification(.filterInstallTimeout))
            case .userClickedDontAllow:
              interestingEvent(id: "01f94ff3")
              await send(.focusedNotification(.filterInstallDenied))
            case .activationRequestFailed,
                 .failedToGetBundleIdentifier,
                 .failedToLoadConfig,
                 .failedToSaveConfig,
                 .alreadyInstalled:
              unexpectedError(id: "8a8762e7", detail: "result: \(installResult)")
            }
          } else {
            await self.api.securityEvent(.systemExtensionChangeRequested, "start")
            let state = await self.filterExtension.start()
            switch state {
            case .installedAndRunning:
              break
            case .errorLoadingConfig,
                 .installedButNotRunning,
                 .notInstalled,
                 .unknown:
              unexpectedError(id: "cb2a0564", detail: "state: \(state)")
            }
          }
        },
        .exec { send in
          // especially for the case of an admin re-starting the stopped extension
          // on Big Sur, the extension state change doesn't get pushed through the publisher
          // so we also poll the state to make sure the admin/user is getting good feedback
          try await self.mainQueue.sleep(for: .milliseconds(200))
          await send(.filter(.receivedState(self.filterExtension.state())))
          for _ in 1 ... 10 {
            try await self.mainQueue.sleep(for: .seconds(1))
            let state = await self.filterExtension.state()
            await send(.filter(.receivedState(state)))
            if state == .installedAndRunning { return }
          }
          for _ in 1 ... 10 {
            try await self.mainQueue.sleep(for: .seconds(5))
            let state = await self.filterExtension.state()
            await send(.filter(.receivedState(state)))
            if state == .installedAndRunning { return }
          }
        },
      )

    default:
      return .none
    }
  }

  func suspendFilter(
    for seconds: Seconds<Int>,
    with state: inout State,
    fromAdmin: Bool = false,
    comment: String? = nil,
    extraMonitoring: Bool = false,
  ) -> Effect<Action> {
    let expiration = now.advanced(by: Double(seconds.rawValue))
    state.filter.currentSuspensionExpiration = expiration
    state.requestSuspension.pending = nil
    return .merge(
      .exec { _ in
        _ = await self.xpc.suspendFilter(seconds)
      },
      .exec { _ in
        await self.device.notifyFilterSuspension(
          resuming: seconds,
          from: now,
          with: comment,
          extraMonitoring: extraMonitoring,
        )
      },
      .exec { _ in
        await self.api.securityEvent(
          fromAdmin
            ? .filterSuspensionGrantedByAdmin
            : .filterSuspendedRemotely,
          "for \(self.now.shortDuration(until: expiration))",
        )
      },
      .cancel(id: FilterFeature.CancelId.quitBrowsers),
    )
  }

  func handleFilterSuspensionEnded(
    browsers: [BrowserMatch],
    early endedEarly: Bool = false,
  ) -> Effect<Action> {
    .exec { send in
      if endedEarly { _ = await self.xpc.endFilterSuspension() }
      await self.api
        .securityEvent(endedEarly ? .filterSuspensionEndedEarly : .filterSuspensionExpired)
      try? await self.websocket.send(.currentFilterState_v2(.on))
      await self.device.notifyBrowsersQuitting()
      try await self.mainQueue.sleep(for: .seconds(60))
      await self.device.quitBrowsers(browsers)
    }
    .cancellable(id: FilterFeature.CancelId.quitBrowsers, cancelInFlight: true)
  }
}

private extension AppReducer.Action.FocusedNotification {
  static var filterInstallTimeout: Self {
    .text(
      "Filter install never completed",
      "Try again, and be sure to allow Gertrude to install a system extension in \"System Settings > Privacy & Security\".",
    )
  }

  static var filterInstallDenied: Self {
    .text(
      "Filter install failed",
      "We couldn't install the filter, you may have refused permission. Please try again, clicking \"Allow\".",
    )
  }
}
