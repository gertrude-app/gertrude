import GertieBlocker
import IOSRoute
import LibApp
import LibClients
import LibCore
import LibSim
import Testing
import XExpect

@MainActor
private func connectedDevice(
  suspensionDecision: PollFilterSuspensionDecision.Output = .pending,
) -> VirtualDevice {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "blocked.com")]
  api.connected = .init(blockRules: [.targetContains(value: "blocked.com")], webPolicy: nil)
  api.suspensionDecision = suspensionDecision
  let connection = ChildIOSDeviceData_v2(
    childId: UUID(2),
    token: UUID(3),
    deviceId: UUID(4),
    childName: "Little Jimmy",
    supervised: nil,
  )
  return VirtualDevice(
    disk: SimDisk.current(
      protectionMode: .connected([.targetContains(value: "blocked.com")], nil),
      connection: connection,
      disabledBlockGroupIds: [],
    ),
    api: api,
    filterInstalled: true,
  )
}

// MARK: - the whole feature, end to end

@Test @MainActor func grantedSuspensionWithRecordingLiftsBlocking() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()

  let app = await device.launchApp()
  await device.quiesce()
  #expect(app.state.screen == .running(state: .connected))
  #expect(await device.browse("blocked.com") == .drop) // protected before suspension

  await app.store.send(.interactive(.requestSuspensionBtnTapped))
  await app.store.send(.destination(.presented(
    .requestSuspension(.submitRequest(duration: 300, comment: "school project")),
  )))
  await device.settle()
  await device.advanceTime(seconds: 5) // first poll tick, still pending
  await device.settle()
  #expect(device.api.suspensionRequests.value == [.init(duration: 300, comment: "school project")])

  device.api.config.withValue {
    $0.suspensionDecision = .accepted(duration: 300, parentComment: nil)
  }
  await device.advanceTime(seconds: 5) // next poll tick sees the grant
  await device.quiesce()
  #expect(app.state.destination == .requestSuspension(.granted(duration: 300, comment: nil)))

  await app.store.send(.destination(.presented(.requestSuspension(.startRecordingTapped))))
  await device.startBroadcast() // suspend sentinel flows to filter
  #expect(device.filter?.suspension != nil)

  #expect(await device.browse("blocked.com") == .allow) // blocking lifted
  await device.record(seconds: 25)
  #expect(await device.browse("blocked.com") == .allow) // stays lifted while frames flow
  #expect(device.api.uploadedScreenshots.value.count > 0) // parent got evidence

  await device.stopBroadcast() // user ends recording, final upload drains
  #expect(device.screenshotDisk.value.isEmpty)

  await device.advanceTime(seconds: 7) // liveness window lapses
  #expect(await device.browse("blocked.com") == .drop) // protection restored
  #expect(device.trace.value.contains(.log(
    .filter,
    "filter resumed: expired-or-recording-stopped",
  )))
}

// MARK: - fail-safe: blocking never stays lifted without screenshots flowing

@Test @MainActor func recorderKilledByOsTriggersLivenessFailSafe() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 300)

  await device.startBroadcast()
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .allow)

  await device.kill(.recorder) // os enforces ~50MB memory limit, no final upload

  #expect(await device.browse("blocked.com") == .allow) // within liveness window
  await device.advanceTime(seconds: 7)
  #expect(await device.browse("blocked.com") == .drop) // fail-safe resumed blocking

  // leftover screenshots the dead recorder never uploaded get drained by controller
  let leftovers = device.screenshotDisk.value.count
  #expect(leftovers > 0)
  await device.deliverSentinel(.refreshRules) // next rule refresh drains them
  await device.quiesce()
  #expect(device.screenshotDisk.value.isEmpty)
  #expect(device.api.uploadedScreenshots.value.count >= leftovers)
}

@Test @MainActor func sneakySavedExpirationAloneDoesNotSuspend() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()

  // expiration key present (e.g. planted, or left over from legit grant), no recording
  device.seedSuspensionExpiration(secondsFromNow: 300)

  await device.deliverSentinel(.suspendFilter) // even a spoofed sentinel from the app
  let entered = await device.browse("blocked.com")
  #expect(entered == .allow) // grace window admits the suspension briefly...

  await device.advanceTime(seconds: 7) // ...but no screenshots ever arrive
  #expect(await device.browse("blocked.com") == .drop)
}

// MARK: - filter process death mid-suspension

@Test @MainActor func filterKilledMidSuspensionRederivesSuspensionFromDisk() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 300)

  await device.startBroadcast()
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .allow)

  await device.kill(.filter) // os reclaims memory mid-recording

  // relaunched-on-demand filter rederives the suspension from disk state
  #expect(await device.browse("blocked.com") == .allow)
  #expect(device.trace.value.contains(.launchedOnDemand(.filter)))
  #expect(device.filter?.suspension != nil)

  await device.stopBroadcast()
  await device.advanceTime(seconds: 7)
  #expect(await device.browse("blocked.com") == .drop)
}

// MARK: - reboot mid-suspension

@Test @MainActor func rebootMidSuspensionRestoresBlockingBothOrders() async throws {
  for order in [[SimTarget.filter, .controller], [SimTarget.controller, .filter]] {
    let device = connectedDevice()
    await device.reboot()
    await device.quiesce()
    device.seedSuspensionExpiration(secondsFromNow: 900)

    await device.startBroadcast()
    await device.record(seconds: 10)
    #expect(await device.browse("blocked.com") == .allow)

    await device.reboot(order: order) // broadcast dies with the reboot
    await device.quiesce()
    await device.advanceTime(seconds: 7)

    // expiration key still future on disk, but no live recording: protected
    #expect(await device.browse("blocked.com") == .drop)
  }
}

// MARK: - suspension expiration wins over live recording

@Test @MainActor func expirationEndsSuspensionEvenWhileStillRecording() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 60)

  await device.startBroadcast()
  await device.record(seconds: 30)
  #expect(await device.browse("blocked.com") == .allow)

  await device.record(seconds: 40) // recording continues past the granted minute
  #expect(await device.browse("blocked.com") == .drop) // but the grant is up

  await device.record(seconds: 20)
  #expect(await device.browse("blocked.com") == .drop) // more frames don't revive it
  #expect(device.api.uploadedScreenshots.value.count > 0) // evidence kept flowing
}

// MARK: - no grant, no suspension

@Test @MainActor func deniedRequestThenBroadcastDoesNotSuspend() async throws {
  let device = connectedDevice(suspensionDecision: .denied(parentComment: "no way"))
  await device.reboot()
  await device.quiesce()

  let app = await device.launchApp()
  await device.quiesce()
  await app.store.send(.interactive(.requestSuspensionBtnTapped))
  await app.store.send(.destination(.presented(
    .requestSuspension(.submitRequest(duration: 300, comment: nil)),
  )))
  await device.settle()
  await device.advanceTime(seconds: 5)
  await device.quiesce()
  #expect(app.state.destination == .requestSuspension(.denied(comment: "no way")))

  await device.startBroadcast() // kid starts a recording anyway
  await device.record(seconds: 10)

  #expect(await device.browse("blocked.com") == .drop) // no expiration key, no suspension
  #expect(device.filter?.suspension == nil)
}

// MARK: - static screen: liveness without redundant uploads

@Test @MainActor func unchangedFramesMaintainLivenessWithoutUploads() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 300)

  await device.startBroadcast()
  await device.record(seconds: 5) // one real frame
  let uploadedAfterFirst = device.api.uploadedScreenshots.value.count
    + device.screenshotDisk.value.count
  #expect(uploadedAfterFirst == 1)

  await device.record(seconds: 60, changed: false) // kid leaves screen static
  #expect(await device.browse("blocked.com") == .allow) // suspension persists

  let totalSaved = device.api.uploadedScreenshots.value.count
    + device.screenshotDisk.value.count
  #expect(totalSaved == 1) // no duplicate screenshots saved or uploaded
}

// MARK: - upload failures retry until network recovers

@Test @MainActor func failedUploadsAreRetainedAndRetried() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 600)
  device.api.config.withValue { $0.screenshotUploadsFailing = true }

  await device.startBroadcast()
  await device.record(seconds: 45) // two upload cycles fail
  #expect(device.api.uploadedScreenshots.value.isEmpty)
  #expect(device.screenshotDisk.value.count > 0) // retained on disk for retry

  device.api.config.withValue { $0.screenshotUploadsFailing = false }
  await device.record(seconds: 20) // next cycle uploads the backlog
  #expect(device.api.uploadedScreenshots.value.count >= 3)

  await device.stopBroadcast() // final drain gets the tail frames
  #expect(device.screenshotDisk.value.isEmpty)
}

// MARK: - parent never answers

@Test @MainActor func unansweredRequestExpiresAfterFiveMinutes() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()

  let app = await device.launchApp()
  await device.quiesce()
  await app.store.send(.interactive(.requestSuspensionBtnTapped))
  await app.store.send(.destination(.presented(
    .requestSuspension(.submitRequest(duration: 300, comment: nil)),
  )))
  await device.settle()

  await device.advanceTime(minutes: 6) // parent never responds
  await device.quiesce()

  #expect(app.state.destination == .requestSuspension(.requestExpired))
  #expect(device.diskSuspensionExpiration == nil) // nothing written
  #expect(await device.browse("blocked.com") == .drop)
}

// MARK: - kid ends suspension early from the app

@Test @MainActor func earlyResumeFromAppRestoresBlockingImmediately() async throws {
  let device = connectedDevice(suspensionDecision: .accepted(duration: 900, parentComment: nil))
  await device.reboot()
  await device.quiesce()

  let app = await device.launchApp()
  await device.quiesce()
  await app.store.send(.interactive(.requestSuspensionBtnTapped))
  await app.store.send(.destination(.presented(
    .requestSuspension(.submitRequest(duration: 900, comment: nil)),
  )))
  await device.settle()
  await device.advanceTime(seconds: 5)
  await device.quiesce()
  #expect(app.state.destination == .requestSuspension(.granted(duration: 900, comment: nil)))
  #expect(device.diskSuspensionExpiration != nil) // grant recorded to disk

  await app.store.send(.destination(.presented(.requestSuspension(.startRecordingTapped))))
  await device.startBroadcast()
  await device.record(seconds: 15)
  #expect(await device.browse("blocked.com") == .allow)

  await app.store.send(.destination(.presented(.requestSuspension(.endSuspensionTapped))))
  await device.quiesce() // resume sentinel + expiration cleared

  #expect(await device.browse("blocked.com") == .drop) // blocked though recording continues
  #expect(device.diskSuspensionExpiration == nil)
  #expect(device.trace.value.contains(.log(.filter, "filter resumed: requested")))
}
