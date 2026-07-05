import GertieBlocker
import IOSRoute
import LibApp
import LibClients
import LibCore
import LibSim
import Testing
import XExpect

private let youtube = "com.google.ios.youtube"

@MainActor
private func shieldedDevice(
  allowlist: [String] = [.gertrudeBundleIdShort],
  suspensionDecision: PollFilterSuspensionDecision.Output = .pending,
  grantPolicy: RecordingSuspension.GrantPolicy = .burnOnFinish,
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
  let device = VirtualDevice(
    disk: SimDisk.current(
      protectionMode: .connected([.targetContains(value: "blocked.com")], nil),
      connection: connection,
      disabledBlockGroupIds: [],
    ),
    api: api,
    filterInstalled: true,
    grantPolicy: grantPolicy,
  )
  device.seedShieldAllowlist(allowlist)
  return device
}

// MARK: - steady state: shields up for everyone but the allowlist (S3, R14, R15)

@Test @MainActor func steadyStateShieldsRiseAtControllerStartup() async throws {
  let device = shieldedDevice()
  await device.reboot()
  await device.quiesce()

  #expect(device.shields.value.raised) // controller startup reconcile (D8)
  #expect(device.appIsShielded(youtube))
  #expect(!device.appIsShielded(.gertrudeBundleIdShort)) // allowlisted
  #expect(!device.appIsShielded("com.apple.mobilesafari")) // system-exempt (R14)

  #expect(await device.browse("safe.com", from: youtube) == nil) // R15: no user flows
  #expect(await device.backgroundRefreshFlow(to: "safe.com", from: youtube) == .allow)
  #expect(await device.browse("safe.com") == .allow) // safari unaffected
}

// MARK: - the app entry edge is load-bearing; reconcile must survive the second writer

// (found by the shields corpus on its FIRST run, seed 6, shrunk to 3 actions: the
// controller cached its own last shield write, the app's entry-edge drop made that
// cache stale, and the post-suspension raising write was skipped — S3 violated. The
// reconciler now writes the projection unconditionally.)

@Test @MainActor func appEntryEdgeDoesNotStaleControllerReconcile() async throws {
  let device = shieldedDevice()
  await device.reboot()
  await device.quiesce()
  #expect(device.shields.value.raised)

  device.seedSuspensionExpiration(secondsFromNow: 300)
  await device.startBroadcast()
  device.appDropsShieldsEntryEdge() // as the app does on broadcastStarted
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 5)
  #expect(!device.shields.value.raised)

  await device.advanceTime(seconds: 240) // frames stop: liveness starves (system pause)
  await device.deliverSentinel(.refreshRules) // any controller flow = reconcile opportunity
  await device.quiesce()
  #expect(device.shields.value.raised) // no write cache: the raise happens
}

// MARK: - shield state survives writer death and reboot (R14); startup reconcile heals

@Test @MainActor func rebootMidSuspensionRaisesShieldsViaStartupReconcile() async throws {
  for order in [[SimTarget.filter, .controller], [SimTarget.controller, .filter]] {
    let device = shieldedDevice()
    await device.reboot()
    await device.quiesce()
    device.seedSuspensionExpiration(secondsFromNow: 900)
    await device.startBroadcast()
    device.appDropsShieldsEntryEdge()
    await device.deliverSentinel(.suspendFilter)
    await device.record(seconds: 10)
    #expect(!device.shields.value.raised)

    await device.kill(.controller)
    await device.kill(.filter)
    #expect(!device.shields.value.raised) // R14: dropped state outlives both writers

    await device.advanceTime(seconds: 7) // sim reboots are instant; real boots outlast liveness
    await device.reboot(order: order) // broadcast dies; dropped shields PERSIST the reboot
    await device.quiesce()
    #expect(device.shields.value.raised) // startup reconcile raised them, before ANY traffic
    #expect(await device.browse("blocked.com") == .drop)
  }
}

// MARK: - allowlist edits apply on the next reconcile, no special casing

@Test @MainActor func allowlistEditAppliesOnNextReconcile() async throws {
  let device = shieldedDevice()
  await device.reboot()
  await device.quiesce()
  #expect(device.appIsShielded(youtube))

  device.seedShieldAllowlist([.gertrudeBundleIdShort, youtube]) // parent adds youtube
  #expect(device.appIsShielded(youtube)) // stale until a reconcile opportunity

  await device.deliverSentinel(.refreshRules)
  await device.quiesce()
  #expect(!device.appIsShielded(youtube))
  #expect(device.shields.value.raised) // still up for everyone else
}

// MARK: - S1′: the R13 leaked socket goes unusable behind the shield

@Test @MainActor func leakedSocketUnusableOnceShieldsRise() async throws {
  let device = shieldedDevice()
  await device.reboot()
  await device.quiesce()
  device.seedSuspensionExpiration(secondsFromNow: 600)
  await device.startBroadcast()
  device.appDropsShieldsEntryEdge()
  await device.deliverSentinel(.suspendFilter)
  await device.record(seconds: 10)

  let leaked = await device.openConnection(to: "blocked.com", from: youtube)! // during grant
  #expect(device.connectionCarriesData(leaked))

  await device.stopBroadcast() // tombstone: suspension over, socket lives on (R13)
  #expect(await device.browse("blocked.com") == .drop) // new flows blocked (S1)
  #expect(device.connectionCarriesData(leaked)) // the leak, until a reconcile opportunity

  await device.deliverSentinel(.refreshRules)
  await device.quiesce()
  #expect(device.shields.value.raised)
  #expect(!device.connectionCarriesData(leaked)) // S1′: usable data path gone
}

// MARK: - the managing app is exempt from its own shields (R14 owner exemption)

// (device-verified 2026-07-05: with shields-all up, Gertrude stayed launchable and
// usable WITHOUT being in the exception set, from both writer contexts. Had this
// gone the other way the feature would entry-deadlock — a shielded Gertrude can't
// be opened to request a suspension and its sentinels are R15-suppressed.)

@Test @MainActor func gertrudeIsExemptFromItsOwnShields() async throws {
  let device = shieldedDevice(allowlist: ["com.example.someapp"]) // gertrude NOT picked
  await device.reboot()
  await device.quiesce()
  #expect(device.shields.value.raised)

  #expect(!device.appIsShielded(.gertrudeBundleIdShort)) // owner exemption, not allowlist
  await device.deliverSentinel(.refreshRules) // its sentinels flow: entry path intact
  await device.quiesce()
  let suppressed = device.trace.value.contains {
    if case .flowSuppressedByShield(bundleId: .gertrudeBundleIdShort, target: _) = $0 {
      return true
    }
    return false
  }
  #expect(!suppressed)
}

// MARK: - grant policy A: burn-on-finish (shipped) — a lock consumes the grant

@Test @MainActor func lockBurnsGrantUnderBurnOnFinishPolicy() async throws {
  let device = shieldedDevice(
    suspensionDecision: .accepted(duration: 600, parentComment: nil),
    grantPolicy: .burnOnFinish,
  )
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
  await device.startBroadcast() // darwin → app: expiration + shield entry edge + sentinel
  #expect(!device.shields.value.raised) // real reducer edge, not the sim helper
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com", from: youtube) == .allow) // kid can use the app

  await device.lockDevice() // iOS cleanly finishes the broadcast; app suspends with it
  await device.resumeApp() // coalesced finish: app burns the grant + raises shields
  await device.quiesce()
  #expect(device.diskSuspensionExpiration == nil) // grant consumed
  #expect(device.shields.value.raised)

  await device.startBroadcast() // kid restarts from the picker anyway
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com") == .drop) // no grant, no lift
}

// MARK: - grant policy B: restart-within-grant — a lock pauses, the window stands

@Test @MainActor func lockPreservesGrantUnderRestartWithinGrantPolicy() async throws {
  let device = shieldedDevice(
    suspensionDecision: .accepted(duration: 600, parentComment: nil),
    grantPolicy: .restartWithinGrant,
  )
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
  await device.startBroadcast()
  let window = device.diskSuspensionExpiration
  #expect(window != nil)
  await device.record(seconds: 10)
  #expect(await device.browse("blocked.com", from: youtube) == .allow)

  await device.lockDevice()
  await device.resumeApp() // finish heard, but the window is still open: register kept
  await device.quiesce()
  #expect(device.diskSuspensionExpiration == window) // grant preserved, NOT extended
  #expect(device.shields.value.raised) // not recording right now → shields up
  #expect(await device.browse("blocked.com") == .drop) // and blocking is back on

  await device.startBroadcast() // kid restarts within the window
  await device.record(seconds: 10)
  #expect(device.diskSuspensionExpiration == window) // same window, no re-grant
  #expect(!device.shields.value.raised) // app entry edge fired again
  #expect(await device.browse("blocked.com", from: youtube) == .allow) // re-lifted

  await device.record(seconds: 600) // recording continues past the granted window
  #expect(await device.browse("blocked.com") == .drop) // register-authoritative (D7)
}
