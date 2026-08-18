import ComposableArchitecture
import Core
import Gertie
import MacAppRoute
import TaggedTime
import TestSupport
import XCTest
import XExpect

@testable import App

final class FilterFeatureTests: XCTestCase {
  @MainActor
  func testResumeSuspension() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 90)
      $0.browsers = [.name("Arc")]
    }

    let filterNotify = mock(once: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.endFilterSuspension = filterNotify.fn
    let notification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = notification.fn
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn
    store.deps.storage.loadPersistentState = { .mock }

    await store.send(.menuBar(.resumeFilterClicked)) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(filterNotify.called).toEqual(true)
    await expect(notification.calls[0].a).toContain("browsers quitting soon")
    await expect(securityEvent.calls).toEqual([Both(.init(.filterSuspensionEndedEarly), nil)])

    await scheduler.advance(by: 59)
    await expect(quitBrowsers.called).toEqual(false)
    await scheduler.advance(by: 1)
    await expect(quitBrowsers.called).toEqual(true)
    await expect(quitBrowsers.calls).toEqual([[.name("Arc")]])
  }

  @MainActor
  func testSuspensionEndReportsResultingFilterState() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 60)
      $0.filter.extension = .installedAndRunning
      $0.user.data = .mock { $0.filteringDisabled = true }
    }
    let send = succeed(with: (), capturing: WebSocketMessage.FromAppToApi.self)
    store.deps.websocket.send = send.fn

    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(send.calls).toEqual([
      .currentFilterState_v2(.unfiltered),
    ])
  }

  @MainActor
  func testEveryMinuteSendsAliveMsgToFilter() async {
    let (store, _) = AppReducer.testStore()
    let alive = mock(once: Result<Bool, XPCErr>.success(true))
    store.deps.filterXpc.sendAlive = alive.fn
    await store.send(.heartbeat(.everyMinute))
    await expect(alive.called).toEqual(true)
  }

  @MainActor
  func testEveryMinuteReportsCurrentFilterStateWhenWebsocketConnected() async {
    let expiration = Date(timeIntervalSince1970: 60)
    let (store, _) = AppReducer.testStore {
      $0.user.data = .mock
      $0.filter.extension = .installedAndRunning
      $0.filter.currentSuspensionExpiration = expiration
    }
    let send = succeed(with: (), capturing: WebSocketMessage.FromAppToApi.self)
    store.deps.websocket.send = send.fn

    await store.send(.heartbeat(.everyMinute))

    await expect(send.calls).toEqual([
      .currentFilterState_v2(.suspended(resuming: expiration)),
    ])
  }

  @MainActor
  func testHeartbeatUpdatesFilterVersionIfPossible() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.installedVersion = "1.3.4"
      $0.filter.version = "1.3.3" // <-- out of date
    }

    let relaunch = mock(once: ())
    store.deps.app.relaunch = relaunch.fn
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }
    store.deps.filterXpc.requestAck = { .success(.init(
      randomInt: 333,
      version: "1.3.4", // <-- filter version from ack
      userId: 502,
      numUserKeys: 33,
    )) }

    await store.send(.heartbeat(.everyFiveMinutes))

    await store.receive(.filter(.receivedVersion("1.3.4"))) {
      $0.filter.version = "1.3.4"
    }

    // we're not behind, so we don't relaunch
    await expect(relaunch.called).toEqual(false)
  }

  @MainActor
  func testHeartbeatRelaunchesAppIfFilterAhead() async {
    let (store, _) = AppReducer.testStore {
      $0.appUpdates.installedVersion = "1.3.3" // <-- we're on "1.3.3"
      $0.filter.version = "1.3.3" // ... and we think the filter is too
    }

    store.deps.app = .testValue
    let stopWatcher = mock(once: ())
    store.deps.app.stopRelaunchWatcher = stopWatcher.fn
    let relaunch = mock(once: ())
    store.deps.app.relaunch = relaunch.fn
    let saveState = spy(on: Persistent.State.self, returning: ())
    store.deps.storage.savePersistentState = saveState.fn
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }
    store.deps.filterXpc.requestAck = { .success(.init(
      randomInt: 333,
      version: "1.3.4", // <-- but we get a new "ahead" filter version
      userId: 502,
      numUserKeys: 33,
    )) }

    await store.send(.heartbeat(.everyFiveMinutes))

    // so we 1) update the state
    await store.receive(.filter(.receivedVersion("1.3.4"))) {
      $0.filter.version = "1.3.4"
    }
    // 2) store persistent state
    await expect(saveState.calls.count).toEqual(1)
    // and 3) relaunch
    await expect(stopWatcher.called).toEqual(true)
    await expect(relaunch.called).toEqual(true)
  }

  @MainActor
  func testAdminSuspensionReportsEffectiveFilterState() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.extension = .installedButNotRunning
    }
    let send = succeed(with: (), capturing: WebSocketMessage.FromAppToApi.self)
    store.deps.websocket.send = send.fn

    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30)))),
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    await expect(send.calls).toEqual([
      .currentFilterState_v2(.off),
    ])
  }

  @MainActor
  func testManualAdminSuspensionLifecycle() async {
    let store = TestStore(initialState: AppReducer.State(appVersion: "1.0.0")) {
      AppReducer()
    }
    store.deps.websocket = .mock
    store.deps.device = .mock
    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    store.deps.storage.loadPersistentState = { .mock }
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let resumeFilter = mock(returning: [Result<Void, XPCErr>.success(())])
    store.deps.filterXpc.endFilterSuspension = resumeFilter.fn
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    expect(store.state.filter.currentSuspensionExpiration).toBeNil()
    await expect(suspendFilter.called).toEqual(false)

    // receive a manual suspension
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30)))),
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    await expect(suspendFilter.calls).toEqual([30])
    await expect(resumeFilter.called).toEqual(false)
    await expect(securityEvent.calls)
      .toEqual([Both(.init(.filterSuspensionGrantedByAdmin, "for < 1 min"), nil)])

    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await scheduler.advance(by: .seconds(59))
    await expect(showNotification.calls.count).toEqual(1)
    await expect(quitBrowsers.calls.count).toEqual(0)
    await expect(showNotification.calls[0].a).toContain("browsers quitting soon")

    // after 60 seconds pass, we quit the browsers
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.calls.count).toEqual(1)
  }

  @MainActor
  func testFilterSuspensionCanBeExtendedByReceivingAnother() async {
    let (store, scheduler) = AppReducer.testStore()
    let time = ControllingNow(starting: .epoch, with: scheduler)
    store.deps.date = time.generator
    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn

    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: "yup!",
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    await expect(suspendFilter.calls).toEqual([120])
    await time.advance(seconds: 100)

    // they get ANOTHER suspension before the first one has expired
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: "here's another one for ya!",
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 100 + 120)
    }

    await expect(suspendFilter.calls).toEqual([120, 120])

    // so far we've only showed them two "filter suspended", messages
    await expect(showNotification.calls.count).toEqual(2)

    await time.advance(seconds: 40) // now move past first suspension expiration

    // and we haven't told them that the browsers are quitting
    await expect(showNotification.calls.count).toEqual(2)
    await expect(quitBrowsers.calls.count).toEqual(0)
    expect(store.state.filter.currentSuspensionExpiration).not.toBeNil()

    // now move past second suspension
    await time.advance(seconds: 100)
    await expect(showNotification.calls.count).toEqual(2)
    await expect(quitBrowsers.calls.count).toEqual(0)

    // simulate filter notifying that the suspension is over
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(showNotification.calls.count).toEqual(3)
    await expect(showNotification.calls[2].a).toContain("browsers quitting soon")
    await expect(quitBrowsers.calls.count).toEqual(1)
  }

  @MainActor
  func testAcceptedWebsocketSuspensionReportsCurrentFilterStateImmediately() async {
    let expiration = Date(timeIntervalSince1970: 120)
    let (store, _) = AppReducer.testStore {
      $0.filter.extension = .installedAndRunning
    }
    let send = succeed(with: (), capturing: WebSocketMessage.FromAppToApi.self)
    store.deps.websocket.send = send.fn

    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: nil,
    )))) {
      $0.filter.currentSuspensionExpiration = expiration
    }

    await expect(send.calls).toEqual([
      .currentFilterState_v2(.suspended(resuming: expiration)),
    ])
  }

  @MainActor
  func testFallbackApprovalReportsCurrentFilterStateWhenWebsocketConnected() async {
    let expiration = Date(timeIntervalSince1970: 33)
    let output = CheckIn_v2.Output.mock {
      $0.resolvedFilterSuspension = .init(
        id: .deadbeef,
        decision: .accepted(duration: 33, extraMonitoring: nil),
        comment: nil,
      )
    }
    let (store, _) = AppReducer.testStore {
      $0.filter.extension = .installedAndRunning
      $0.requestSuspension.pending = .init(id: .deadbeef, createdAt: .epoch)
    }
    let send = succeed(with: (), capturing: WebSocketMessage.FromAppToApi.self)
    store.deps.websocket.send = send.fn

    await store.send(.checkIn(result: .success(output), reason: .pendingRequest)) {
      $0.filter.currentSuspensionExpiration = expiration
      $0.requestSuspension.pending = nil
    }

    await expect(send.calls).toEqual([
      .currentFilterState_v2(.suspended(resuming: expiration)),
    ])
  }

  @MainActor
  func testFilterSuspensionWebsocketLifecycle() async {
    let (store, _) = AppReducer.testStore()

    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let suspendFilter = spy(on: Seconds<Int>.self, returning: Result<Void, XPCErr>.success(()))
    store.deps.filterXpc.suspendFilter = suspendFilter.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn
    let resumeFilter = mock(returning: [Result<Void, XPCErr>.success(())])
    store.deps.filterXpc.endFilterSuspension = resumeFilter.fn

    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: "yup!",
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    await expect(suspendFilter.calls).toEqual([120])
    await expect(showNotification.calls.count).toEqual(1)
    await expect(showNotification.calls[0].a).toContain("disabling filter")
    await expect(showNotification.calls[0].b).toContain("yup!")
    await expect(showNotification.calls[0].b).toContain("2 minutes from now")

    await scheduler.advance(by: .seconds(120))
    await expect(showNotification.calls.count).toEqual(1)

    // simulate filter sending notice that suspension is ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(showNotification.calls.count).toEqual(2)
    await expect(showNotification.calls[1].a).toContain("browsers quitting soon")

    await scheduler.advance(by: .seconds(59))
    await expect(quitBrowsers.calls.count).toEqual(0)
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.calls.count).toEqual(1)

    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .rejected,
      comment: "nope!",
    ))))

    await expect(showNotification.calls.count).toEqual(3)
    await expect(showNotification.calls[2].a).toContain("request DENIED")
    await expect(showNotification.calls[2].b).toContain("nope!")
    await expect(suspendFilter.calls).toEqual([120]) // <-- no new suspension sent

    // another filter suspension comes in
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 90, extraMonitoring: nil),
      comment: "OK",
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 90)
    }

    await scheduler.advance(by: .seconds(30))
    await expect(resumeFilter.calls.count).toEqual(0)

    await store.send(.menuBar(.resumeFilterClicked)) {
      $0.filter.currentSuspensionExpiration = nil
    }
    await expect(resumeFilter.calls.count).toEqual(1)
    await expect(showNotification.calls.count).toEqual(5)
    await expect(showNotification.calls[4].a).toContain("browsers quitting soon")

    await scheduler.advance(by: .seconds(59))
    await expect(quitBrowsers.calls.count).toEqual(1)
    await scheduler.advance(by: .seconds(1))
    await expect(quitBrowsers.calls.count).toEqual(2)
  }

  @MainActor
  func testReceivingSuspensionDuring60SecondCountdownCancelsTimer() async {
    let (store, _) = AppReducer.testStore {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    store.deps.date = .constant(Date(timeIntervalSince1970: 0))
    let scheduler = DispatchQueue.test
    store.deps.mainQueue = scheduler.eraseToAnyScheduler()
    let showNotification = spy2(on: (String.self, String.self), returning: ())
    store.deps.device.showNotification = showNotification.fn
    let quitBrowsers = spy(on: [BrowserMatch].self, returning: ())
    store.deps.device.quitBrowsers = quitBrowsers.fn

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    await expect(showNotification.calls.count).toEqual(1)
    await expect(showNotification.calls[0].a).toContain("browsers quitting soon")

    // 30 seconds from notification re: quitting browsers, dad sends another suspension!
    await scheduler.advance(by: .seconds(30))
    await store.send(.websocket(.receivedMessage(.filterSuspensionRequestDecided_v2(
      id: .init(),
      decision: .accepted(duration: 120, extraMonitoring: nil),
      comment: nil,
    )))) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 120)
    }

    // user notified of suspension
    await expect(showNotification.calls.count).toEqual(2)
    await expect(showNotification.calls[1].a).toContain("disabling filter")

    await scheduler.advance(by: .seconds(31))
    await expect(quitBrowsers.calls.count).toEqual(0) // ...and browsers never quit!

    // now, receive a MANUAL suspension
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30)))),
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    // user notified of suspension
    await expect(showNotification.calls.count).toEqual(3)
    await expect(showNotification.calls[2].a).toContain("disabling filter")

    // pretend 30 seconds passed and the filter notifies of suspension ending
    await store.send(.xpc(.receivedExtensionMessage(.userFilterSuspensionEnded(502)))) {
      $0.filter.currentSuspensionExpiration = nil
    }

    // user notified again that browsers will quit
    await expect(showNotification.calls.count).toEqual(4)
    await expect(showNotification.calls[3].a).toContain("browsers quitting soon")
    await scheduler.advance(by: .seconds(30))

    // now, receive a SECOND MANUAL suspension, which stops timer
    await store.send(
      .adminAuthed(.requestSuspension(.webview(.grantSuspensionClicked(durationInSeconds: 30)))),
    ) {
      $0.filter.currentSuspensionExpiration = Date(timeIntervalSince1970: 30)
    }

    await scheduler.advance(by: .seconds(31))
    await expect(quitBrowsers.calls.count).toEqual(0) // browsers never quit
  }

  @MainActor
  func testReceivingFilterLogsSendsThemOnToApi() async {
    let (store, _) = AppReducer.testStore()
    let logFilterEvents = spy(on: LogFilterEvents.Input.self, returning: ())
    store.deps.api.logFilterEvents = logFilterEvents.fn

    let logs = FilterLogs(
      bundleIds: ["com.widget": 1],
      events: [.init(id: "foo", detail: nil): 1],
    )

    await store.send(.xpc(.receivedExtensionMessage(.logs(logs))))
    await expect(logFilterEvents.calls).toEqual([logs])
  }

  @MainActor
  func testXpcHealthCheckFailureReportsUdsShadowHealthOnceUntilRecovery() async {
    let (store, _) = AppReducer.testStore()
    store.deps.network.isConnected = { true }
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = { .failure(.timeout) } // <-- xpc wedged
    store.deps.filterXpc.establishConnection = { .failure(.timeout) } // ...and unrepairable
    let shadowHealth = UDS.ShadowHealth(healthy: true, detail: "round-trip ok, filter v1.2.3")
    store.deps.filterXpc.checkUdsShadowHealth = { shadowHealth }
    store.deps.filterXpc.takeUdsShadowStatusReport = { .init(
      connected: true,
      filterVersion: "1.2.3",
      requestsSucceeded: 5,
    ) }
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    // first sample: xpc failure edge reported + per-launch status rollup
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(
      xpcHealthy: false,
      udsShadow: shadowHealth,
    ))) {
      $0.filter.xpcFailureReported = true
      $0.filter.lastShadowStatusReportAt = Date(timeIntervalSince1970: 0)
      $0.filter.channelSamples = .init() // recorded, then reset by the rollup
    }
    await expect(securityEvent.calls).toEqual([
      Both(
        .init(
          deviceId: Persistent.State.mock.user!.deviceId,
          event: "xpcHealthCheckFailed",
          detail: "uds shadow ALIVE: round-trip ok, filter v1.2.3",
        ),
        nil,
      ),
      Both(
        .init(
          deviceId: Persistent.State.mock.user!.deviceId,
          event: "udsShadowStatus",
          detail: "connected, filter v1.2.3, requests 5 ok / 0 failed, reconnects 0;"
            + " samples: 0 both ok, 0 xpc-only, 1 uds-only, 0 both dead",
        ),
        nil,
      ),
    ])

    // still wedged 5 minutes later: sample counted, no duplicate report
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(
      xpcHealthy: false,
      udsShadow: shadowHealth,
    ))) {
      $0.filter.channelSamples.udsOnlyHealthy = 1
    }
    await expect(securityEvent.calls.count).toEqual(2)

    // xpc recovers: recovery reported, edge trigger reset
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(xpcHealthy: true, udsShadow: shadowHealth))) {
      $0.filter.xpcFailureReported = false
      $0.filter.channelSamples.bothHealthy = 1
    }
    await expect(securityEvent.calls.count).toEqual(3)
    await expect(securityEvent.calls[2].a.event).toEqual("xpcHealthCheckRecovered")
  }

  @MainActor
  func testUdsShadowDeathWhileXpcAliveReportedOnceUntilRecovery() async {
    let (store, _) = AppReducer.testStore()
    store.deps.network.isConnected = { true }
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = { .success(()) } // <-- xpc fine
    store.deps.filterXpc.requestAck = { .success(.init(
      randomInt: 1,
      version: "1.0.0",
      userId: 502,
      numUserKeys: 1,
    )) }
    let deadShadow = UDS.ShadowHealth(
      healthy: false,
      detail: "not connected, last round-trip: never",
    )
    store.deps.filterXpc.checkUdsShadowHealth = { deadShadow }
    store.deps.filterXpc.takeUdsShadowStatusReport = { .init(connected: false) }
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    // first sample: uds failure edge + per-launch status rollup
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(xpcHealthy: true, udsShadow: deadShadow))) {
      $0.filter.udsShadowFailureReported = true
      $0.filter.lastShadowStatusReportAt = Date(timeIntervalSince1970: 0)
    }
    await expect(securityEvent.calls[0].a.event).toEqual("udsHealthCheckFailed")
    await expect(securityEvent.calls[0].a.detail)
      .toEqual("xpc alive: not connected, last round-trip: never")
    await expect(securityEvent.calls[1].a.event).toEqual("udsShadowStatus")
    await expect(securityEvent.calls[1].a.detail)
      .toEqual("never connected, requests 0 ok / 0 failed, reconnects 0;"
        + " samples: 0 both ok, 1 xpc-only, 0 uds-only, 0 both dead")

    // still dead: no duplicate
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(xpcHealthy: true, udsShadow: deadShadow))) {
      $0.filter.channelSamples.xpcOnlyHealthy = 1
    }
    await expect(securityEvent.calls.count).toEqual(2)

    // shadow recovers
    let aliveShadow = UDS.ShadowHealth(healthy: true, detail: "round-trip ok, filter v1.0.0")
    store.deps.filterXpc.checkUdsShadowHealth = { aliveShadow }
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(xpcHealthy: true, udsShadow: aliveShadow))) {
      $0.filter.udsShadowFailureReported = false
      $0.filter.channelSamples.bothHealthy = 1
    }
    await expect(securityEvent.calls.count).toEqual(3)
    await expect(securityEvent.calls[2].a.event).toEqual("udsHealthCheckRecovered")
  }

  @MainActor
  func testShadowStatusRollupEmittedDaily() async {
    let (store, _) = AppReducer.testStore()
    store.deps.network.isConnected = { true }
    store.deps.filterExtension.state = { .installedAndRunning }
    store.deps.filterXpc.checkConnectionHealth = { .success(()) }
    store.deps.filterXpc.requestAck = { .success(.init(
      randomInt: 1,
      version: "1.0.0",
      userId: 502,
      numUserKeys: 1,
    )) }
    let shadowHealth = UDS.ShadowHealth(healthy: true, detail: "round-trip ok")
    store.deps.filterXpc.checkUdsShadowHealth = { shadowHealth }
    store.deps.filterXpc.takeUdsShadowStatusReport = { .init(connected: true) }
    let securityEvent = spy2(on: (LogSecurityEvent.Input.self, UUID?.self), returning: ())
    store.deps.api.logSecurityEvent = securityEvent.fn

    // launch rollup on first sample
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(xpcHealthy: true, udsShadow: shadowHealth)))
    await expect(securityEvent.calls.count).toEqual(1)
    await expect(securityEvent.calls[0].a.event).toEqual("udsShadowStatus")

    // 5 minutes later: sample counted, no rollup
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(xpcHealthy: true, udsShadow: shadowHealth))) {
      $0.filter.channelSamples.bothHealthy = 1
    }
    await expect(securityEvent.calls.count).toEqual(1)

    // 24 hours later: next rollup, with accumulated samples, counters reset
    store.deps.date = .constant(Date(timeIntervalSince1970: 60 * 60 * 24))
    await store.send(.heartbeat(.everyFiveMinutes))
    await store.receive(.filter(.channelHealthSampled(xpcHealthy: true, udsShadow: shadowHealth))) {
      $0.filter.channelSamples = .init()
      $0.filter.lastShadowStatusReportAt = Date(timeIntervalSince1970: 60 * 60 * 24)
    }
    await expect(securityEvent.calls.count).toEqual(2)
    await expect(securityEvent.calls[1].a.detail)
      .toEqual("connected, requests 0 ok / 0 failed, reconnects 0;"
        + " samples: 2 both ok, 0 xpc-only, 0 uds-only, 0 both dead")
  }
}

extension LogSecurityEvent.Input {
  init(_ event: SecurityEvent.MacApp, _ detail: String? = nil) {
    self.init(
      deviceId: Persistent.State.mock.user!.deviceId,
      event: event.rawValue,
      detail: detail,
    )
  }
}
