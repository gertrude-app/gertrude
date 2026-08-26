import ClientInterfaces
import Combine
import ComposableArchitecture
import Core
import Dependencies
import Foundation
import Gertie
import MacAppRoute
import TestSupport
import XCore

@testable import App

/// One macapp process, backed by the real reducer under sim dependencies.
@MainActor final class MacAppProcess {
  let uid: uid_t
  let store: TestStoreOf<AppReducer>

  init(uid: uid_t, store: TestStoreOf<AppReducer>) {
    self.uid = uid
    self.store = store
  }

  var state: AppReducer.State { self.store.state }

  func skipReceivedActions() async {
    await self.store.skipReceivedActions(strict: false)
  }

  func osShutdown() async {
    await self.store.skipReceivedActions(strict: false)
    await self.store.skipInFlightEffects()
  }
}

// conductor: app lifecycle

extension VirtualMac {
  nonisolated static let appVersion = "2.5.0"

  /// Starts a macapp process and sends the launch action.
  @discardableResult
  func launchApp(
    uid: uid_t,
    checkInOutput: LockIsolated<CheckIn_v2.Output>,
  ) async -> MacAppProcess {
    let store = TestStore(
      initialState: AppReducer.State(appVersion: Self.appVersion),
      reducer: { AppReducer() },
      withDependencies: self.appDependencies(uid: uid, checkInOutput: checkInOutput),
    )
    store.useMainSerialExecutor = true
    store.exhaustivity = .off
    let process = MacAppProcess(uid: uid, store: store)
    self.apps[uid] = process
    self.log(.appLaunched(uid))
    await store.send(.application(.didFinishLaunching))
    await self.settle()
    return process
  }

  func quitApp(uid: uid_t) async {
    guard let process = self.apps[uid] else { return }
    await process.store.send(.application(.willTerminate))
    await process.osShutdown()
    self.apps[uid] = nil
    // OS RULE M5: app exit removes that user's XPC connection.
    self.xpcConnections.withValue { $0.disconnect(uid) }
    self.log(.appQuit(uid))
  }

  func seedAppDisk(uid: uid_t, user: UserData) throws {
    let state = Persistent.State(
      appVersion: Self.appVersion,
      appUpdateReleaseChannel: .stable,
      filterVersion: Self.filterVersion,
      user: user,
      resumeOnboarding: nil,
    )
    let json = try JSON.encode(state)
    self.userDisk(uid).withValue { $0[Persistent.State.storageKey] = .string(json) }
  }
}

// dependency wiring: app process context

extension VirtualMac {
  private func appDependencies(
    uid: uid_t,
    checkInOutput: LockIsolated<CheckIn_v2.Output>,
  ) -> @Sendable (inout DependencyValues) -> Void {
    let scheduler = self.scheduler
    let currentDate = self.currentDate
    let simDefaults = self.simUserDefaults(self.userDisk(uid))
    let xpcSubject = self.appXpcSubject(for: uid)
    let websocketSubject = self.websocketSubject(for: uid)
    let extensionState = self.extensionState
    let extensionStateChanges = self.extensionStateChanges
    let trace = self.trace
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let fixedCalendar = calendar

    let filterXpc = self.simFilterXPCClient(uid: uid, events: xpcSubject)
    let filterExtension = self.simFilterExtensionClient(
      state: extensionState,
      changes: extensionStateChanges,
    )

    return { deps in
      deps.date = DateGenerator { currentDate.value }
      deps.calendar = fixedCalendar
      deps.mainQueue = scheduler.eraseToAnyScheduler()
      deps.backgroundQueue = scheduler.eraseToAnyScheduler()
      deps.uuid = .incrementing
      deps.userDefaults = simDefaults
      deps.storage = .liveValue
      deps.network = .connected
      deps.monitoring = .mock
      deps.security = .mock
      deps.updater = .mock

      deps.app = .mock
      deps.app.installedVersion = { Self.appVersion }

      deps.api = .mock
      deps.api.checkIn = { _ in checkInOutput.value }
      deps.api.trustedNetworkTimestamp = { currentDate.value.timeIntervalSince1970 }
      deps.api.logSecurityEvent = { input, _ in
        trace.withValue { $0.append(.securityEvent(uid, input.event)) }
      }

      deps.device = .mock
      deps.device.currentUserId = { uid }
      deps.device.numericUserId = { uid }
      deps.device.boottime = { currentDate.value - 3600 }
      deps.device.screenTimeWebFilterActive = { false }
      deps.device.screensaverRunning = { false }
      deps.device.showNotification = { title, _ in
        trace.withValue { $0.append(.notification(uid, title: title)) }
      }
      deps.device.quitBrowsers = { _ in
        trace.withValue { $0.append(.browsersQuit(uid)) }
      }
      deps.device.quitNonSafariBrowsers = { _ in }
      deps.device.terminateBlockedApps = { _ in }

      deps.websocket = WebSocketClient(
        connect: { _ in .connected },
        disconnect: {},
        receive: { websocketSubject.eraseToAnyPublisher() },
        send: { message in
          trace.withValue { $0.append(.websocketSent(uid, "\(message)")) }
        },
        state: { .connected },
      )

      deps.filterExtension = filterExtension
      deps.filterXpc = filterXpc
    }
  }

  /// App-side XPC surface backed by the world's bus.
  /// sync:bc4068f6 app-to-filter xpc request surface
  private func simFilterXPCClient(
    uid: uid_t,
    events: PassthroughSubject<XPCEvent.App, Never>,
  ) -> FilterXPCClient {
    @Sendable func send(_ request: SimXPCRequest) async -> Result<Void, XPCErr> {
      do {
        _ = try await self.xpcSend(from: uid, request)
        return .success(())
      } catch {
        return .failure(.init(error))
      }
    }

    return FilterXPCClient(
      establishConnection: {
        await self.xpcEstablishConnection(from: uid)
      },
      checkConnectionHealth: {
        await MainActor.run {
          if self.filterProcess != nil,
             self.listenerUp.value,
             self.xpcConnections.value.has(uid) {
            .success(())
          } else {
            .failure(.noConnection)
          }
        }
      },
      disconnectUser: {
        await send(.disconnectUser(userId: uid))
      },
      endFilterSuspension: {
        await send(.endSuspension(userId: uid))
      },
      endDowntimePause: {
        await send(.endDowntimePause(userId: uid))
      },
      pauseDowntime: { expiration in
        await send(.pauseDowntime(
          userId: uid,
          untilSecondsSinceReference: expiration.timeIntervalSinceReferenceDate,
        ))
      },
      requestAck: {
        do {
          let reply = try await self.xpcSend(
            from: uid,
            .ackRequest(randomInt: 0, userId: uid),
          )
          guard let data = reply.data else { throw XPCErr.unexpectedMissingValueAndError }
          return try .success(XPC.decode(XPC.FilterAck.self, from: data))
        } catch {
          return .failure(.init(error))
        }
      },
      requestUserTypes: {
        do {
          let reply = try await self.xpcSend(from: uid, .listUserTypes)
          guard let data = reply.data else { throw XPCErr.unexpectedMissingValueAndError }
          return try .success(XPC.decode(FilterUserTypes.self, from: data))
        } catch {
          return .failure(.init(error))
        }
      },
      sendAlive: {
        do {
          let reply = try await self.xpcSend(from: uid, .alive(userId: uid))
          return .success(reply.bool ?? false)
        } catch {
          return .failure(.init(error))
        }
      },
      sendDeleteAllStoredState: {
        await send(.deleteAllStoredState)
      },
      sendURLMessage: { message in
        await self.deliverUrlMessage(message, from: uid)
      },
      sendUserRules: { manifest, keychains, downtime, filteringDisabled, alwaysBlocked in
        do {
          // sync:70544a7f user-rules payload encoding
          let manifestData = try XPC.encode(manifest)
          let filterData = try XPC.encode(UserFilterData(
            keychains: keychains,
            downtime: downtime,
            filteringDisabled: filteringDisabled,
            alwaysBlocked: alwaysBlocked,
          ))
          return await send(.userRules(
            userId: uid,
            manifestData: manifestData,
            filterData: filterData,
          ))
        } catch {
          return .failure(.init(error))
        }
      },
      setBlockStreaming: { enabled in
        await send(.setBlockStreaming(enabled, userId: uid))
      },
      setUserExemption: { userId, enabled in
        await send(.setUserExemption(userId: userId, enabled: enabled))
      },
      suspendFilter: { seconds in
        await send(.suspendFilter(userId: uid, durationInSeconds: seconds.rawValue))
      },
      events: { events.eraseToAnyPublisher() },
    )
  }

  /// App-side system-extension surface backed by world state.
  private func simFilterExtensionClient(
    state: LockIsolated<FilterExtensionState>,
    changes: PassthroughSubject<FilterExtensionState, Never>,
  ) -> FilterExtensionClient {
    FilterExtensionClient(
      setup: { state.value },
      start: { [weak self] in
        if state.value != .installedAndRunning {
          await self?.bootFilterExtension()
        }
        return state.value
      },
      stop: { [weak self] in
        await self?.stopFilterExtension()
        return state.value
      },
      reinstall: { [weak self] in
        await self?.stopFilterExtension()
        await self?.bootFilterExtension()
        return .installedSuccessfully
      },
      restart: { [weak self] in
        await self?.stopFilterExtension()
        await self?.bootFilterExtension()
        return state.value
      },
      replace: { [weak self] in
        await self?.stopFilterExtension()
        await self?.bootFilterExtension()
        return .installedSuccessfully
      },
      state: { state.value },
      install: { [weak self] in
        if state.value != .installedAndRunning {
          await self?.bootFilterExtension()
        }
        return .installedSuccessfully
      },
      installOverridingTimeout: { [weak self] _ in
        if state.value != .installedAndRunning {
          await self?.bootFilterExtension()
        }
        return .installedSuccessfully
      },
      stateChanges: { changes.eraseToAnyPublisher() },
      uninstall: { [weak self] in
        await self?.stopFilterExtension()
        state.setValue(.notInstalled)
        return true
      },
    )
  }
}
