import ComposableArchitecture
import Core
import Filter
import Gertie
import MacAppRoute
import TestSupport
import XCTest
import XExpect

@testable import App

/// Downtime enforcement across the filter provider's crash/respawn lifecycle
/// (OS RULE M1: a fresh provider process reloads durable state from disk).
/// The filter persists each user's downtime window in `Persistent.State`
/// precisely so a respawned process can keep enforcing it before the app's
/// next rules delivery — which can be up to 20 minutes away (checkIn
/// heartbeat), or forever if the app is gone.
final class DowntimeScenarioTests: XCTestCase {
  @MainActor
  func testDowntimeSurvivesFilterCrashRespawn() async throws {
    let world = VirtualMac()
    let child: uid_t = 502
    try world.seedAppDisk(uid: child, user: .mock)
    await world.bootFilterExtension()

    // downtime window opens 2 sim-minutes from now
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "UTC")!
    let window = PlainTimeWindow(
      start: .from(world.currentDate.value + 120, in: calendar),
      end: .from(world.currentDate.value + 120 + 3600, in: calendar),
    )
    var output = CheckIn_v2.Output.sim(keychains: [.gitHubOnly])
    output.userData.downtime = window
    output.userData.filteringDisabled = false
    let checkIn = LockIsolated(output)

    // app launches, checks in, delivers rules + downtime to the filter
    _ = await world.launchApp(uid: child, checkInOutput: checkIn)
    await expect(world.browse("https://github.com", as: child)).toEqual(.allow)

    // downtime begins: even the allowlisted host is blocked
    await world.advanceTime(seconds: 180)
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)

    // provider crashes mid-downtime; the OS respawns it and the fresh process
    // reloads durable state from disk. within ~5 minutes the app reconnects
    // (everyFiveMinutes heartbeat) and re-announces alive — but its next
    // rules delivery (checkIn heartbeat) can be up to 20 minutes away
    await world.crashAndRecoverFilterProvider()
    await world.advanceTime(seconds: 360)

    // still inside the downtime window: the respawned filter must keep
    // enforcing the PERSISTED downtime, not wait for the next checkIn
    await expect(world.browse("https://github.com", as: child)).toEqual(.drop)
  }
}
