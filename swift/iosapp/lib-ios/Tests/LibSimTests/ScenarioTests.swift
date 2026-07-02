import GertieBlocker
import LibApp
import LibClients
import LibCore
import LibSim
import Testing
import XExpect

// MARK: - boot order after device reboot

@Test @MainActor func rebootFilterFirstServesStoredRulesBeforeControllerWakes() async throws {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "bad.com")]
  let device = VirtualDevice(
    disk: SimDisk.current(
      protectionMode: .normal([.targetContains(value: "bad.com")]),
      disabledBlockGroupIds: [],
    ),
    api: api,
    filterInstalled: true,
  )

  device.launchFilter() // filter wins the post-reboot race
  let earlyBad = await device.browse("bad.com")
  let earlyOk = await device.browse("ok.com")
  #expect(earlyBad == .drop) // protected from stored rules before controller wakes
  #expect(earlyOk == .allow)

  await device.launchController()
  await device.quiesce()

  let lateBad = await device.browse("bad.com")
  #expect(lateBad == .drop)
  #expect(device.filter?.protectionMode == .normal([.targetContains(value: "bad.com")]))
}

@Test @MainActor func rebootControllerFirstDropsNotificationButFilterRecovers() async throws {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "new-bad.com")]
  let device = VirtualDevice(
    disk: SimDisk.current(
      protectionMode: .normal([.targetContains(value: "stale-bad.com")]),
      disabledBlockGroupIds: [],
    ),
    api: api,
    filterInstalled: true,
  )

  await device.launchController() // controller wins the post-reboot race
  await device.quiesce()

  // fresh rules hit the disk, but the filter wasn't running to be notified
  #expect(device.trace.value.contains(.rulesChangedDropped(.notifyRulesChanged)))
  #expect(device.diskProtectionMode == .normal([.targetContains(value: "new-bad.com")]))

  device.launchFilter()
  let newBad = await device.browse("new-bad.com")
  let staleBad = await device.browse("stale-bad.com")
  #expect(newBad == .drop) // filter reads current rules at startup, dropped notify harmless
  #expect(staleBad == .allow)
}

// MARK: - app update triggers legacy migration, any process may run it first

@Test @MainActor func updateMigrationRunsInControllerWhenItBootsFirst() async throws {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "api-fresh.com")]
  let device = VirtualDevice(
    disk: SimDisk.v1_3_upgrader(
      legacyMode: .normal([.targetContains("legacy.com")]),
      disabledGroups: [.gifs],
    ),
    api: api,
    filterInstalled: true,
  )

  await device.reboot(order: [.controller, .filter])
  await device.quiesce()

  #expect(device.api.loggedEvents.value.contains("04376893")) // block groups -> uuids
  #expect(device.api.loggedEvents.value.contains("edd6e55f")) // v1.3 -> v1.5
  #expect(device.api.loggedEvents.value.contains("99bacaaa")) // migrated by controller
  #expect(device.diskProtectionMode == .normal([.targetContains(value: "api-fresh.com")]))

  let fresh = await device.browse("api-fresh.com")
  let legacy = await device.browse("legacy.com")
  #expect(fresh == .drop)
  #expect(legacy == .allow)

  await device.launchApp() // user opens app much later, its safeguard migration no-ops
  await device.quiesce()

  #expect(device.app?.state.screen == .running(state: .notConnected))
  #expect(device.api.loggedEvents.value.count(where: { $0 == "edd6e55f" }) == 1)
}

@Test @MainActor func updateMigrationRunsInAppWhenItLaunchesFirst() async throws {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "api-fresh.com")]
  let device = VirtualDevice(
    disk: SimDisk.v1_3_upgrader(
      legacyMode: .normal([.targetContains("legacy.com")]),
      disabledGroups: [.gifs],
    ),
    api: api,
    filterInstalled: true,
  )

  await device.launchApp() // user opens app before either extension wakes
  await device.quiesce()

  #expect(device.api.loggedEvents.value.contains("edd6e55f")) // v1.3 -> v1.5, by app
  #expect(device.diskProtectionMode == .normal([.targetContains(value: "legacy.com")]))

  await device.launchController()
  device.launchFilter()
  await device.quiesce()

  // controller's init migration no-ops, its refresh pulls fresh api rules
  #expect(device.api.loggedEvents.value.count(where: { $0 == "edd6e55f" }) == 1)
  #expect(!device.api.loggedEvents.value.contains("99bacaaa"))
  #expect(device.diskProtectionMode == .normal([.targetContains(value: "api-fresh.com")]))

  let fresh = await device.browse("api-fresh.com")
  #expect(fresh == .drop)
}

// MARK: - fresh device onboarding, end to end

@Test @MainActor func onboardingEndsWithLiveFilterProtection() async throws {
  let device = VirtualDevice() // factory-fresh phone, nothing installed

  let preInstall = await device.browse("default-blocked.com")
  #expect(preInstall == .allow) // unprotected before onboarding

  let app = await device.launchApp()
  await device.quiesce()
  #expect(app.state.screen == .onboarding(.happyPath(.hiThere)))

  for _ in 1 ... 9 {
    await app.tap(.primary)
  } // hiThere through explainAuth
  #expect(app.state.screen == .onboarding(.happyPath(.dontGetTrickedPreAuth)))

  await app.tap(.primary) // triggers Screen Time authorization
  await device.quiesce()
  #expect(app.state.screen == .onboarding(.happyPath(.explainInstallWithDevicePasscode)))

  await app.tap(.primary)
  await app.tap(.primary) // triggers filter install, OS starts both providers
  await device.quiesce()

  #expect(app.state.screen == .onboarding(.happyPath(.offerAccountConnect)))
  #expect(device.filterInstalled.value == true)
  #expect(device.isRunning(.filter))
  #expect(device.isRunning(.controller))

  let blocked = await device.browse("default-blocked.com")
  let allowed = await device.browse("ok.com")
  #expect(blocked == .drop) // protecting with onboarding rules fetched at first launch
  #expect(allowed == .allow)
}

// MARK: - filter killed by os, relaunched on demand by next flow

@Test @MainActor func killedFilterRelaunchesOnDemandWithoutProtectionGap() async throws {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "bad.com")]
  let device = VirtualDevice(
    disk: SimDisk.current(
      protectionMode: .normal([.targetContains(value: "bad.com")]),
      disabledBlockGroupIds: [],
    ),
    api: api,
    filterInstalled: true,
  )

  await device.reboot()
  await device.quiesce()
  let before = await device.browse("bad.com")
  #expect(before == .drop)

  await device.kill(.filter) // os reclaims memory

  let after = await device.browse("bad.com")
  #expect(after == .drop) // next flow relaunched the filter, no protection gap
  #expect(device.trace.value.contains(.launchedOnDemand(.filter)))
}

// MARK: - app sentinel forces immediate rule refresh, no heartbeat needed

@Test @MainActor func sentinelRefreshPropagatesRulesImmediately() async throws {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "old-bad.com")]
  let device = VirtualDevice(
    disk: SimDisk.current(
      protectionMode: .normal([.targetContains(value: "old-bad.com")]),
      disabledBlockGroupIds: [],
    ),
    api: api,
    filterInstalled: true,
  )

  await device.reboot()
  await device.quiesce()

  device.api.config.withValue { $0.blockRules = [.targetContains(value: "new-bad.com")] }
  let unpropagated = await device.browse("new-bad.com")
  #expect(unpropagated == .allow) // ordinary browsing hasn't picked up the change

  await device.deliverSentinel(.refreshRules) // app pokes the filter directly
  await device.quiesce()

  let propagated = await device.browse("new-bad.com")
  #expect(propagated == .drop)
  #expect(device.trace.value.contains(.sentinelSent(.refreshRules)))
  #expect(device.filter?.protectionMode == .normal([.targetContains(value: "new-bad.com")]))
}

// MARK: - parent rule change propagates through the faux heartbeat

@Test @MainActor func parentRuleChangeReachesFilterViaHeartbeat() async throws {
  var api = ScriptedApi.Config()
  api.blockRules = [.targetContains(value: "old-bad.com")]
  let device = VirtualDevice(
    disk: SimDisk.current(
      protectionMode: .normal([.targetContains(value: "old-bad.com")]),
      disabledBlockGroupIds: [],
    ),
    api: api,
    filterInstalled: true,
  )

  await device.reboot()
  await device.quiesce()

  let beforeChange = await device.browse("new-bad.com")
  #expect(beforeChange == .allow)

  // parent flips the rules in the dashboard, api now serves the new set
  device.api.config.withValue { $0.blockRules = [.targetContains(value: "new-bad.com")] }
  await device.advanceTime(minutes: 5) // past the controller api debounce

  var rulesReachedFilter = false
  for _ in 0 ..< 60 { // browsing eventually trips the filter's needRules counter
    await device.browse("filler.com")
    if device.trace.value.contains(.rulesChangedDelivered(.withUpdateRules)) {
      rulesReachedFilter = true
      break
    }
  }

  #expect(rulesReachedFilter)
  let newBad = await device.browse("new-bad.com")
  let oldBad = await device.browse("old-bad.com")
  #expect(newBad == .drop)
  #expect(oldBad == .allow)
  #expect(device.filter?.protectionMode == .normal([.targetContains(value: "new-bad.com")]))
}
