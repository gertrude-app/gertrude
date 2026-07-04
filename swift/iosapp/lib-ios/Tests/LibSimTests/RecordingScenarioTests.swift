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
  await device.startBroadcast() // darwin event -> app writes expiration + suspend sentinel
  #expect(device.filter?.suspension != nil)
  #expect(app.state.destination == .requestSuspension(.recording))

  #expect(await device.browse("blocked.com") == .allow) // blocking lifted
  await device.record(seconds: 25)
  #expect(device.screenshotDisk.value.count > 0) // evidence accumulates on disk
  #expect(await device.browse("blocked.com") == .allow) // stays lifted while frames flow
  await device.quiesce() // browse summoned the controller, which drains evidence
  #expect(device.api.uploadedScreenshots.value.count > 0) // parent gets evidence LIVE

  await device.stopBroadcast() // darwin event -> app resumes filter + drains uploads
  #expect(device.screenshotDisk.value.isEmpty) // nothing left behind
  #expect(app.state.destination == nil)

  #expect(await device.browse("blocked.com") == .drop) // immediate, no liveness wait
  #expect(device.trace.value.contains(.log(.filter, "filter resumed: requested")))
  #expect(device.diskSuspensionExpiration == nil)
}

// MARK: - grant clock starts at broadcast start, not at parent approval

@Test @MainActor func expirationAnchoredAtBroadcastStartNotGrant() async throws {
  let device = connectedDevice(suspensionDecision: .accepted(duration: 300, parentComment: nil))
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
  #expect(app.state.destination == .requestSuspension(.granted(duration: 300, comment: nil)))
  #expect(device.diskSuspensionExpiration == nil) // grant alone writes nothing

  await device.advanceTime(minutes: 2) // kid dawdles before starting the recording
  await app.store.send(.destination(.presented(.requestSuspension(.startRecordingTapped))))
  await device.startBroadcast()

  // the full 5 minutes starts when recording starts
  #expect(device.diskSuspensionExpiration == device.currentDate.value + 300)
  #expect(await device.browse("blocked.com") == .allow)
}

// MARK: - darwin events die with the app: no live app, no suspension

@Test @MainActor func broadcastWhileAppDeadNeverSuspends() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce() // app never launched (or was killed after the grant)

  await device.startBroadcast() // kid starts a recording from control center
  await device.record(seconds: 10)

  #expect(device.trace.value.contains(.recorderEventDropped(.broadcastStarted)))
  #expect(device.filter?.suspension == nil) // nobody wrote the expiration
  #expect(await device.browse("blocked.com") == .drop)
}

// MARK: - fail-safe: blocking never stays lifted without screenshots flowing

@Test @MainActor func recorderKilledByOsTriggersLivenessFailSafe() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 300)

  device.api.config.withValue { $0.screenshotUploadsFailing = true } // strand evidence
  await device.startBroadcast()
  await device.deliverSentinel(.suspendFilter) // as the app does on broadcastStarted
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .allow)

  await device.kill(.recorder) // os enforces ~50MB memory limit; no darwin, no tombstone

  #expect(await device.browse("blocked.com") == .allow) // within liveness window
  await device.advanceTime(seconds: 7)
  #expect(await device.browse("blocked.com") == .drop) // fail-safe resumed blocking

  // leftover screenshots the dead recorder stranded get drained by the controller
  await device.quiesce()
  let leftovers = device.screenshotDisk.value.count
  #expect(leftovers > 0)
  device.api.config.withValue { $0.screenshotUploadsFailing = false }
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
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .allow)

  await device.kill(.filter) // os reclaims memory mid-recording

  // relaunched-on-demand filter rederives the suspension from disk state
  #expect(await device.browse("blocked.com") == .allow)
  #expect(device.trace.value.contains(.launchedOnDemand(.filter)))
  #expect(device.filter?.suspension != nil)

  await device.stopBroadcast() // graceful stop tombstones the liveness timestamp
  #expect(await device.browse("blocked.com") == .drop) // immediate, no 6s lapse needed
}

// MARK: - reboot mid-suspension

@Test @MainActor func rebootMidSuspensionRestoresBlockingBothOrders() async throws {
  for order in [[SimTarget.filter, .controller], [SimTarget.controller, .filter]] {
    let device = connectedDevice()
    await device.reboot()
    await device.quiesce()
    device.seedSuspensionExpiration(secondsFromNow: 900)

    await device.startBroadcast()
    await device.deliverSentinel(.suspendFilter)
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
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 30)
  #expect(await device.browse("blocked.com") == .allow)

  await device.record(seconds: 40) // recording continues past the granted minute
  #expect(await device.browse("blocked.com") == .drop) // but the grant is up

  await device.record(seconds: 20)
  #expect(await device.browse("blocked.com") == .drop) // more frames don't revive it
  #expect(device.screenshotDisk.value.count > 0) // evidence kept accumulating
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

  // darwin event delivered, but with no grant the app writes nothing
  #expect(device.trace.value.contains(.recorderEventDelivered(.broadcastStarted)))
  #expect(await device.browse("blocked.com") == .drop)
  #expect(device.filter?.suspension == nil)
}

// MARK: - static screen: liveness without redundant screenshots

@Test @MainActor func unchangedFramesMaintainLivenessWithoutUploads() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 300)

  await device.startBroadcast()
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 5) // one real frame
  #expect(device.screenshotDisk.value.count == 1)

  await device.record(seconds: 60, changed: false) // kid leaves screen static
  #expect(await device.browse("blocked.com") == .allow) // suspension persists
  await device.quiesce()

  // the one saved screenshot may have drained, but no duplicates were ever created
  let evidence = device.screenshotDisk.value.count + device.api.uploadedScreenshots.value.count
  #expect(evidence == 1)
}

// MARK: - upload failures retry on the next wake

@Test @MainActor func failedUploadsAreRetainedAndRetried() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()

  let app = await device.launchApp()
  await device.quiesce()

  await device.startBroadcast()
  await device.record(seconds: 20) // frames accumulate on disk

  device.api.config.withValue { $0.screenshotUploadsFailing = true }
  await device.stopBroadcast() // broadcastFinished drain fails
  #expect(device.api.uploadedScreenshots.value.isEmpty)
  let retained = device.screenshotDisk.value.count
  #expect(retained > 0) // retained on disk for retry

  device.api.config.withValue { $0.screenshotUploadsFailing = false }
  await app.store.send(.programmatic(.appDidEnterForeground)) // next wake point
  await device.quiesce()
  #expect(device.screenshotDisk.value.isEmpty)
  #expect(device.api.uploadedScreenshots.value.count == retained)
}

// MARK: - frame-delivery pause mid-recording: fail-safe blocks, recovery re-lifts (no app needed)

@Test @MainActor func framePauseGlitchReblocksThenRecoversWithoutApp() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 600)

  await device.startBroadcast()
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .allow)

  await device.pauseFrameDelivery(seconds: 15) // system pause: buffers stop, broadcast lives
  #expect(await device.browse("blocked.com") == .drop) // no live evidence, no free pass
  #expect(device.trace.value
    .contains(.log(.filter, "filter resumed: expired-or-recording-stopped")))

  await device.record(seconds: 5) // pause ends, frames flow again
  #expect(await device.browse("blocked.com") == .allow) // session recovered, not thrown away
  #expect(device.filter?.suspension != nil)

  await device.stopBroadcast()
  #expect(await device.browse("blocked.com") == .drop) // tombstone: immediate re-block
}

// MARK: - device lock finishes the broadcast; expiration lingers, restart re-lifts

@Test @MainActor func lockFinishesBroadcastReblocksAndRestartRelifts() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 600)

  await device.startBroadcast()
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .allow)

  await device.lockDevice() // side-button or auto-lock: iOS cleanly finishes the broadcast
  #expect(device.trace.value.contains(.broadcastFinished))
  #expect(!device.isRunning(.recorder))
  #expect(await device.browse("blocked.com") == .drop) // tombstone: immediate re-block

  await device.advanceTime(seconds: 30)
  await device.startBroadcast() // kid restarts recording from picker, no app involvement
  await device.record(seconds: 5)
  #expect(await device.browse("blocked.com") == .allow) // expiration lingers → D2 re-entry
}

// MARK: - suspended app misses the finish darwin event; coalesced delivery cleans up

@Test @MainActor func suspendedAppGetsCoalescedFinishOnResume() async throws {
  let device = connectedDevice(suspensionDecision: .accepted(duration: 600, parentComment: nil))
  await device.reboot()
  await device.quiesce()

  let app = await device.launchApp()
  await device.quiesce()
  await app.store.send(.interactive(.requestSuspensionBtnTapped))
  await app.store.send(.destination(.presented(
    .requestSuspension(.submitRequest(duration: 600, comment: nil)),
  )))
  await device.settle()
  await device.advanceTime(seconds: 5)
  await device.quiesce()
  await app.store.send(.destination(.presented(.requestSuspension(.startRecordingTapped))))
  await device.startBroadcast() // darwin start delivered while app still foreground
  #expect(device.diskSuspensionExpiration != nil)

  await app.store.send(.programmatic(.appDidEnterBackground))
  device.suspendApp() // seconds later, the os freezes the app
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .allow)

  await device.stopBroadcast() // finish darwin event HELD: app suspended, not dead
  #expect(await device.browse("blocked.com") == .drop) // tombstone re-blocks without the app
  #expect(device.diskSuspensionExpiration != nil) // app never heard; key lingers (by design)

  await device.resumeApp() // coalesced delivery: exactly one finish event
  await device.quiesce()
  #expect(device.trace.value.contains(.appResumed(coalescedEvents: [.broadcastFinished])))
  #expect(device.diskSuspensionExpiration == nil) // app cleaned up on resume
  #expect(device.api.uploadedScreenshots.value.count > 0)
  #expect(app.state.destination == nil)
}

// MARK: - evidence reaches the parent DURING the recording, no app process at all

@Test @MainActor func evidenceUploadsDuringRecordingWithoutApp() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 600)

  await device.startBroadcast()
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 15)

  var uploadsSeen: [Int] = []
  for _ in 0 ..< 3 {
    #expect(await device.browse("blocked.com") == .allow)
    await device.quiesce() // summoned controller drains
    uploadsSeen.append(device.api.uploadedScreenshots.value.count)
    await device.record(seconds: 10) // recording continues
  }
  #expect(device.recorder?.isBroadcasting == true) // still mid-session
  #expect(uploadsSeen.first! > 0) // parent saw evidence before the session ended
  #expect(uploadsSeen.last! > uploadsSeen.first!) // and it kept flowing
}

// MARK: - parent-configured screenshot cadence never loosens the safety math

@Test @MainActor func slowScreenshotCadenceKeepsFailSafeAndLivenessTight() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 600)

  await device.startBroadcast(screenshotInterval: 30) // parent wants sparse evidence
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 60)

  #expect(await device.browse("blocked.com") == .allow) // liveness solid between saves
  await device.quiesce()
  let evidence = device.screenshotDisk.value.count + device.api.uploadedScreenshots.value.count
  #expect(evidence >= 1 && evidence <= 3) // sparse saves, not one per heartbeat
  #expect(evidence < 60 / Int(RecordingSuspension.heartbeatInterval)) // cadences decoupled

  await device.kill(.recorder) // fail-safe latency must not scale with cadence
  await device.advanceTime(seconds: Int(RecordingSuspension.livenessWindow) + 1)
  #expect(await device.browse("blocked.com") == .drop)
}

// MARK: - a failing upload doesn't wedge the evidence backlog

@Test @MainActor func failedUploadSkipsAndBacklogDrainsNextWake() async throws {
  let device = connectedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 600)

  await device.startBroadcast()
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 20) // frames accumulate

  device.api.config.withValue { $0.screenshotUploadsFailing = true }
  #expect(await device.browse("blocked.com") == .allow) // summon: drain attempt fails
  await device.quiesce()
  #expect(device.api.uploadedScreenshots.value.isEmpty)
  let retained = device.screenshotDisk.value.count
  #expect(retained > 0) // nothing lost

  device.api.config.withValue { $0.screenshotUploadsFailing = false }
  await device.record(seconds: 10) // next summon window opens
  #expect(await device.browse("blocked.com") == .allow)
  await device.quiesce()
  #expect(device.screenshotDisk.value.isEmpty) // backlog cleared
  #expect(device.api.uploadedScreenshots.value.count >= retained)
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

  await app.store.send(.destination(.presented(.requestSuspension(.startRecordingTapped))))
  await device.startBroadcast()
  await device.record(seconds: 15)
  #expect(await device.browse("blocked.com") == .allow)

  await app.store.send(.destination(.presented(.requestSuspension(.endSuspensionTapped))))
  await device.quiesce() // resume sentinel + expiration cleared + uploads drained

  #expect(await device.browse("blocked.com") == .drop) // blocked though recording continues
  #expect(device.diskSuspensionExpiration == nil)
  #expect(device.api.uploadedScreenshots.value.count > 0)
  #expect(device.trace.value.contains(.log(.filter, "filter resumed: requested")))
}
